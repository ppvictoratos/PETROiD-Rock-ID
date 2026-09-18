//
//  CrackSoundPlayer.swift
//  PETROiD-Rock-ID
//

import AVFoundation

/// Synthesizes a short rock-on-rock "crack" impact with no bundled audio asset:
/// a fast-decaying noise burst layered over a low thump.
@MainActor
final class CrackSoundPlayer {
    static let shared = CrackSoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let buffer: AVAudioPCMBuffer
    private let format: AVAudioFormat

    private init() {
        let sampleRate = 44100.0
        let duration = 0.18
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        self.format = format

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let channel = buffer.floatChannelData![0]
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let crackEnvelope = exp(-t * 45.0)
            let crackle = Double.random(in: -1...1) * crackEnvelope
            let thump = sin(2.0 * .pi * 90.0 * t) * exp(-t * 22.0) * 0.6
            channel[frame] = Float(crackle + thump)
        }
        self.buffer = buffer

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    func play() {
        if !engine.isRunning {
            try? engine.start()
        }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }
}
