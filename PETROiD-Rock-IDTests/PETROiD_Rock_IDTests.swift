//
//  PETROiD_Rock_IDTests.swift
//  PETROiD-Rock-IDTests
//

import ComposableArchitecture
import XCTest
@testable import PETROiD_Rock_ID

// MARK: - Fixtures

private let granite = RockSpecies(name: "Granite", mohsMin: 6, mohsMax: 7)
private let basalt = RockSpecies(name: "Basalt", mohsMin: 5, mohsMax: 6)
private let shale = RockSpecies(name: "Shale", mohsMin: 2, mohsMax: 3)

extension RockRecord {
    static func fixture(
        id: UUID = UUID(0),
        name: String = "Granite",
        mohsMin: Double = 6,
        mohsMax: Double = 7,
        imageData: Data = Data([0xAA]),
        wins: Int = 0,
        dateAdded: Date = Date(timeIntervalSince1970: 0)
    ) -> RockRecord {
        RockRecord(
            id: id,
            name: name,
            mohsMin: mohsMin,
            mohsMax: mohsMax,
            hardnessValue: (mohsMin + mohsMax) / 2,
            imageData: imageData,
            wins: wins,
            dateAdded: dateAdded
        )
    }
}

extension UUID {
    /// Small, readable stand-in for the incrementing UUIDs `DependencyValues.uuid` hands out in tests.
    init(_ int: Int) {
        self = UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", int))")!
    }
}

// MARK: - Model-level tests

final class RockModelTests: XCTestCase {
    func testRockHardnessLabel() {
        XCTAssertEqual(RockRecord.fixture(mohsMin: 6, mohsMax: 7).hardnessLabel, "6-7")
        XCTAssertEqual(RockRecord.fixture(mohsMin: 10, mohsMax: 10).hardnessLabel, "10")
    }

    func testRockSpeciesCatalogIsWellFormed() {
        XCTAssertGreaterThan(RockSpecies.catalog.count, 0, "Catalog must not be empty")
        for species in RockSpecies.catalog {
            XCTAssertFalse(species.name.isEmpty)
            XCTAssertGreaterThanOrEqual(species.mohsMin, 1)
            XCTAssertLessThanOrEqual(species.mohsMax, 10)
            XCTAssertGreaterThanOrEqual(species.mohsMax, species.mohsMin)
        }
    }
}

// MARK: - RockBattleFeature: exhaustive TestStore coverage
//
// Every dependency the reducer touches — clock, uuid, date, the rock catalog, the battle
// coin flip, persistence, sound — is overridden here. Nothing is random, nothing sleeps for
// real, and every intermediate state mutation is asserted exactly. This is "exhaustive"
// testing: the default TestStore config fails the test if any state change or effect isn't
// accounted for in a `store.send`/`store.receive` step.
@MainActor
final class RockBattleFeatureTests: XCTestCase {

    func testOnAppearLoadsPersistedRocks() async {
        let saved = [RockRecord.fixture(id: UUID(1), name: "Basalt")]
        let store = TestStore(initialState: RockBattleFeature.State()) {
            RockBattleFeature()
        } withDependencies: {
            $0.rockPersistence.fetchAll = { saved }
        }

        await store.send(.onAppear)
        await store.receive(\.rocksLoaded) {
            $0.rocks = IdentifiedArray(uniqueElements: saved)
        }
    }

    func testTappingEmptySlotPresentsCamera() async {
        let store = TestStore(initialState: RockBattleFeature.State()) {
            RockBattleFeature()
        }

        await store.send(.slotTapped(0)) {
            $0.isShowingCamera = true
        }
    }

    func testTappingLockedSlotDoesNothing() async {
        // Only one empty slot is ever active — slot 1 is locked until slot 0 is filled.
        let store = TestStore(initialState: RockBattleFeature.State()) {
            RockBattleFeature()
        }

        await store.send(.slotTapped(1))
    }

    func testTappingFilledSlotStagesAndUnstagesIt() async {
        let rock = RockRecord.fixture(id: UUID(1))
        var initialState = RockBattleFeature.State()
        initialState.rocks = [rock]

        let store = TestStore(initialState: initialState) {
            RockBattleFeature()
        }

        await store.send(.slotTapped(0)) {
            $0.stagedRockID = rock.id
        }
        await store.send(.slotTapped(0)) {
            $0.stagedRockID = nil
        }
    }

    func testFullIdentificationFlow() async {
        let clock = TestClock()
        let fixedID = UUID(42)
        let fixedDate = Date(timeIntervalSince1970: 1_000)
        let imageData = Data([0x01, 0x02])

        let store = TestStore(initialState: RockBattleFeature.State()) {
            RockBattleFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.uuid = .constant(fixedID)
            $0.date = .constant(fixedDate)
            $0.rockCatalog.identify = { granite }
            $0.rockPersistence.insert = { _ in }
        }

        await store.send(.cameraPresented(true)) {
            $0.isShowingCamera = true
        }

        await store.send(.photoCaptured(imageData)) {
            $0.isShowingCamera = false
            $0.isIdentifying = true
            $0.pendingImageData = imageData
        }

        await clock.advance(by: RockBattleFeature.identifyingDelay)

        await store.receive(\.identificationFinished) {
            $0.isIdentifying = false
            $0.pendingImageData = nil
            let expected = RockRecord(
                id: fixedID,
                name: granite.name,
                mohsMin: granite.mohsMin,
                mohsMax: granite.mohsMax,
                hardnessValue: granite.hardnessValue,
                imageData: imageData,
                wins: 0,
                dateAdded: fixedDate
            )
            $0.rocks = [expected]
            $0.stagedRockID = fixedID
        }
    }

