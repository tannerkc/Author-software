//
//  Chapter.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData

/// Represents a chapter within a book
///
/// A Chapter is the fundamental writing unit in Scrib, analogous to a note in Apple Notes.
/// Each chapter contains the actual manuscript content and maintains its own metadata.
@Model
final class Chapter {
    /// Unique identifier for the chapter
    @Attribute(.unique) var id: UUID

    /// The chapter's title (displayed in the chapter list)
    var title: String

    /// The actual manuscript content (plain text, Markdown-friendly)
    var content: String

    /// Sort order within the parent book (0-indexed)
    var order: Int

    /// Timestamp when the chapter was first created
    var dateCreated: Date

    /// Timestamp of the most recent edit to this chapter
    var lastModified: Date

    /// Reference to the parent book
    var book: Book?

    /// Initialize a new chapter
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Chapter title
    ///   - content: Manuscript content (defaults to empty string)
    ///   - order: Sort position (defaults to 0)
    ///   - dateCreated: Creation date (defaults to now)
    ///   - lastModified: Last modification date (defaults to now)
    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        order: Int = 0,
        dateCreated: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.order = order
        self.dateCreated = dateCreated
        self.lastModified = lastModified
    }

    /// Calculate the word count of the chapter content
    ///
    /// Words are defined as sequences separated by whitespace or newlines.
    /// This provides a real-time word count for the toolbar display.
    var wordCount: Int {
        let words = content.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }

    /// Calculate the character count of the chapter content
    ///
    /// Includes all characters including whitespace and punctuation.
    var characterCount: Int {
        content.count
    }

    /// Extract title from the first line of content (Apple Notes style)
    ///
    /// In the new free-form editing mode, the first line of content becomes the title.
    /// This computed property extracts that title, falling back to the stored title
    /// if the content is empty or for backward compatibility.
    var extractedTitle: String {
        // Get first line from content
        if let firstLine = content.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first {
            let extracted = String(firstLine).trimmingCharacters(in: .whitespaces)
            if !extracted.isEmpty {
                return extracted
            }
        }

        // Fallback to stored title or default
        return title.isEmpty ? "Untitled Chapter" : title
    }

    /// Get the body content (everything after the first line)
    ///
    /// Returns content excluding the title line for display purposes.
    var bodyContent: String {
        let lines = content.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        if lines.count > 1 {
            return String(lines[1])
        }
        return ""
    }

    /// Returns a preview of the chapter content (first 100 characters of body, excluding title)
    ///
    /// Used in the chapter list view to show a snippet of the content.
    var contentPreview: String {
        let body = bodyContent
        if body.isEmpty {
            return ""
        }
        let preview = body.prefix(100)
        return String(preview)
    }

    /// Returns true if the chapter has no content
    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Comparable
extension Chapter: Comparable {
    static func < (lhs: Chapter, rhs: Chapter) -> Bool {
        lhs.order < rhs.order
    }
}

// MARK: - Helper Methods
extension Chapter {
    /// Update the content and refresh the lastModified timestamp
    /// - Parameter newContent: The new content to set
    func updateContent(_ newContent: String) {
        content = newContent
        lastModified = Date()
    }

    /// Update the title and refresh the lastModified timestamp
    /// - Parameter newTitle: The new title to set
    func updateTitle(_ newTitle: String) {
        title = newTitle
        lastModified = Date()
    }
}
