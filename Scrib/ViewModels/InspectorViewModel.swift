//
//  InspectorViewModel.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData
import Observation

/// View model for managing Inspector panel operations
///
/// InspectorViewModel handles the inspector's scope (Book vs Chapter),
/// section expansion states, and queries for research materials, characters,
/// scenes, and notes.
@MainActor
@Observable
final class InspectorViewModel {
    /// The SwiftData model context
    private let modelContext: ModelContext

    /// Current inspector scope (Book-level or Chapter-level)
    var scope: InspectorScope = .book

    /// Section expansion states
    var isResearchExpanded: Bool = true
    var isMetadataExpanded: Bool = true
    var isCharactersExpanded: Bool = false
    var isScenesExpanded: Bool = false
    var isNotesExpanded: Bool = false
    var isOutlineExpanded: Bool = false

    /// Currently displayed error message
    var errorMessage: String?

    /// Search filter for materials
    var searchText: String = ""

    /// Selected research item for preview
    var selectedResearchItem: ResearchItem?

    /// Initialize with a model context
    /// - Parameter modelContext: The SwiftData context for persistence
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Research Items

    /// Fetch research items for a book
    /// - Parameter book: The book to fetch research items for
    /// - Returns: Array of research items sorted by order
    func fetchResearchItems(for book: Book) -> [ResearchItem] {
        let items = book.researchItems.sorted()

        if searchText.isEmpty {
            return items
        }

        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(searchText) ||
            item.content.localizedCaseInsensitiveContains(searchText) ||
            item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    /// Fetch research items filtered by type
    /// - Parameters:
    ///   - book: The book to fetch research items for
    ///   - type: The type to filter by
    /// - Returns: Array of filtered research items
    func fetchResearchItems(for book: Book, ofType type: ResearchItemType) -> [ResearchItem] {
        fetchResearchItems(for: book).filter { $0.itemType == type }
    }

    // MARK: - Characters

    /// Fetch characters for a book
    /// - Parameter book: The book to fetch characters for
    /// - Returns: Array of characters sorted by role and order
    func fetchCharacters(for book: Book) -> [Character] {
        let characters = book.characters.sorted()

        if searchText.isEmpty {
            return characters
        }

        return characters.filter { character in
            character.name.localizedCaseInsensitiveContains(searchText) ||
            character.physicalDescription.localizedCaseInsensitiveContains(searchText) ||
            character.personality.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Fetch characters filtered by role
    /// - Parameters:
    ///   - book: The book to fetch characters for
    ///   - role: The role to filter by
    /// - Returns: Array of filtered characters
    func fetchCharacters(for book: Book, withRole role: CharacterRole) -> [Character] {
        fetchCharacters(for: book).filter { $0.role == role }
    }

    // MARK: - Scenes

    /// Fetch scenes for a book
    /// - Parameter book: The book to fetch scenes for
    /// - Returns: Array of scenes sorted by order
    func fetchScenes(for book: Book) -> [Scene] {
        let scenes = book.scenes.sorted()

        if searchText.isEmpty {
            return scenes
        }

        return scenes.filter { scene in
            scene.title.localizedCaseInsensitiveContains(searchText) ||
            scene.synopsis.localizedCaseInsensitiveContains(searchText) ||
            scene.location.localizedCaseInsensitiveContains(searchText) ||
            scene.povCharacter.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Fetch scenes filtered by status
    /// - Parameters:
    ///   - book: The book to fetch scenes for
    ///   - status: The status to filter by
    /// - Returns: Array of filtered scenes
    func fetchScenes(for book: Book, withStatus status: SceneStatus) -> [Scene] {
        fetchScenes(for: book).filter { $0.status == status }
    }

    /// Fetch scenes filtered by POV character
    /// - Parameters:
    ///   - book: The book to fetch scenes for
    ///   - povCharacter: The POV character name
    /// - Returns: Array of filtered scenes
    func fetchScenes(for book: Book, withPOV povCharacter: String) -> [Scene] {
        fetchScenes(for: book).filter { $0.povCharacter == povCharacter }
    }

    // MARK: - Notes

    /// Fetch notes for a book
    /// - Parameter book: The book to fetch notes for
    /// - Returns: Array of notes sorted by pinned status and order
    func fetchNotes(for book: Book) -> [Note] {
        let notes = book.notes.sorted()

        if searchText.isEmpty {
            return notes
        }

        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.content.localizedCaseInsensitiveContains(searchText) ||
            note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    /// Fetch notes filtered by category
    /// - Parameters:
    ///   - book: The book to fetch notes for
    ///   - category: The category to filter by
    /// - Returns: Array of filtered notes
    func fetchNotes(for book: Book, inCategory category: NoteCategory) -> [Note] {
        fetchNotes(for: book).filter { $0.category == category }
    }

    /// Fetch only pinned notes
    /// - Parameter book: The book to fetch notes for
    /// - Returns: Array of pinned notes
    func fetchPinnedNotes(for book: Book) -> [Note] {
        fetchNotes(for: book).filter { $0.isPinned }
    }

    // MARK: - Book Outline

    /// Fetch chapters for outline view
    /// - Parameter book: The book to fetch chapters for
    /// - Returns: Array of chapters sorted by order
    func fetchChaptersForOutline(for book: Book) -> [Chapter] {
        book.sortedChapters
    }

    /// Get word count summary for a book
    /// - Parameter book: The book to analyze
    /// - Returns: Tuple with total words, chapter count, and average words per chapter
    func getWordCountSummary(for book: Book) -> (total: Int, chapters: Int, average: Int) {
        let chapters = book.chapters
        let totalWords = chapters.reduce(0) { $0 + $1.wordCount }
        let chapterCount = chapters.count
        let averageWords = chapterCount > 0 ? totalWords / chapterCount : 0

        return (total: totalWords, chapters: chapterCount, average: averageWords)
    }

    // MARK: - Scope Management

    /// Switch inspector scope
    /// - Parameter newScope: The new scope to switch to
    func switchScope(to newScope: InspectorScope) {
        scope = newScope
    }

    /// Clear search filter
    func clearSearch() {
        searchText = ""
    }

    /// Reset all section expansion states to defaults
    func resetExpansionStates() {
        isResearchExpanded = true
        isMetadataExpanded = true
        isCharactersExpanded = false
        isScenesExpanded = false
        isNotesExpanded = false
        isOutlineExpanded = false
    }
}

// MARK: - Inspector Scope

/// Defines the scope of materials shown in the inspector
enum InspectorScope: String, CaseIterable, Identifiable {
    /// Show book-level materials (research, characters, scenes, notes)
    case book = "Book"

    /// Show chapter-specific metadata and context
    case chapter = "Chapter"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .book: return "book.closed"
        case .chapter: return "doc.text"
        }
    }
}
