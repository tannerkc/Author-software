//
//  CharacterEditorView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Editor view for character details
struct CharacterEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let character: Character
    let viewModel: MaterialViewModel

    @State private var name: String
    @State private var role: CharacterRole
    @State private var age: String
    @State private var occupation: String
    @State private var physicalDescription: String
    @State private var personality: String
    @State private var backstory: String
    @State private var goals: String
    @State private var arcNotes: String
    @State private var relationships: String
    @State private var notes: String

    init(character: Character, viewModel: MaterialViewModel) {
        self.character = character
        self.viewModel = viewModel
        self._name = State(initialValue: character.name)
        self._role = State(initialValue: character.role)
        self._age = State(initialValue: character.age)
        self._occupation = State(initialValue: character.occupation)
        self._physicalDescription = State(initialValue: character.physicalDescription)
        self._personality = State(initialValue: character.personality)
        self._backstory = State(initialValue: character.backstory)
        self._goals = State(initialValue: character.goals)
        self._arcNotes = State(initialValue: character.arcNotes)
        self._relationships = State(initialValue: character.relationships)
        self._notes = State(initialValue: character.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                        .font(.headline)

                    Picker("Role", selection: $role) {
                        ForEach(CharacterRole.allCases) { role in
                            Label(role.rawValue, systemImage: role.icon)
                                .tag(role)
                        }
                    }

                    TextField("Age", text: $age)
                    TextField("Occupation", text: $occupation)
                }

                Section("Physical Description") {
                    TextEditor(text: $physicalDescription)
                        .frame(height: 100)
                }

                Section("Personality") {
                    TextEditor(text: $personality)
                        .frame(height: 100)
                }

                Section("Backstory") {
                    TextEditor(text: $backstory)
                        .frame(height: 120)
                }

                Section("Goals & Motivations") {
                    TextEditor(text: $goals)
                        .frame(height: 100)
                }

                Section("Character Arc") {
                    TextEditor(text: $arcNotes)
                        .frame(height: 100)
                }

                Section("Relationships") {
                    TextEditor(text: $relationships)
                        .frame(height: 100)
                }

                Section("Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Character")
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCharacter()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveCharacter() {
        character.name = name
        character.role = role
        character.age = age
        character.occupation = occupation
        character.physicalDescription = physicalDescription
        character.personality = personality
        character.backstory = backstory
        character.goals = goals
        character.arcNotes = arcNotes
        character.relationships = relationships
        character.notes = notes
        viewModel.updateCharacter(character)
    }
}
