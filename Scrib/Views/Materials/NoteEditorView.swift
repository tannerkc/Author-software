//
//  NoteEditorView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Editor view for note content
struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let note: Note
    let viewModel: MaterialViewModel

    @State private var attributedContent: NSAttributedString
    @State private var showFormatMenu = false
    @State private var autoSaveTask: Task<Void, Never>?

    init(note: Note, viewModel: MaterialViewModel) {
        self.note = note
        self.viewModel = viewModel
        self._attributedContent = State(initialValue: note.getAttributedContent())
    }

    var body: some View {
        NavigationStack {
            RichTextEditor(
                attributedText: $attributedContent,
                showFormatMenu: $showFormatMenu,
                placeholderText: "Start writing your note..."
            )
            .onChange(of: attributedContent) { _, newValue in
                scheduleAutoSave(newValue)
            }
            .navigationTitle(note.extractedTitle)
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
                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .foregroundStyle(.orange)
                        }

                        Text("\(note.wordCount) words")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDisappear {
                forceSave()
            }
        }
    }

    private func scheduleAutoSave(_ content: NSAttributedString) {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                note.setAttributedContent(content)
                viewModel.updateNote(note, content: content.string)
            }
        }
    }

    private func forceSave() {
        autoSaveTask?.cancel()
        note.setAttributedContent(attributedContent)
        viewModel.updateNote(note, content: attributedContent.string)
    }
}
