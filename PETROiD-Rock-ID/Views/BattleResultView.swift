//
//  BattleResultView.swift
//  PETROiD-Rock-ID
//

import SwiftUI

struct BattleResultView: View {
    let result: BattleResult
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.rockBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()

                Text(result.playerWon ? "YOU WIN" : "YOU LOSE")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .italic()
                    .tracking(-1)
                    .foregroundStyle(result.playerWon ? Color.rockPrimary : Color.rockOnSurfaceVariant)

                HStack(spacing: 20) {
                    battlerCard(name: result.playerName, hardness: result.playerHardnessLabel, won: result.playerWon)
                    Text("VS")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(Color.rockOnSurfaceVariant)
                    battlerCard(name: result.opponentName, hardness: result.opponentHardnessLabel, won: !result.playerWon)
                }

                Spacer()

                Button(action: onContinue) {
                    Text("CONTINUE")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color.rockBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.rockPrimaryDim, Color.rockPrimary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .buttonStyle(PressableStyle())
            }
            .padding(32)
        }
    }

    private func battlerCard(name: String, hardness: String, won: Bool) -> some View {
        VStack(spacing: 10) {
            Text(name.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color.rockOnSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(hardness)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(won ? Color.rockPrimary : Color.rockOnSurfaceVariant)
        }
        .padding(16)
        .frame(width: 130)
        .background(Color.rockSurfaceVariant.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(won ? Color.rockPrimary.opacity(0.6) : Color.clear, lineWidth: 2)
        )
    }
}
