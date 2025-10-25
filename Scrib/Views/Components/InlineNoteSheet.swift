//
//  InlineNoteSheet.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Sheet for adding inline notes and annotations to manuscript text
///
/// Allows authors to attach notes, reminders, and research references
/// to specific passages without disrupting the main text flow.
struct InlineNoteSheet: View {
    /// Binding to control sheet presentation
    @Environment(\.dismiss) private var dismiss

    /// Selected text to annotate
    let selectedText: String

    /// Callback when note is created
    var onCreateNote: (InlineNote) -> Void

    /// Note content
    @State private var noteContent: String = ""

    /// Note category/type
    @State private var noteType: NoteType = .general

    /// Priority level
    @State private var priority: NotePriority = .normal

    var body: some View {
        NavigationStack {
            Form {
                Section("Annotating") {
                    Text(selectedText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }

                Section("Note") {
                    Picker("Type", selection: $noteType) {
                        ForEach(NoteType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(NotePriority.allCases) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }

                    TextEditor(text: $noteContent)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Add Note")
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let note = InlineNote(
                            content: noteContent,
                            type: noteType,
                            priority: priority,
                            annotatedText: selectedText
                        )
                        onCreateNote(note)
                        dismiss()
                    }
                    .disabled(noteContent.isEmpty)
                }
            }
        }
    }
}

// Data models are defined in Models/ChapterMetadata.swift

// MARK: - Previews

#Preview {
    InlineNoteSheet(
        selectedText: "The detective examined the evidence carefully.",
        onCreateNote: { note in
            print("Created note: \(note.content)")
        }
    )
}
