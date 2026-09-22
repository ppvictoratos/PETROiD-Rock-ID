//
//  PETROiD_Rock_IDTests.swift
//  PETROiD-Rock-IDTests
//
//  Created by Petie Positivo on 9/17/26.
//

import XCTest
@testable import PETROiD_Rock_ID

// MARK: - Test Fixtures

extension Rock {
    static func fixture(
        name: String = "Test Rock",
        mohsMin: Double = 5,
        mohsMax: Double = 6,
        imageData: Data = Data(),
        wins: Int = 0
    ) -> Rock {
        Rock(
            name: name,
            mohsMin: mohsMin,
            mohsMax: mohsMax,
            hardnessValue: (mohsMin + mohsMax) / 2,
            imageData: imageData,
            wins: wins
        )
    }
}

final class PETROiD_Rock_IDTests: XCTestCase {

    func testRockHardnessLabel() {
        let rock = Rock(name: "Granite", mohsMin: 6, mohsMax: 7, hardnessValue: 6.5, imageData: Data())
        XCTAssertEqual(rock.hardnessLabel, "6-7")

        let homogeneous = Rock(name: "Diamond", mohsMin: 10, mohsMax: 10, hardnessValue: 10, imageData: Data())
        XCTAssertEqual(homogeneous.hardnessLabel, "10")
    }

    func testRockSpeciesCatalog() {
        XCTAssertGreaterThan(RockSpecies.catalog.count, 0, "Catalog must not be empty")

        for species in RockSpecies.catalog {
            XCTAssertFalse(species.name.isEmpty)
            XCTAssertGreaterThanOrEqual(species.mohsMin, 1)
            XCTAssertLessThanOrEqual(species.mohsMax, 10)
            XCTAssertGreaterThanOrEqual(species.mohsMax, species.mohsMin)
        }
    }

    func testRockSpeciesIdentify() {
        let species = RockSpecies.identify()
        XCTAssertTrue(RockSpecies.catalog.contains { $0.name == species.name })
    }

    func testBattleResultCreation() {
        let result = BattleResult(
            playerName: "Granite",
            playerHardnessLabel: "6-7",
            opponentName: "Basalt",
            opponentHardnessLabel: "5-6",
            playerWon: true
        )
        XCTAssertEqual(result.playerName, "Granite")
        XCTAssertTrue(result.playerWon)
    }

}
