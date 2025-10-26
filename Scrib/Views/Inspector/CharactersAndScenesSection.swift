//
//  CharactersAndScenesSection.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

#if os(macOS)
import SwiftUI
import SwiftData

/// Section displaying characters and scenes in the inspector panel
///
/// Provides quick reference to characters and scenes in the book.
/// Shows character roles, descriptions, and scene details for easy lookup
/// while writing.
struct CharactersAndScenesSection: View {
    /// The current book
    let book: Book

    /// View model for inspector operations
    @Bindable var viewModel: InspectorViewModel

    /// Filter characters by role
    @State private var selectedRoleFilter: CharacterRole?

    /// Filter scenes by status
    @State private var selectedStatusFilter: SceneStatus?

    /// Fetch characters based on filter
    private var characters: [Character] {
        if let filter = selectedRoleFilter {
            return viewModel.fetchCharacters(for: book, withRole: filter)
        }
        return viewModel.fetchCharacters(for: book)
    }

    /// Fetch scenes based on filter
    private var scenes: [Scene] {
        if let filter = selectedStatusFilter {
            return viewModel.fetchScenes(for: book, withStatus: filter)
        }
        return viewModel.fetchScenes(for: book)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Characters section
            charactersSection

            // Scenes section
            scenesSection
        }
    }

    // MARK: - Characters Section

    private var charactersSection: some View {
        CollapsibleSection(
            "Characters",
            icon: "person.2",
            count: characters.count,
            isExpanded: $viewModel.isCharactersExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Role filter
                if !book.characters.isEmpty {
                    characterFilterPicker
                }

                // Characters list
                if characters.isEmpty {
                    emptyCharactersState
                } else {
                    charactersList
                }
            }
        }
    }

    private var characterFilterPicker: some View {
        Menu {
            Button("All Roles") {
                selectedRoleFilter = nil
            }

            Divider()

            ForEach(CharacterRole.allCases) { role in
                let count = viewModel.fetchCharacters(for: book, withRole: role).count
                if count > 0 {
                    Button {
                        selectedRoleFilter = role
                    } label: {
                        Label {
                            Text("\(role.rawValue) (\(count))")
                        } icon: {
                            Image(systemName: role.icon)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedRoleFilter?.icon ?? "line.3.horizontal.decrease.circle")
                    .font(.system(size: 11))

                Text(selectedRoleFilter?.rawValue ?? "All Roles")
                    .font(.system(size: 11))

                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }

    private var charactersList: some View {
        LazyVStack(spacing: 8) {
            ForEach(characters.sorted(), id: \.id) { character in
                CharacterCard(character: character)
            }
        }
    }

    private var emptyCharactersState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)

            Text(selectedRoleFilter != nil ? "No \(selectedRoleFilter!.rawValue.lowercased()) characters" : "No characters")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            if selectedRoleFilter != nil {
                Button("Clear Filter") {
                    selectedRoleFilter = nil
                }
                .font(.system(size: 10))
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Scenes Section

    private var scenesSection: some View {
        CollapsibleSection(
            "Scenes",
            icon: "film",
            count: scenes.count,
            isExpanded: $viewModel.isScenesExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Status filter
                if !book.scenes.isEmpty {
                    sceneFilterPicker
                }

                // Scenes list
                if scenes.isEmpty {
                    emptyScenesState
                } else {
                    scenesList
                }
            }
        }
    }

    private var sceneFilterPicker: some View {
        Menu {
            Button("All Statuses") {
                selectedStatusFilter = nil
            }

            Divider()

            ForEach(SceneStatus.allCases) { status in
                let count = viewModel.fetchScenes(for: book, withStatus: status).count
                if count > 0 {
                    Button {
                        selectedStatusFilter = status
                    } label: {
                        Label {
                            Text("\(status.rawValue) (\(count))")
                        } icon: {
                            Image(systemName: status.icon)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedStatusFilter?.icon ?? "line.3.horizontal.decrease.circle")
                    .font(.system(size: 11))

                Text(selectedStatusFilter?.rawValue ?? "All Statuses")
                    .font(.system(size: 11))

                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }

    private var scenesList: some View {
        LazyVStack(spacing: 8) {
            ForEach(scenes.sorted(), id: \.id) { scene in
                SceneCard(scene: scene)
            }
        }
    }

    private var emptyScenesState: some View {
        VStack(spacing: 8) {
            Image(systemName: "film")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)

            Text(selectedStatusFilter != nil ? "No \(selectedStatusFilter!.rawValue.lowercased()) scenes" : "No scenes")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            if selectedStatusFilter != nil {
                Button("Clear Filter") {
                    selectedStatusFilter = nil
                }
                .font(.system(size: 10))
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Character Card

private struct CharacterCard: View {
    let character: Character

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with role badge
            HStack(spacing: 6) {
                Image(systemName: character.role.icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(character.role.color)

                Text(character.role.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(character.role.color)
                    .textCase(.uppercase)

                Spacer()
            }

            // Name
            Text(character.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)

            // Summary
            if !character.summary.isEmpty {
                Text(character.summary)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Physical description preview
            if !character.physicalDescription.isEmpty {
                Text(character.physicalDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.background)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

// MARK: - Scene Card

private struct SceneCard: View {
    let scene: Scene

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with status
            HStack(spacing: 6) {
                Image(systemName: scene.status.icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(scene.status.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                // Word count
                Text("\(scene.wordCount) words")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            // Title
            Text(scene.extractedTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            // Synopsis or content preview
            if !scene.synopsis.isEmpty {
                Text(scene.synopsis)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else if !scene.content.isEmpty {
                Text(scene.contentPreview)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }

            // Scene details
            HStack(spacing: 12) {
                if !scene.location.isEmpty {
                    Label {
                        Text(scene.location)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "mappin")
                    }
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                }

                if !scene.povCharacter.isEmpty {
                    Label {
                        Text(scene.povCharacter)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "person")
                    }
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.background)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

// MARK: - Previews

#Preview("With Characters and Scenes") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, Character.self, Scene.self,
        configurations: config
    )

    let book = Book(title: "My Novel", genre: "Fantasy")
    container.mainContext.insert(book)

    // Add characters
    let char1 = Character(
        name: "Sarah Connor",
        role: .protagonist,
        physicalDescription: "Athletic woman in her 30s with determination in her eyes",
        age: "35",
        occupation: "Resistance Leader"
    )
    char1.book = book

    let char2 = Character(
        name: "Marcus Wright",
        role: .supporting,
        physicalDescription: "Tall, muscular man with a mysterious past",
        age: "40",
        occupation: "Soldier"
    )
    char2.book = book

    // Add scenes
    let scene1 = Scene(
        title: "The Awakening",
        content: "She opened her eyes to a world transformed...",
        synopsis: "Sarah discovers her new abilities",
        status: .draft,
        povCharacter: "Sarah Connor",
        location: "Abandoned Warehouse"
    )
    scene1.book = book

    let scene2 = Scene(
        title: "First Contact",
        content: "The meeting would change everything...",
        synopsis: "Sarah meets Marcus for the first time",
        status: .revised,
        povCharacter: "Sarah Connor",
        location: "Underground Bunker",
        timeOfDay: "Night"
    )
    scene2.book = book

    container.mainContext.insert(char1)
    container.mainContext.insert(char2)
    container.mainContext.insert(scene1)
    container.mainContext.insert(scene2)

    let viewModel = InspectorViewModel(modelContext: container.mainContext)

    return ScrollView {
        CharactersAndScenesSection(book: book, viewModel: viewModel)
            .padding()
    }
    .frame(width: 300, height: 700)
    .modelContainer(container)
}

#endif
