//
//  RockEntity.swift
//  PETROiD-Rock-ID
//

import Foundation
import SwiftData

/// SwiftData storage model. Only `SwiftDataRockStore` touches this type — the rest of the
/// app works with the plain `RockRecord` value type so feature logic stays testable without SwiftData.
@Model
final class RockEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var mohsMin: Double
    var mohsMax: Double
    var hardnessValue: Double
    var imageData: Data
    var wins: Int
    var dateAdded: Date

    init(record: RockRecord) {
        self.id = record.id
        self.name = record.name
        self.mohsMin = record.mohsMin
        self.mohsMax = record.mohsMax
        self.hardnessValue = record.hardnessValue
        self.imageData = record.imageData
        self.wins = record.wins
        self.dateAdded = record.dateAdded
    }
}

extension RockRecord {
    init(entity: RockEntity) {
        self.init(
            id: entity.id,
            name: entity.name,
            mohsMin: entity.mohsMin,
            mohsMax: entity.mohsMax,
            hardnessValue: entity.hardnessValue,
            imageData: entity.imageData,
            wins: entity.wins,
            dateAdded: entity.dateAdded
        )
    }
}
