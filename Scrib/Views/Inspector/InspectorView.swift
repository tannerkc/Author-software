//
//  InspectorView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

#if os(macOS)
import SwiftUI
import SwiftData

/// Main inspector panel view for macOS
///
/// Provides always-accessible materials similar to Scrivener's inspector,
/// including research items, chapter metadata, characters, scenes, and outline.
/// Uses a segmented control to switch between Book and Chapter scope.
struct InspectorView: View {
    /// The current book
    let book: Book

    /// The currently selected chapter (optional)
    let chapter: Chapter?

    /// View model for inspector operations
    @State var viewModel: InspectorViewModel

    /// Action to navigate to a chapter
    let onChapterSelect: (Chapter) -> Void

    /// Model context from environment
    @Environment(\.modelContext) private var modelContext

    /// Initialize inspector view
    /// - Parameters:
    ///   - book: The current book
    ///   - chapter: The currently selected chapter
    ///   - onChapterSelect: Action when a chapter is selected from outline
    init(
        book: Book,
        chapter: Chapter?,
        onChapterSelect: @escaping (Chapter) -> Void
    ) {
        self.book = book
        self.chapter = chapter
        self.onChapterSelect = onChapterSelect
        // ViewModel will be initialized in onAppear with the environment's modelContext
        self._viewModel = State(initialValue: InspectorViewModel(modelContext: ModelContext(.init(for: Book.self))))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with scope picker
                header

                // Content based on scope
                content
            }
            .padding(16)
        }
        .frame(minWidth: 280, idealWidth: 320)
        .background(.background)
        .onAppear {
            // Initialize viewModel with the correct modelContext
            if viewModel.self.hashValue == 0 {
                viewModel = InspectorViewModel(modelContext: modelContext)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text("Inspector")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            // Scope picker
            scopePicker

            // Search field (if applicable)
            if viewModel.scope == .book {
                searchField
            }
        }
    }

    private var scopePicker: some View {
        Picker("Scope", selection: $viewModel.scope) {
            ForEach(InspectorScope.allCases) { scope in
                Label(scope.rawValue, systemImage: scope.icon)
                    .tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            TextField("Search materials...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.3))
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.scope {
        case .book:
            bookScopeContent
        case .chapter:
            chapterScopeContent
        }
    }

    private var bookScopeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Outline - shows all chapters
            BookOutlineSection(
                book: book,
                selectedChapter: chapter,
                viewModel: viewModel,
                onChapterSelect: onChapterSelect
            )

            Divider()

            // Research items
            ResearchItemsSection(
                book: book,
                viewModel: viewModel
            )

            Divider()

            // Characters and scenes
            CharactersAndScenesSection(
                book: book,
                viewModel: viewModel
            )

            Divider()

            // Notes section (if needed)
            notesSection
        }
    }

    private var chapterScopeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chapter metadata
            ChapterMetadataSection(
                chapter: chapter,
                viewModel: viewModel
            )

            if chapter != nil {
                Divider()

                // Quick access to related characters
                relatedCharactersSection

                Divider()

                // Chapter notes
                chapterNotesSection
            }
        }
    }

    // MARK: - Additional Sections

    private var notesSection: some View {
        CollapsibleSection(
            "Notes",
            icon: "note.text",
            count: viewModel.fetchNotes(for: book).count,
            isExpanded: $viewModel.isNotesExpanded
        ) {
            if viewModel.fetchNotes(for: book).isEmpty {
                emptyNotesState
            } else {
                notesList
            }
        }
    }

    private var notesList: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.fetchNotes(for: book).sorted(), id: \.id) { note in
                NoteCard(note: note)
            }
        }
    }

    private var emptyNotesState: some View {
        VStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)

            Text("No notes")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var relatedCharactersSection: some View {
        Group {
            if let chapter = chapter, let metadata = chapter.metadata, !metadata.povCharacter.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("POV Character")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    } icon: {
                        Image(systemName: "person.circle")
                            .font(.system(size: 10))
                    }

                    // Find matching character
                    if let character = viewModel.fetchCharacters(for: book).first(where: { $0.name == metadata.povCharacter }) {
                        CharacterQuickView(character: character)
                    } else {
                        Text(metadata.povCharacter)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.quaternary.opacity(0.3))
                            }
                    }
                }
            }
        }
    }

    private var chapterNotesSection: some View {
        Group {
            if let chapter = chapter, let metadata = chapter.metadata, !metadata.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("Chapter Notes")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    } icon: {
                        Image(systemName: "note.text")
                            .font(.system(size: 10))
                    }

                    Text(metadata.notes)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary.opacity(0.3))
                        }
                }
            }
        }
    }
}

// MARK: - Note Card

private struct NoteCard: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with category
            HStack(spacing: 6) {
                Image(systemName: note.category.icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(note.category.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }

            // Title
            Text(note.extractedTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            // Content preview
            if !note.content.isEmpty {
                Text(note.contentPreview)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
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

// MARK: - Character Quick View

private struct CharacterQuickView: View {
    let character: Character

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: character.role.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(character.role.color)

                Text(character.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }

            if !character.summary.isEmpty {
                Text(character.summary)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary.opacity(0.3))
        }
    }
}

// MARK: - Previews

#Preview("Inspector - Book Scope") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, Chapter.self, ResearchItem.self, Character.self, Scene.self, Note.self,
        configurations: config
    )

    let book = Book(title: "My Novel", genre: "Fantasy")
    container.mainContext.insert(book)

    // Add some chapters
    for i in 1...3 {
        let chapter = Chapter(title: "Chapter \(i)", content: String(repeating: "Word ", count: 500), order: i - 1)
        chapter.book = book
        container.mainContext.insert(chapter)
    }

    // Add research
    let research = ResearchItem(title: "Character Photo", itemType: .image)
    research.book = book
    container.mainContext.insert(research)

    // Add character
    let character = Character(name: "Sarah", role: .protagonist)
    character.book = book
    container.mainContext.insert(character)

    return InspectorView(
        book: book,
        chapter: book.chapters.first,
        onChapterSelect: { _ in }
    )
    .frame(width: 320, height: 800)
    .modelContainer(container)
}

#Preview("Inspector - Chapter Scope") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, Chapter.self, ChapterMetadata.self,
        configurations: config
    )

    let book = Book(title: "My Novel", genre: "Fantasy")
    let chapter = Chapter(title: "Chapter 1", content: "Content", order: 0)
    chapter.book = book

    let metadata = ChapterMetadata(
        povCharacter: "Sarah",
        isCompleted: true,
        notes: "This is the opening chapter"
    )
    metadata.chapter = chapter
    chapter.metadata = metadata

    container.mainContext.insert(book)
    container.mainContext.insert(chapter)
    container.mainContext.insert(metadata)

    let inspectorView = InspectorView(
        book: book,
        chapter: chapter,
        onChapterSelect: { _ in }
    )

    // Set scope to chapter
    let _ = inspectorView.viewModel.switchScope(to: .chapter)

    return inspectorView
        .frame(width: 320, height: 800)
        .modelContainer(container)
}

#endif
