//
//  RockCatalogClient.swift
//  PETROiD-Rock-ID
//

import ComposableArchitecture
import Foundation

/// Stands in for a real classifier until one is wired in. Injected so tests can pin
/// exactly which species gets "identified" or faced in battle — no `.randomElement()` in sight.
struct RockCatalogClient: Sendable {
    var identify: @Sendable () -> RockSpecies
    var randomOpponent: @Sendable () -> RockSpecies
}

extension RockCatalogClient: DependencyKey {
    static let liveValue = RockCatalogClient(
        identify: { RockSpecies.catalog.randomElement() ?? RockSpecies(name: "Granite", mohsMin: 6, mohsMax: 7) },
        randomOpponent: { RockSpecies.catalog.randomElement() ?? RockSpecies(name: "Basalt", mohsMin: 5, mohsMax: 6) }
    )

    static let testValue = RockCatalogClient(
        identify: {
            reportIssue("RockCatalogClient.identify is unimplemented")
            return RockSpecies(name: "Granite", mohsMin: 6, mohsMax: 7)
        },
        randomOpponent: {
            reportIssue("RockCatalogClient.randomOpponent is unimplemented")
            return RockSpecies(name: "Basalt", mohsMin: 5, mohsMax: 6)
        }
    )
}

extension DependencyValues {
    var rockCatalog: RockCatalogClient {
        get { self[RockCatalogClient.self] }
        set { self[RockCatalogClient.self] = newValue }
    }
}
