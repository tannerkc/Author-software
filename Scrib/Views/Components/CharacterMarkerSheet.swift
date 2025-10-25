//
//  CharacterMarkerSheet.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Sheet for marking and tracking characters mentioned in text
///
/// Allows authors to tag character references in their manuscript,
/// building a database of character appearances and tracking character arcs.
struct CharacterMarkerSheet: View {
    /// Binding to control sheet presentation
    @Environment(\.dismiss) private var dismiss

    /// Selected text to mark as a character
    let selectedText: String

    /// Callback when character is marked
    var onMarkCharacter: (CharacterMarker) -> Void

    /// Character name
    @State private var characterName: String = ""

    /// Character role/type
    @State private var characterRole: CharacterRole = .protagonist

    /// Notes about this character appearance
    @State private var notes: String = ""

    /// Whether this is a new character or existing
    @State private var isNewCharacter: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Character Details") {
                    TextField("Character Name", text: $characterName)
                        .textContentType(.name)

                    Picker("Role", selection: $characterRole) {
                        ForEach(CharacterRole.allCases) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                }

                Section("Selected Text") {
                    Text(selectedText)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section {
                    Toggle("Track as new character", isOn: $isNewCharacter)
                }
            }
            .navigationTitle("Mark Character")
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Mark") {
                        let marker = CharacterMarker(
                            name: characterName,
                            role: characterRole,
                            markedText: selectedText,
                            notes: notes,
                            isNew: isNewCharacter
                        )
                        onMarkCharacter(marker)
                        dismiss()
                    }
                    .disabled(characterName.isEmpty)
                }
            }
            .onAppear {
                // Pre-fill character name from selected text
                characterName = selectedText
            }
        }
    }
}

// Data models are defined in Models/ChapterMetadata.swift

// MARK: - Previews

#Preview {
    CharacterMarkerSheet(
        selectedText: "Sarah walked into the room",
        onMarkCharacter: { marker in
            print("Marked character: \(marker.name)")
        }
    )
}
