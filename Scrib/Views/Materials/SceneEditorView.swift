//
//  SceneEditorView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Editor view for scene content
struct SceneEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let scene: Scene
    let viewModel: MaterialViewModel

    @State private var attributedContent: NSAttributedString
    @State private var showFormatMenu = false
    @State private var showMetadata = false
    @State private var textSelection: NSRange = NSRange(location: 0, length: 0)
    @FocusState private var isEditorFocused: Bool

    @State private var autoSaveTask: Task<Void, Never>?

    init(scene: Scene, viewModel: MaterialViewModel) {
        self.scene = scene
        self.viewModel = viewModel
        self._attributedContent = State(initialValue: scene.getAttributedContent())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Metadata strip
                if !scene.synopsis.isEmpty || !scene.povCharacter.isEmpty {
                    metadataStrip
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(.secondary.opacity(0.1))
                }

                // Editor
                RichTextEditor(
                    attributedText: $attributedContent,
                    selectedRange: $textSelection,
                    isFocused: $isEditorFocused,
                    isEditable: true
                )
                .onChange(of: attributedContent) { _, newValue in
                    scheduleAutoSave(newValue)
                }
            }
            .navigationTitle(scene.extractedTitle)
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        forceSave()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        // Word count
                        Text("\(scene.wordCount) words")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Metadata button
                        Button {
                            showMetadata = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                    }
                }
            }
            .onDisappear {
                forceSave()
            }
            .sheet(isPresented: $showMetadata) {
                SceneMetadataSheet(scene: scene)
            }
        }
    }

    private var metadataStrip: some View {
        HStack {
            if !scene.povCharacter.isEmpty {
                Label(scene.povCharacter, systemImage: "person")
                    .font(.caption)
            }

            if !scene.location.isEmpty {
                Label(scene.location, systemImage: "location")
                    .font(.caption)
            }

            if !scene.timeOfDay.isEmpty {
                Label(scene.timeOfDay, systemImage: "clock")
                    .font(.caption)
            }

            Spacer()

            if !scene.synopsis.isEmpty {
                Text(scene.synopsis)
                    .font(.caption)
                    .italic()
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Auto-save

    private func scheduleAutoSave(_ content: NSAttributedString) {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                scene.setAttributedContent(content)
                viewModel.updateScene(scene, content: content.string)
            }
        }
    }

    private func forceSave() {
        autoSaveTask?.cancel()
        scene.setAttributedContent(attributedContent)
        viewModel.updateScene(scene, content: attributedContent.string)
    }
}

// MARK: - Scene Metadata Sheet

struct SceneMetadataSheet: View {
    @Environment(\.dismiss) private var dismiss

    let scene: Scene

    @State private var synopsis: String
    @State private var povCharacter: String
    @State private var location: String
    @State private var timeOfDay: String
    @State private var status: SceneStatus

    init(scene: Scene) {
        self.scene = scene
        self._synopsis = State(initialValue: scene.synopsis)
        self._povCharacter = State(initialValue: scene.povCharacter)
        self._location = State(initialValue: scene.location)
        self._timeOfDay = State(initialValue: scene.timeOfDay)
        self._status = State(initialValue: scene.status)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Synopsis") {
                    TextEditor(text: $synopsis)
                        .frame(height: 100)
                }

                Section("Scene Details") {
                    HStack {
                        Text("POV Character")
                        Spacer()
                        TextField("Character name", text: $povCharacter)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Location")
                        Spacer()
                        TextField("Setting", text: $location)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Time of Day")
                        Spacer()
                        TextField("Morning, evening, etc.", text: $timeOfDay)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Status", selection: $status) {
                        ForEach(SceneStatus.allCases) { status in
                            Label(status.rawValue, systemImage: status.icon)
                                .tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Scene Metadata")
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        scene.synopsis = synopsis
                        scene.povCharacter = povCharacter
                        scene.location = location
                        scene.timeOfDay = timeOfDay
                        scene.status = status
                        scene.lastModified = Date()
                        dismiss()
                    }
                }
            }
        }
    }
}
