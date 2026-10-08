//
//  BattleCoin.swift
//  PETROiD-Rock-ID
//

import ComposableArchitecture
import Foundation

/// The only source of randomness in a battle: the tie-break when both rocks have identical
/// hardness. Isolating it means every other battle outcome is 100% deterministic in tests.
struct BattleCoin: Sendable {
    var flip: @Sendable () -> Bool
}

extension BattleCoin: DependencyKey {
    static let liveValue = BattleCoin(flip: { Bool.random() })

    static let testValue = BattleCoin(flip: {
        reportIssue("BattleCoin.flip is unimplemented")
        return true
    })
}

extension DependencyValues {
    var battleCoin: BattleCoin {
        get { self[BattleCoin.self] }
        set { self[BattleCoin.self] = newValue }
    }
}
