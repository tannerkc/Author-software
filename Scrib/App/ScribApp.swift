//
//  ScribApp.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// Main app entry point for Scrib
///
/// Scrib is a cross-platform book writing application for iOS 26 and macOS 26
/// that reimagines Apple Notes as a book-authoring environment.
@main
struct ScribApp: App {
    /// Data store instance for the app
    @StateObject private var dataStore = DataStore()

    /// Track whether this is the first launch
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Create sample data on first launch
                    if !hasLaunchedBefore {
                        dataStore.createSampleData()
                        hasLaunchedBefore = true
                    }
                }
        }
        .modelContainer(dataStore.modelContainer)

        #if os(macOS)
        // macOS-specific settings window
        Settings {
            SettingsView()
        }
        #endif
    }
}
