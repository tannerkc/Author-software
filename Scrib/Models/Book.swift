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
    var lastModified: Date

    /// Collection of chapters belonging to this book
    /// Cascade delete ensures chapters are removed when book is deleted
    @Relationship(deleteRule: .cascade, inverse: \Chapter.book)
    var chapters: [Chapter]

    /// Initialize a new book
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Book title
    ///   - genre: Genre classification (defaults to "General")
    ///   - dateCreated: Creation date (defaults to now)
    ///   - lastModified: Last modification date (defaults to now)
    ///   - chapters: Initial chapters (defaults to empty array)
    init(
        id: UUID = UUID(),
        title: String,
        genre: String = "General",
        dateCreated: Date = Date(),
        lastModified: Date = Date(),
        chapters: [Chapter] = []
    ) {
        self.id = id
        self.title = title
        self.genre = genre
        self.dateCreated = dateCreated
        self.lastModified = lastModified
        self.chapters = chapters
    }

    /// Returns chapters sorted by their order property
    var sortedChapters: [Chapter] {
        chapters.sorted { $0.order < $1.order }
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
}

// MARK: - Comparable
extension Book: Comparable {
    static func < (lhs: Book, rhs: Book) -> Bool {
        lhs.lastModified > rhs.lastModified // Most recent first
    }
}
