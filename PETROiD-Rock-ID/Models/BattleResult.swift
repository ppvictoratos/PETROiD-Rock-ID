//
//  BattleResult.swift
//  PETROiD-Rock-ID
//

import Foundation

struct BattleResult: Identifiable {
    let id = UUID()
    let playerName: String
    let playerHardnessLabel: String
    let opponentName: String
    let opponentHardnessLabel: String
    let playerWon: Bool
}
