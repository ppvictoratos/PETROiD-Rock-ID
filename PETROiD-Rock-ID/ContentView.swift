//
//  ContentView.swift
//  PETROiD-Rock-ID
//

import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Rock.dateAdded) private var rocks: [Rock]

    @State private var stagedRockID: UUID?
    @State private var isShowingCamera = false
    @State private var isIdentifying = false
    @State private var pendingImage: UIImage?
    @State private var isBattling = false
    @State private var battleResult: BattleResult?

    private let identifyingDelay: TimeInterval = 1.6
    private let battleDelay: TimeInterval = 0.5
    private let imageCompressionQuality: Double = 0.8

    private var stagedRock: Rock? {
        rocks.first { $0.id == stagedRockID }
    }

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

            if isIdentifying {
                identifyingOverlay
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraCaptureView(onCapture: handleCapture, onCancel: { isShowingCamera = false })
                .ignoresSafeArea()
        }
        .sheet(item: $battleResult) { result in
            BattleResultView(result: result, onContinue: { battleResult = nil })
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
            ForEach(0..<3, id: \.self) { index in
                RockSlotView(
                    state: slotState(at: index),
                    isStaged: isStaged(at: index),
                    action: { handleSlotTap(at: index) }
                )
            }
        }
    }

    private var battleButton: some View {
        Button(action: startBattle) {
            HStack(spacing: 12) {
                Image(systemName: "figure.fencing")
                    .font(.system(size: 22, weight: .bold))
                Text("BATTLE")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .foregroundStyle(stagedRock == nil ? Color.rockOnSurfaceVariant.opacity(0.5) : Color.rockBackground)
            .background(battleButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.rockPrimary.opacity(stagedRock == nil ? 0 : 0.25), radius: 30)
        }
        .buttonStyle(PressableStyle())
        .disabled(stagedRock == nil || isBattling)
    }

    @ViewBuilder
    private var battleButtonBackground: some View {
        if stagedRock == nil {
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
                Text(stagedRock.map { "\($0.wins)" } ?? "—")
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
                Text(stagedRock?.hardnessLabel ?? "—")
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
                if let pendingImage {
                    Image(uiImage: pendingImage)
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
        if index < rocks.count {
            return .filled(rocks[index])
        } else if index == rocks.count {
            return .activeEmpty
        } else {
            return .locked
        }
    }

    private func isStaged(at index: Int) -> Bool {
        index < rocks.count && rocks[index].id == stagedRockID
    }

    private func handleSlotTap(at index: Int) {
        if index < rocks.count {
            let rock = rocks[index]
            stagedRockID = (stagedRockID == rock.id) ? nil : rock.id
        } else if index == rocks.count {
            isShowingCamera = true
        }
    }

    // MARK: - Scanning

    private func handleCapture(_ image: UIImage) {
        isShowingCamera = false
        pendingImage = image
        isIdentifying = true
        Task {
            try? await Task.sleep(for: .seconds(identifyingDelay))
            let species = RockSpecies.identify()
            guard let imageData = image.jpegData(compressionQuality: imageCompressionQuality) else {
                isIdentifying = false
                pendingImage = nil
                return
            }
            let rock = Rock(
                name: species.name,
                mohsMin: species.mohsMin,
                mohsMax: species.mohsMax,
                hardnessValue: species.hardnessValue,
                imageData: imageData
            )
            modelContext.insert(rock)
            stagedRockID = rock.id
            pendingImage = nil
            isIdentifying = false
        }
    }

    // MARK: - Battle

    private func startBattle() {
        guard let playerRock = stagedRock else { return }
        isBattling = true
        Task {
            try? await Task.sleep(for: .seconds(battleDelay))
            let opponent = RockSpecies.randomOpponent()
            let playerWon = playerRock.hardnessValue == opponent.hardnessValue
                ? Bool.random()
                : playerRock.hardnessValue > opponent.hardnessValue

            CrackSoundPlayer.shared.play()
            if playerWon {
                playerRock.wins += 1
            }

            battleResult = BattleResult(
                playerName: playerRock.name,
                playerHardnessLabel: playerRock.hardnessLabel,
                opponentName: opponent.name,
                opponentHardnessLabel: opponent.hardnessLabel,
                playerWon: playerWon
            )
            isBattling = false
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Rock.self, inMemory: true)
}
