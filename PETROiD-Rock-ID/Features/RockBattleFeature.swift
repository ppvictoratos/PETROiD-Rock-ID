//
//  RockBattleFeature.swift
//  PETROiD-Rock-ID
//

import ComposableArchitecture
import Foundation

/// Everything the roster/battle screen does, as a pure value-type state machine.
/// Every side effect (clock, uuid, persistence, catalog lookup, coin flip, sound) is a
/// `@Dependency` — nothing here calls `Task.sleep` or `.random()` directly, which is what
/// lets `RockBattleFeatureTests` assert every step exhaustively with `TestStore`.
@Reducer
struct RockBattleFeature {
    static let maxRocks = 3
    static let identifyingDelay: Duration = .seconds(1.6)
    static let battleDelay: Duration = .seconds(0.5)
    static let imageCompressionQuality: Double = 0.8

    @ObservableState
    struct State: Equatable {
        var rocks: IdentifiedArrayOf<RockRecord> = []
        var stagedRockID: RockRecord.ID?
        var isShowingCamera = false
        var isIdentifying = false
        var pendingImageData: Data?
        var isBattling = false
        var battleResult: BattleResult?

        var stagedRock: RockRecord? {
            stagedRockID.flatMap { rocks[id: $0] }
        }
    }

    enum Action: Equatable, Sendable {
        case onAppear
        case rocksLoaded([RockRecord])
        case slotTapped(Int)
        case cameraPresented(Bool)
        case photoCaptured(Data)
        case identificationFinished(species: RockSpecies, imageData: Data, id: UUID, dateAdded: Date)
        case battleButtonTapped
        case battleFinished(opponent: RockSpecies, playerWon: Bool, resultID: UUID)
        case battleResultDismissed
    }

    private enum CancelID: Hashable {
        case identify
        case battle
    }

    @Dependency(\.rockCatalog) var rockCatalog
    @Dependency(\.rockPersistence) var persistence
    @Dependency(\.battleCoin) var battleCoin
    @Dependency(\.soundClient) var soundClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let rocks = try await persistence.fetchAll()
                    await send(.rocksLoaded(rocks))
                }

            case let .rocksLoaded(rocks):
                state.rocks = IdentifiedArray(uniqueElements: rocks)
                return .none

            case let .slotTapped(index):
                if index < state.rocks.count {
                    let rock = state.rocks[index]
                    state.stagedRockID = state.stagedRockID == rock.id ? nil : rock.id
                } else if index == state.rocks.count && index < Self.maxRocks {
                    state.isShowingCamera = true
                }
                return .none

            case let .cameraPresented(isPresented):
                state.isShowingCamera = isPresented
                return .none

            case let .photoCaptured(imageData):
                state.isShowingCamera = false
                state.pendingImageData = imageData
                state.isIdentifying = true
                let newID = uuid()
                let capturedDate = date()
                return .run { send in
                    try await clock.sleep(for: Self.identifyingDelay)
                    let species = rockCatalog.identify()
                    await send(.identificationFinished(species: species, imageData: imageData, id: newID, dateAdded: capturedDate))
                }
                .cancellable(id: CancelID.identify)

            case let .identificationFinished(species, imageData, id, dateAdded):
                let rock = RockRecord(
                    id: id,
                    name: species.name,
                    mohsMin: species.mohsMin,
                    mohsMax: species.mohsMax,
                    hardnessValue: species.hardnessValue,
                    imageData: imageData,
                    wins: 0,
                    dateAdded: dateAdded
                )
                state.rocks.append(rock)
                state.stagedRockID = rock.id
                state.pendingImageData = nil
                state.isIdentifying = false
                return .run { _ in try await persistence.insert(rock) }

            case .battleButtonTapped:
                guard let playerRock = state.stagedRock, !state.isBattling else { return .none }
                state.isBattling = true
                let playerHardness = playerRock.hardnessValue
                let resultID = uuid()
                return .run { send in
                    try await clock.sleep(for: Self.battleDelay)
                    let opponent = rockCatalog.randomOpponent()
                    let playerWon = playerHardness == opponent.hardnessValue
                        ? battleCoin.flip()
                        : playerHardness > opponent.hardnessValue
                    await send(.battleFinished(opponent: opponent, playerWon: playerWon, resultID: resultID))
                }
                .cancellable(id: CancelID.battle)

            case let .battleFinished(opponent, playerWon, resultID):
                state.isBattling = false

                guard let stagedID = state.stagedRockID, var player = state.rocks[id: stagedID] else {
                    return .run { _ in await soundClient.playCrack() }
                }
                if playerWon {
                    player.wins += 1
                    state.rocks[id: stagedID] = player
                }

                state.battleResult = BattleResult(
                    id: resultID,
                    playerName: player.name,
                    playerHardnessLabel: player.hardnessLabel,
                    opponentName: opponent.name,
                    opponentHardnessLabel: opponent.hardnessLabel,
                    playerWon: playerWon
                )

                return .run { _ in
                    await soundClient.playCrack()
                    try await persistence.update(player)
                }

            case .battleResultDismissed:
                state.battleResult = nil
                return .none
            }
        }
    }
}
