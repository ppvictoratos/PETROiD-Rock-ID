//
//  RockRecord.swift
//  PETROiD-Rock-ID
//

import Foundation

/// A rock in the player's roster. Plain value type so it can live in `RockBattleFeature.State`
/// and be compared/asserted against exhaustively in `TestStore` — persistence is a side effect,
/// not part of the model.
struct RockRecord: Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var mohsMin: Double
    var mohsMax: Double
    var hardnessValue: Double
    var imageData: Data
    var wins: Int
    var dateAdded: Date

    var hardnessLabel: String {
        formatHardness(min: mohsMin, max: mohsMax)
    }
}
