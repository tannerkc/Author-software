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

    /// Show splash screen on startup for professional loading experience
    @State private var showingSplashScreen = true

    init() {
        // Initialize model container with optimized configuration
        let schema = Schema([
            Book.self,
            Chapter.self,
            ChapterMetadata.self,
            Scene.self,
            Note.self,
            ResearchItem.self,
            Character.self
        ])

        // PERFORMANCE: Optimized ModelConfiguration
        // - allowsSave: true (default, but explicit)
        // - isStoredInMemoryOnly: false (persisted to disk)
        // - cloudKitDatabase: .none (disable CloudKit sync for faster initialization)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            print("✅ ModelContainer initialized successfully")
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ZStack {
                // Main content view
                ContentView()
                    .modelContainer(modelContainer)
                    .opacity(showingSplashScreen ? 0 : 1)
                    .task {
                        // PERFORMANCE: Splash fade happens FIRST
                        // UI becomes interactive IMMEDIATELY
                        try? await Task.sleep(for: .milliseconds(100))
                        guard !Task.isCancelled else { return }

                        withAnimation(.easeOut(duration: 0.2)) {
                            showingSplashScreen = false
                        }
                        print("⚡ UI now interactive")

                        // CRITICAL: Create sample data AFTER UI is interactive
                        // User can click and interact while this runs
                        if !hasLaunchedBefore {
                            // Additional delay to ensure user sees interactive UI first
                            try? await Task.sleep(for: .milliseconds(200))
                            guard !Task.isCancelled else { return }

                            let dataStore = DataStore(container: modelContainer)
                            await dataStore.createSampleData()
                            hasLaunchedBefore = true
                            print("✅ Sample data created after UI ready")
                        }
                    }

                // PERFORMANCE: Instant splash screen
                // Shows immediately (<16ms) while data loads in background
                if showingSplashScreen {
                    VStack(spacing: 20) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("Scrib")
                            .font(.title.bold())

                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #if os(macOS)
                    .background(Color(nsColor: .windowBackgroundColor))
                    #else
                    .background(Color(uiColor: .systemBackground))
                    #endif
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
