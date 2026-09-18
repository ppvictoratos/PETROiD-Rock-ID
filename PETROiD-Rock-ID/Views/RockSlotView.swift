//
//  RockSlotView.swift
//  PETROiD-Rock-ID
//

import SwiftUI

enum RockSlotState {
    case filled(Rock)
    case activeEmpty
    case locked
}

/// One of the three roster slots: a captured rock, the next open "tap to ID" slot, or a locked slot.
struct RockSlotView: View {
    let state: RockSlotState
    let isStaged: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            content
        }
        .buttonStyle(PressableStyle())
        .disabled(isLocked)
    }

    private var isLocked: Bool {
        if case .locked = state { return true }
        return false
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .filled(let rock):
            filledContent(rock)
        case .activeEmpty:
            emptyContent
        case .locked:
            lockedContent
        }
    }

    private func filledContent(_ rock: Rock) -> some View {
        VStack(spacing: 8) {
            if let uiImage = UIImage(data: rock.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: Color.rockPrimary.opacity(isStaged ? 0.5 : 0.2), radius: isStaged ? 20 : 12)
            }
            Text(rock.name.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color.rockOnSurface.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .background(Color.rockSurfaceVariant.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.rockPrimary.opacity(isStaged ? 0.85 : 0.2), lineWidth: isStaged ? 2 : 1)
        )
    }

    private var emptyContent: some View {
        VStack(spacing: 4) {
            Image(systemName: "camera.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.rockPrimary)
            Text("TAP TO ID")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.rockPrimary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .background(Color.rockSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.rockPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }

    private var lockedContent: some View {
        VStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.rockOutlineVariant)
            Text("TAP TO ID")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.rockOutlineVariant.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .background(Color.rockSurface.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.rockOutlineVariant.opacity(0.1), lineWidth: 1)
        )
        .opacity(0.3)
    }
}
