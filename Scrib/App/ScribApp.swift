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
    /// Model container for SwiftData persistence
    let modelContainer: ModelContainer

    /// Track whether this is the first launch
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore: Bool = false

    init() {
        // Initialize model container
        let schema = Schema([
            Book.self,
            Chapter.self,
            ChapterMetadata.self,
            Scene.self,
            Note.self,
            ResearchItem.self,
            Character.self
        ])
        let configuration = ModelConfiguration(schema: schema)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .task {
                    // Create sample data on first launch
                    if !hasLaunchedBefore {
                        let dataStore = DataStore(container: modelContainer)
                        dataStore.createSampleData()
                        hasLaunchedBefore = true
                    }
                }
        }
        #if os(macOS)
        // MARK: - macOS Toolbar Configuration (Apple Notes style)
        // Enables separate toolbars for each column in NavigationSplitView
        // The .unified style with showsTitle: false creates distinct toolbar areas
        // for sidebar, content, and detail columns
        .windowToolbarStyle(.unified(showsTitle: false))
        #endif

        #if os(macOS)
        // macOS-specific settings window
        Settings {
            SettingsView()
        }
        #endif
    }
}
