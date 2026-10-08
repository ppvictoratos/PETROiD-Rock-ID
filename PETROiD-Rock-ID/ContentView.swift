//
//  ContentView.swift
//  PETROiD-Rock-ID
//

import ComposableArchitecture
import SwiftUI
import UIKit

struct ContentView: View {
    let store: StoreOf<RockBattleFeature>

    var body: some View {
        ZStack {
            Color.rockBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()
                VStack(spacing: 48) {
                    rosterGrid
                    battleButton
                }
                Spacer()
                footer
            }
            .padding(32)

            if store.isIdentifying {
                identifyingOverlay
            }
        }
        .onAppear { store.send(.onAppear) }
        .fullScreenCover(
            isPresented: Binding(
                get: { store.isShowingCamera },
                set: { store.send(.cameraPresented($0)) }
            )
        ) {
            CameraCaptureView(
                onCapture: { image in
                    let imageData = image.jpegData(compressionQuality: RockBattleFeature.imageCompressionQuality) ?? Data()
                    store.send(.photoCaptured(imageData))
                },
                onCancel: { store.send(.cameraPresented(false)) }
            )
            .ignoresSafeArea()
        }
        .sheet(
            item: Binding(
                get: { store.battleResult },
                set: { if $0 == nil { store.send(.battleResultDismissed) } }
            )
        ) { result in
            BattleResultView(result: result, onContinue: { store.send(.battleResultDismissed) })
        }
    }

    // MARK: - Sections

    private var header: some View {
        Text("PETROiD")
            .font(.system(size: 34, weight: .black, design: .rounded))
            .italic()
            .tracking(-1)
            .foregroundStyle(Color.rockPrimary)
            .padding(.top, 8)
    }

    private var rosterGrid: some View {
        HStack(spacing: 12) {
            ForEach(0..<RockBattleFeature.maxRocks, id: \.self) { index in
                RockSlotView(
                    state: slotState(at: index),
                    isStaged: isStaged(at: index),
                    action: { store.send(.slotTapped(index)) }
                )
            }
        }
    }

    private var battleButton: some View {
        Button(action: { store.send(.battleButtonTapped) }) {
            HStack(spacing: 12) {
                Image(systemName: "figure.fencing")
                    .font(.system(size: 22, weight: .bold))
                Text("BATTLE")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .foregroundStyle(store.stagedRock == nil ? Color.rockOnSurfaceVariant.opacity(0.5) : Color.rockBackground)
            .background(battleButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.rockPrimary.opacity(store.stagedRock == nil ? 0 : 0.25), radius: 30)
        }
        .buttonStyle(PressableStyle())
        .disabled(store.stagedRock == nil || store.isBattling)
    }

    @ViewBuilder
    private var battleButtonBackground: some View {
        if store.stagedRock == nil {
            Color.rockSurfaceVariant
        } else {
            LinearGradient(colors: [Color.rockPrimaryDim, Color.rockPrimary], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 8) {
                Text("WINS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color.rockOnSurfaceVariant)
                Text(store.stagedRock.map { "\($0.wins)" } ?? "—")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.rockPrimary)
            }
            Spacer()
            Rectangle()
                .fill(Color.rockOutlineVariant.opacity(0.3))
                .frame(width: 1, height: 12)
            Spacer()
            HStack(spacing: 8) {
                Text("HARDNESS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color.rockOnSurfaceVariant)
                Text(store.stagedRock?.hardnessLabel ?? "—")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.rockOnSurface)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.rockSurface.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private var identifyingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                if let pendingImageData = store.pendingImageData, let uiImage = UIImage(data: pendingImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .clipped()
                }
                ProgressView()
                    .tint(Color.rockPrimary)
                Text("IDENTIFYING…")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.rockPrimary)
            }
            .padding(24)
            .background(Color.rockSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    // MARK: - Slot logic

    private func slotState(at index: Int) -> RockSlotState {
        if index < store.rocks.count {
            return .filled(store.rocks[index])
        } else if index == store.rocks.count {
            return .activeEmpty
        } else {
            return .locked
        }
    }

    private func isStaged(at index: Int) -> Bool {
        index < store.rocks.count && store.rocks[index].id == store.stagedRockID
    }
}

#Preview {
    ContentView(
        store: Store(initialState: RockBattleFeature.State()) {
            RockBattleFeature()
        }
    )
}
