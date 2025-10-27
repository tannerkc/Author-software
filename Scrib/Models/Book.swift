//
//  Book.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData

/// Represents a book containing multiple chapters
///
/// A Book is the top-level organizational unit in Scrib, analogous to a folder in Apple Notes.
/// Each book contains an ordered collection of chapters and maintains metadata about the manuscript.
@Model
final class Book {
    /// Unique identifier for the book
    @Attribute(.unique) var id: UUID

    /// The book's title (displayed in the sidebar)
    var title: String

    /// Genre classification (e.g., "Fiction", "Non-Fiction", "Memoir")
    var genre: String

    /// Timestamp when the book was first created
    var dateCreated: Date

    /// Timestamp of the most recent modification to the book or any of its chapters
    /// Indexed for efficient sorting in queries
    #Index<Book>([\.lastModified], [\.title])
    var lastModified: Date

    /// Collection of chapters belonging to this book
    /// Cascade delete ensures chapters are removed when book is deleted
    @Relationship(deleteRule: .cascade, inverse: \Chapter.book)
    var chapters: [Chapter]

    /// Collection of scenes belonging to this book
    @Relationship(deleteRule: .cascade, inverse: \Scene.book)
    var scenes: [Scene]

    /// Collection of notes belonging to this book
    @Relationship(deleteRule: .cascade, inverse: \Note.book)
    var notes: [Note]

    /// Collection of research items belonging to this book
    @Relationship(deleteRule: .cascade, inverse: \ResearchItem.book)
    var researchItems: [ResearchItem]

    /// Collection of characters in this book
    @Relationship(deleteRule: .cascade, inverse: \Character.book)
    var characters: [Character]

    /// Initialize a new book
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Book title
    ///   - genre: Genre classification (defaults to "General")
    ///   - dateCreated: Creation date (defaults to now)
    ///   - lastModified: Last modification date (defaults to now)
    ///   - chapters: Initial chapters (defaults to empty array)
    ///   - scenes: Initial scenes (defaults to empty array)
    ///   - notes: Initial notes (defaults to empty array)
    ///   - researchItems: Initial research items (defaults to empty array)
    ///   - characters: Initial characters (defaults to empty array)
    init(
        id: UUID = UUID(),
        title: String,
        genre: String = "General",
        dateCreated: Date = Date(),
        lastModified: Date = Date(),
        chapters: [Chapter] = [],
        scenes: [Scene] = [],
        notes: [Note] = [],
        researchItems: [ResearchItem] = [],
        characters: [Character] = []
    ) {
        self.id = id
        self.title = title
        self.genre = genre
        self.dateCreated = dateCreated
        self.lastModified = lastModified
        self.chapters = chapters
        self.scenes = scenes
        self.notes = notes
        self.researchItems = researchItems
        self.characters = characters
    }

    /// Returns chapters sorted by their order property
    var sortedChapters: [Chapter] {
        chapters.sorted { $0.order < $1.order }
    }

    /// Returns scenes sorted by their order property
    var sortedScenes: [Scene] {
        scenes.sorted { $0.order < $1.order }
    }

    /// Returns notes sorted (pinned first, then by order)
    var sortedNotes: [Note] {
        notes.sorted()
    }

    /// Returns research items sorted by their order property
    var sortedResearchItems: [ResearchItem] {
        researchItems.sorted { $0.order < $1.order }
    }

    /// Returns characters sorted by role and order
    var sortedCharacters: [Character] {
        characters.sorted()
    }

    /// Calculate the total word count across all chapters
    var totalWordCount: Int {
        chapters.reduce(0) { $0 + $1.wordCount }
    }

    /// Calculate the total character count across all chapters
    var totalCharacterCount: Int {
        chapters.reduce(0) { $0 + $1.characterCount }
    }

    /// The number of chapters in this book
    var chapterCount: Int {
        chapters.count
    }

    /// The number of scenes in this book
    var sceneCount: Int {
        scenes.count
    }

    /// The number of notes in this book
    var noteCount: Int {
        notes.count
    }

    /// The number of research items in this book
    var researchItemCount: Int {
        researchItems.count
    }

    /// The number of characters in this book
    var characterCount: Int {
        characters.count
    }

    /// Total material count (all non-chapter items)
    var materialCount: Int {
        sceneCount + noteCount + researchItemCount + characterCount
    }
}

// MARK: - Comparable
extension Book: Comparable {
    static func < (lhs: Book, rhs: Book) -> Bool {
        lhs.lastModified > rhs.lastModified // Most recent first
    }
}
