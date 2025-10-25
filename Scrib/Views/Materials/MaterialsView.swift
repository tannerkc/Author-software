//
//  MaterialsView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// Main view for accessing all book materials
///
/// Provides tabbed navigation to scenes, notes, research items, and characters.
/// Acts as a centralized hub for all non-manuscript content related to the book.
struct MaterialsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let book: Book

    @State private var selectedTab: MaterialTab = .scenes
    @State private var materialViewModel: MaterialViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Material Type", selection: $selectedTab) {
                    ForEach(MaterialTab.allCases) { tab in
                        Label(tab.title, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab content
                TabView(selection: $selectedTab) {
                    ForEach(MaterialTab.allCases) { tab in
                        materialContent(for: tab)
                            .tag(tab)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Materials")
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
            .onAppear {
                if materialViewModel == nil {
                    materialViewModel = MaterialViewModel(modelContext: modelContext)
                }
            }
        }
    }

    @ViewBuilder
    private func materialContent(for tab: MaterialTab) -> some View {
        Group {
            switch tab {
            case .scenes:
                SceneListView(book: book, viewModel: materialViewModel ?? MaterialViewModel(modelContext: modelContext))

            case .notes:
                NoteListView(book: book, viewModel: materialViewModel ?? MaterialViewModel(modelContext: modelContext))

            case .research:
                ResearchListView(book: book, viewModel: materialViewModel ?? MaterialViewModel(modelContext: modelContext))

            case .characters:
                CharacterListView(book: book, viewModel: materialViewModel ?? MaterialViewModel(modelContext: modelContext))
            }
        }
    }

    private var addButton: some View {
        Button {
            guard let viewModel = materialViewModel else { return }

            switch selectedTab {
            case .scenes:
                _ = viewModel.createScene(in: book)
            case .notes:
                _ = viewModel.createNote(in: book)
            case .research:
                _ = viewModel.createResearchItem(in: book)
            case .characters:
                _ = viewModel.createCharacter(in: book)
            }
        } label: {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Material Tab Enum

enum MaterialTab: String, CaseIterable, Identifiable {
    case scenes
    case notes
    case research
    case characters

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scenes: return "Scenes"
        case .notes: return "Notes"
        case .research: return "Research"
        case .characters: return "Characters"
        }
    }

    var icon: String {
        switch self {
        case .scenes: return "film"
        case .notes: return "note.text"
        case .research: return "book"
        case .characters: return "person.2"
        }
    }

    var count: (Book) -> Int {
        switch self {
        case .scenes: return { $0.sceneCount }
        case .notes: return { $0.noteCount }
        case .research: return { $0.researchItemCount }
        case .characters: return { $0.characterCount }
        }
    }
}

// MARK: - Empty State View

struct MaterialEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    MaterialsView(book: {
        let book = Book(title: "Sample Book")
        return book
    }())
    .modelContainer(DataStore.preview().modelContainer)
}
