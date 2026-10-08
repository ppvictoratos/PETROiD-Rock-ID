//
//  SoundClient.swift
//  PETROiD-Rock-ID
//

import ComposableArchitecture
import Foundation

/// Wraps `CrackSoundPlayer` so the reducer never touches `AVAudioEngine` directly —
/// tests get a silent no-op instead of spinning up real audio.
struct SoundClient: Sendable {
    var playCrack: @Sendable () async -> Void
}

extension SoundClient: DependencyKey {
    static let liveValue = SoundClient(playCrack: { await CrackSoundPlayer.shared.play() })
    static let testValue = SoundClient(playCrack: {})
}

extension DependencyValues {
    var soundClient: SoundClient {
        get { self[SoundClient.self] }
        set { self[SoundClient.self] = newValue }
    }
}
