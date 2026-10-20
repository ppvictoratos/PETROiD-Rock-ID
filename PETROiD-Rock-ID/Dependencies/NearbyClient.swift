//
//  NearbyClient.swift
//  PETROiD-Rock-ID
//

import ComposableArchitecture
import Foundation

/// Reports whether another player is close enough to battle. The reducer only sees a stream of
/// `Bool`s, so the transport (MultipeerConnectivity, Bluetooth, …) can be swapped without touching it.
struct NearbyClient: Sendable {
    var opponentPresence: @Sendable () -> AsyncStream<Bool>
}

extension NearbyClient: DependencyKey {
    /// PLACEHOLDER: no proximity transport exists in the app yet, so nobody is ever "nearby" and
    /// BATTLE stays disabled. Replace this with the real implementation when it lands.
    static let liveValue = NearbyClient(
        opponentPresence: {
            AsyncStream { continuation in
                continuation.yield(false)
            }
        }
    )

    /// Emits nothing and finishes, so tests that don't care about proximity need no override.
    static let testValue = NearbyClient(opponentPresence: { AsyncStream { $0.finish() } })
}

extension DependencyValues {
    var nearbyClient: NearbyClient {
        get { self[NearbyClient.self] }
        set { self[NearbyClient.self] = newValue }
    }
}
