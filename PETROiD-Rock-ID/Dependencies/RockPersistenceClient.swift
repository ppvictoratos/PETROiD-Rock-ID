//
//  RockPersistenceClient.swift
//  PETROiD-Rock-ID
//

import ComposableArchitecture
import Foundation

/// SwiftData lives entirely behind this interface. The reducer never imports SwiftData —
/// it just awaits `fetchAll`/`insert`/`update`, so tests swap in an in-memory fake with zero ceremony.
struct RockPersistenceClient: Sendable {
    var fetchAll: @Sendable () async throws -> [RockRecord]
    var insert: @Sendable (RockRecord) async throws -> Void
    var update: @Sendable (RockRecord) async throws -> Void
}

extension RockPersistenceClient: DependencyKey {
    static let liveValue: RockPersistenceClient = {
        let store = SwiftDataRockStore()
        return RockPersistenceClient(
            fetchAll: { try await store.fetchAll() },
            insert: { try await store.insert($0) },
            update: { try await store.update($0) }
        )
    }()

    static let testValue = RockPersistenceClient(
        fetchAll: { [] },
        insert: { _ in },
        update: { _ in }
    )

    static let previewValue = testValue
}

extension DependencyValues {
    var rockPersistence: RockPersistenceClient {
        get { self[RockPersistenceClient.self] }
        set { self[RockPersistenceClient.self] = newValue }
    }
}
