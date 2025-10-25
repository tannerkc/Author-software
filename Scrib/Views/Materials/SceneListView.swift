//
//  SceneListView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// List view displaying all scenes for a book
struct SceneListView: View {
    let book: Book
    let viewModel: MaterialViewModel

    @State private var searchText = ""
    @State private var selectedScene: Scene?
    @State private var showingEditor = false

    var filteredScenes: [Scene] {
        if searchText.isEmpty {
            return book.sortedScenes
        } else {
            return book.sortedScenes.filter { scene in
                scene.title.localizedCaseInsensitiveContains(searchText) ||
                scene.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        Group {
            if book.scenes.isEmpty {
                MaterialEmptyStateView(
                    icon: "film",
                    title: "No Scenes",
                    message: "Scenes are smaller writing units that can be combined into chapters. Tap the + button to create your first scene."
                )
            } else {
                List {
                    ForEach(filteredScenes) { scene in
                        SceneRow(scene: scene)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedScene = scene
                                showingEditor = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteScene(scene)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    _ = viewModel.duplicateScene(scene)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    _ = viewModel.duplicateScene(scene)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }

                                Button(role: .destructive) {
                                    viewModel.deleteScene(scene)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onMove { source, destination in
                        viewModel.reorderScenes(in: book, from: source, to: destination)
                    }
                }
                .searchable(text: $searchText, prompt: "Search scenes")
            }
        }
        .sheet(item: $selectedScene) { scene in
            SceneEditorView(scene: scene, viewModel: viewModel)
        }
    }
}

// MARK: - Scene Row

struct SceneRow: View {
    let scene: Scene

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(scene.extractedTitle)
                    .font(.headline)

                Spacer()

                // Status badge
                Label(scene.status.rawValue, systemImage: scene.status.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Synopsis
            if !scene.synopsis.isEmpty {
                Text(scene.synopsis)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Metadata badges
            HStack(spacing: 12) {
                if !scene.povCharacter.isEmpty {
                    Label(scene.povCharacter, systemImage: "person")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !scene.location.isEmpty {
                    Label(scene.location, systemImage: "location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(scene.wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SceneListView(
            book: {
                let book = Book(title: "Sample Book")
                let scene = Scene(
                    title: "Opening Scene",
                    content: "The tavern was dimly lit...",
                    synopsis: "Hero enters the tavern",
                    povCharacter: "Alex",
                    location: "Tavern"
                )
                scene.book = book
                book.scenes = [scene]
                return book
            }(),
            viewModel: MaterialViewModel(modelContext: ModelContext(
                try! ModelContainer(for: Book.self, Scene.self)
            ))
        )
    }
}
