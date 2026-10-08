//
//  SwiftDataRockStore.swift
//  PETROiD-Rock-ID
//

import Foundation
import SwiftData

/// Owns the `ModelContainer` and performs all SwiftData access off the reducer, behind
/// `RockPersistenceClient`. An actor so container/context access stays serialized.
actor SwiftDataRockStore {
    private let container: ModelContainer

    init() {
        let schema = Schema([RockEntity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        guard let container = try? ModelContainer(for: schema, configurations: [configuration]) else {
            fatalError("Could not create ModelContainer for RockEntity")
        }
        self.container = container
    }

    func fetchAll() throws -> [RockRecord] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<RockEntity>(sortBy: [SortDescriptor(\.dateAdded)])
        return try context.fetch(descriptor).map(RockRecord.init)
    }

    func insert(_ record: RockRecord) throws {
        let context = ModelContext(container)
        context.insert(RockEntity(record: record))
        try context.save()
    }

    func update(_ record: RockRecord) throws {
        let context = ModelContext(container)
        let targetID = record.id
        let descriptor = FetchDescriptor<RockEntity>(predicate: #Predicate { $0.id == targetID })
        guard let entity = try context.fetch(descriptor).first else { return }
        entity.wins = record.wins
        try context.save()
    }
}
