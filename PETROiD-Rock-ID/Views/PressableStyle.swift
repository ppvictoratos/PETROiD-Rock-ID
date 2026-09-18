//
//  PressableStyle.swift
//  PETROiD-Rock-ID
//

import SwiftUI

/// Mirrors the "active:scale-95" tap feedback used throughout the Stitch design.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
