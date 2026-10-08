//
//  RockSpecies.swift
//  PETROiD-Rock-ID
//

import Foundation

/// A field-guide entry used to simulate identification until a real classifier is wired in.
/// Random selection lives in `RockCatalogClient` so it's injectable in tests.
struct RockSpecies: Equatable, Sendable {
    let name: String
    let mohsMin: Double
    let mohsMax: Double

    var hardnessValue: Double { (mohsMin + mohsMax) / 2 }
    var hardnessLabel: String { formatHardness(min: mohsMin, max: mohsMax) }

    static let catalog: [RockSpecies] = [
        RockSpecies(name: "Granite", mohsMin: 6, mohsMax: 7),
        RockSpecies(name: "Basalt", mohsMin: 5, mohsMax: 6),
        RockSpecies(name: "Limestone", mohsMin: 3, mohsMax: 4),
        RockSpecies(name: "Sandstone", mohsMin: 6, mohsMax: 7),
        RockSpecies(name: "Obsidian", mohsMin: 5, mohsMax: 5.5),
        RockSpecies(name: "Marble", mohsMin: 3, mohsMax: 4),
        RockSpecies(name: "Slate", mohsMin: 3, mohsMax: 4),
        RockSpecies(name: "Gneiss", mohsMin: 6, mohsMax: 7),
        RockSpecies(name: "Quartzite", mohsMin: 7, mohsMax: 7),
        RockSpecies(name: "Shale", mohsMin: 2, mohsMax: 3),
        RockSpecies(name: "Pumice", mohsMin: 5, mohsMax: 6),
        RockSpecies(name: "Schist", mohsMin: 3, mohsMax: 4),
    ]
}
