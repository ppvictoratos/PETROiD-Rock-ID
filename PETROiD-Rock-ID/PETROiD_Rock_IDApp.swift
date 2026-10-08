//
//  PETROiD_Rock_IDApp.swift
//  PETROiD-Rock-ID
//
//  Created by Petie Positivo on 9/17/26.
//

import ComposableArchitecture
import SwiftUI

@main
struct PETROiD_Rock_IDApp: App {
    static let store = Store(initialState: RockBattleFeature.State()) {
        RockBattleFeature()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: Self.store)
        }
    }
}
