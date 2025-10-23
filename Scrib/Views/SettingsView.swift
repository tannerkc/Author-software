//
//  SettingsView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Settings view for app preferences
///
/// SettingsView provides configuration options for appearance,
/// behavior, and export preferences. On macOS, this appears in
/// the standard Settings window.
struct SettingsView: View {
    @AppStorage("editorFontSize") private var editorFontSize: Double = 16
    @AppStorage("enableAutoSave") private var enableAutoSave: Bool = true
    @AppStorage("autoSaveDelay") private var autoSaveDelay: Double = 1.0

    var body: some View {
        TabView {
            // MARK: - General Settings
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            // MARK: - Editor Settings
            editorSettings
                .tabItem {
                    Label("Editor", systemImage: "doc.text")
                }

            // MARK: - About
            aboutView
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }

    // MARK: - General Settings

    private var generalSettings: some View {
        Form {
            Section("Auto-Save") {
                Toggle("Enable Auto-Save", isOn: $enableAutoSave)

                if enableAutoSave {
                    HStack {
                        Text("Delay:")
                        Slider(value: $autoSaveDelay, in: 0.5...5.0, step: 0.5)
                        Text("\(autoSaveDelay, specifier: "%.1f")s")
                            .frame(width: 40)
                    }
                }
            }

            Section {
                Text("Auto-save automatically saves your work as you type.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Editor Settings

    private var editorSettings: some View {
        Form {
            Section("Appearance") {
                HStack {
                    Text("Font Size:")
                    Slider(value: $editorFontSize, in: 12...24, step: 1)
                    Text("\(Int(editorFontSize))pt")
                        .frame(width: 40)
                }
            }

            Section {
                Text("Customize the appearance of the chapter editor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - About

    private var aboutView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.pages")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Scrib")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version 1.0.0 (Phase One)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("A modern book writing app for iOS and macOS")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            Text("© 2025 Scrib. All rights reserved.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

// MARK: - Previews
#Preview {
    SettingsView()
}
