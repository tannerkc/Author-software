//
//  CharacterListView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// List view displaying all characters for a book
struct CharacterListView: View {
    let book: Book
    let viewModel: MaterialViewModel

    @State private var searchText = ""
    @State private var selectedCharacter: Character?
    @State private var showingEditor = false

    var filteredCharacters: [Character] {
        if searchText.isEmpty {
            return book.sortedCharacters
        } else {
            return book.sortedCharacters.filter { character in
                character.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        Group {
            if book.characters.isEmpty {
                MaterialEmptyStateView(
                    icon: "person.2",
                    title: "No Characters",
                    message: "Build a character database to track names, roles, descriptions, and arcs. Tap the + button to create your first character."
                )
            } else {
                List {
                    ForEach(filteredCharacters) { character in
                        CharacterRow(character: character)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCharacter = character
                                showingEditor = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteCharacter(character)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteCharacter(character)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .searchable(text: $searchText, prompt: "Search characters")
            }
        }
        .sheet(item: $selectedCharacter) { character in
            CharacterEditorView(character: character, viewModel: viewModel)
        }
    }
}

// MARK: - Character Row

struct CharacterRow: View {
    let character: Character

    var body: some View {
        HStack(spacing: 12) {
            // Role indicator
            ZStack {
                Circle()
                    .fill(character.role.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: character.role.icon)
                    .foregroundStyle(character.role.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(character.name)
                        .font(.headline)

                    Spacer()

                    Text(character.role.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !character.summary.isEmpty {
                    Text(character.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if !character.physicalDescription.isEmpty {
                    Text(character.physicalDescription)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CharacterListView(
            book: {
                let book = Book(title: "Sample Book")
                let character = Character(
                    name: "Alex Morgan",
                    role: .protagonist,
                    physicalDescription: "Tall, athletic build with dark curly hair and green eyes",
                    personality: "Determined, compassionate, sometimes impulsive",
                    age: "28",
                    occupation: "Adventurer"
                )
                character.book = book
                book.characters = [character]
                return book
            }(),
            viewModel: MaterialViewModel(modelContext: ModelContext(
                try! ModelContainer(for: Book.self, Character.self)
            ))
        )
    }
}