    func testCancelingCameraDoesNotStartIdentification() async {
        let store = TestStore(initialState: RockBattleFeature.State()) {
            RockBattleFeature()
        }

        await store.send(.slotTapped(0)) {
            $0.isShowingCamera = true
        }
        await store.send(.cameraPresented(false)) {
            $0.isShowingCamera = false
        }
    }

    func testBattleWonByHigherHardnessNoCoinFlipNeeded() async {
        let clock = TestClock()
        let rock = RockRecord.fixture(id: UUID(1), name: "Granite", mohsMin: 6, mohsMax: 7) // hardness 6.5
        var initialState = RockBattleFeature.State()
        initialState.rocks = [rock]
        initialState.stagedRockID = rock.id

        let store = TestStore(initialState: initialState) {
            RockBattleFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.uuid = .constant(UUID(99))
            $0.rockCatalog.randomOpponent = { shale } // hardness 2.5 — player should win outright
            $0.battleCoin.flip = { XCTFail("coin flip should not be consulted on a clear win"); return false }
            $0.soundClient.playCrack = {}
            $0.rockPersistence.update = { _ in }
        }

        await store.send(.battleButtonTapped) {
            $0.isBattling = true
        }

        await clock.advance(by: RockBattleFeature.battleDelay)

        await store.receive(\.battleFinished) {
            $0.isBattling = false
            $0.rocks[id: rock.id]?.wins = 1
            $0.battleResult = BattleResult(
                id: UUID(99),
                playerName: "Granite",
                playerHardnessLabel: "6-7",
                opponentName: shale.name,
                opponentHardnessLabel: shale.hardnessLabel,
                playerWon: true
            )
        }
    }

    func testBattleLostByLowerHardness() async {
        let clock = TestClock()
        let rock = RockRecord.fixture(id: UUID(1), name: "Shale", mohsMin: 2, mohsMax: 3)
        var initialState = RockBattleFeature.State()
        initialState.rocks = [rock]
        initialState.stagedRockID = rock.id

        let store = TestStore(initialState: initialState) {
            RockBattleFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.uuid = .constant(UUID(100))
            $0.rockCatalog.randomOpponent = { granite }
            $0.soundClient.playCrack = {}
            $0.rockPersistence.update = { _ in }
        }

        await store.send(.battleButtonTapped) {
            $0.isBattling = true
        }
        await clock.advance(by: RockBattleFeature.battleDelay)
        await store.receive(\.battleFinished) {
            $0.isBattling = false
            // No win increment on a loss.
            $0.battleResult = BattleResult(
                id: UUID(100),
                playerName: "Shale",
                playerHardnessLabel: "2-3",
                opponentName: granite.name,
                opponentHardnessLabel: granite.hardnessLabel,
                playerWon: false
            )
        }
    }

    func testTiedHardnessDefersToCoinFlip() async {
        let clock = TestClock()
        // Both 6-7 → identical hardnessValue of 6.5, so the coin flip decides.
        let rock = RockRecord.fixture(id: UUID(1), name: "Granite", mohsMin: 6, mohsMax: 7)
        var initialState = RockBattleFeature.State()
        initialState.rocks = [rock]
        initialState.stagedRockID = rock.id

        let store = TestStore(initialState: initialState) {
            RockBattleFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.uuid = .constant(UUID(7))
            $0.rockCatalog.randomOpponent = { RockSpecies(name: "Gneiss", mohsMin: 6, mohsMax: 7) }
            $0.battleCoin.flip = { true } // force the win branch of the tie-break
            $0.soundClient.playCrack = {}
            $0.rockPersistence.update = { _ in }
        }

        await store.send(.battleButtonTapped) {
            $0.isBattling = true
        }
        await clock.advance(by: RockBattleFeature.battleDelay)
        await store.receive(\.battleFinished) {
            $0.isBattling = false
            $0.rocks[id: rock.id]?.wins = 1
            $0.battleResult = BattleResult(
                id: UUID(7),
                playerName: "Granite",
                playerHardnessLabel: "6-7",
                opponentName: "Gneiss",
                opponentHardnessLabel: "6-7",
                playerWon: true
            )
        }
    }

    func testBattleButtonTappedWithNoStagedRockDoesNothing() async {
        let store = TestStore(initialState: RockBattleFeature.State()) {
            RockBattleFeature()
        }

        await store.send(.battleButtonTapped)
    }

    func testDismissingBattleResultClearsIt() async {
        var initialState = RockBattleFeature.State()
        initialState.battleResult = BattleResult(
            id: UUID(1),
            playerName: "Granite",
            playerHardnessLabel: "6-7",
            opponentName: "Shale",
            opponentHardnessLabel: "2-3",
            playerWon: true
        )

        let store = TestStore(initialState: initialState) {
            RockBattleFeature()
        }

        await store.send(.battleResultDismissed) {
            $0.battleResult = nil
        }
    }
}
