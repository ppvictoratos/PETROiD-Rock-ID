//
//  Rock.swift
//  PETROiD-Rock-ID
//

import Foundation
import SwiftData

@Model
final class Rock {
    var id: UUID
    var name: String
    var mohsMin: Double
    var mohsMax: Double
    var hardnessValue: Double
    var imageData: Data
    var wins: Int
    var dateAdded: Date

    init(
        name: String,
        mohsMin: Double,
        mohsMax: Double,
        hardnessValue: Double,
        imageData: Data,
        wins: Int = 0,
        dateAdded: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.mohsMin = mohsMin
        self.mohsMax = mohsMax
        self.hardnessValue = hardnessValue
        self.imageData = imageData
        self.wins = wins
        self.dateAdded = dateAdded
    }

    var hardnessLabel: String {
        formatHardness(min: mohsMin, max: mohsMax)
    }
}
