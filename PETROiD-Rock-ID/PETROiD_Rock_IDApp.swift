//
//  PETROiD_Rock_IDApp.swift
//  PETROiD-Rock-ID
//
//  Created by Petie Positivo on 9/17/26.
//

import SwiftUI
import SwiftData

@main
struct PETROiD_Rock_IDApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Rock.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
