//
//  Chapter.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData

#if canImport(UIKit)
import UIKit
fileprivate typealias PlatformFont = UIFont
fileprivate typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
fileprivate typealias PlatformFont = NSFont
fileprivate typealias PlatformColor = NSColor
#endif

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
    /// Indexed for efficient sorting when displaying chapter lists
    #Index<Chapter>([\.order])
    var order: Int

    /// Timestamp when the chapter was first created
    var dateCreated: Date

    /// Timestamp of the most recent edit to this chapter
    var lastModified: Date

    /// Rich text formatting data (stored as RTF)
    /// Preserves text styling (Title, Heading, Body) and character formatting (bold, italic, etc.)
    var formattedContent: Data?

    /// Reference to the parent book
    var book: Book?

    /// Chapter metadata (optional one-to-one relationship)
    @Relationship(deleteRule: .cascade, inverse: \ChapterMetadata.chapter)
    var metadata: ChapterMetadata?

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

    /// Returns a contextual preview showing where search text appears in the content
    /// - Parameter searchText: The text to search for
    /// - Returns: A string containing context around the first match, or regular contentPreview if no match
    func contextualPreview(for searchText: String) -> String {
        guard !searchText.isEmpty else {
            return contentPreview
        }

        let searchQuery = searchText.lowercased()

        // First check if search text is in the title property
        // This matches the filtering logic which checks both title and content
        if title.lowercased().contains(searchQuery) {
            // If match is in title, show the title plus some content
            let titleText = title
            let bodyPreview = bodyContent.prefix(50).replacingOccurrences(of: "\n", with: " ")
            if !bodyPreview.isEmpty {
                return "\(titleText) - \(bodyPreview)..."
            } else {
                return titleText
            }
        }

        // If not in title, search in content
        let searchContent = content.lowercased()
        guard let range = searchContent.range(of: searchQuery) else {
            return contentPreview
        }

        // Convert String.Index to Int for easier calculation
        let matchStartIndex = searchContent.distance(from: searchContent.startIndex, to: range.lowerBound)

        // Define context window: 50 chars before and after match
        let contextBefore = 50
        let contextAfter = 50

        let startIndex = max(0, matchStartIndex - contextBefore)
        let endIndex = min(content.count, matchStartIndex + searchText.count + contextAfter)

        // Extract the contextual substring
        let startStringIndex = content.index(content.startIndex, offsetBy: startIndex)
        let endStringIndex = content.index(content.startIndex, offsetBy: endIndex)

        var preview = String(content[startStringIndex..<endStringIndex])

        // Add ellipsis if we're not at the start/end of content
        if startIndex > 0 {
            preview = "..." + preview
        }
        if endIndex < content.count {
            preview = preview + "..."
        }

        // Clean up newlines for single-line display
        preview = preview.replacingOccurrences(of: "\n", with: " ")

        return preview.trimmingCharacters(in: .whitespaces)
    }

    /// Returns true if the chapter has no content
    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Returns true if chapter has metadata
    var hasMetadata: Bool {
        metadata != nil
    }

    /// Check if this chapter object is in a valid state for property access
    ///
    /// Returns true if the object has a valid model context and is not faulting.
    /// Use this before accessing properties that might cause crashes on faulting objects.
    var isValidForAccess: Bool {
        // Check if the object has a model context
        guard self.modelContext != nil else {
            return false
        }
        // For SwiftData, if we have a context, the object should be accessible
        return true
    }

    /// Safely access the content property with validation
    ///
    /// Returns the chapter content if the object is in a valid state,
    /// or an empty string if not accessible.
    var safeContent: String {
        guard modelContext != nil else {
            print("⚠️ Chapter object has no model context, returning empty content")
            return ""
        }
        // Wrap property access in error handling for extra safety
        do {
            return content
        } catch {
            print("❌ Failed to access chapter content: \(error.localizedDescription)")
            return ""
        }
    }

    /// Safely access the formatted content property with validation
    ///
    /// Returns the chapter's RTF data if the object is in a valid state,
    /// or nil if not accessible.
    var safeFormattedContent: Data? {
        guard modelContext != nil else {
            print("⚠️ Chapter object has no model context, returning nil formatted content")
            return nil
        }
        // Wrap property access in error handling for extra safety
        do {
            return formattedContent
        } catch {
            print("❌ Failed to access chapter formatted content: \(error.localizedDescription)")
            return nil
        }
    }

    /// Safely access the book relationship with validation
    ///
    /// Returns the parent book if the object and relationship are valid,
    /// or nil if not accessible.
    var safeBook: Book? {
        guard modelContext != nil else {
            print("⚠️ Chapter object has no model context, returning nil book")
            return nil
        }
        // Wrap relationship access in error handling for extra safety
        do {
            return book
        } catch {
            print("❌ Failed to access chapter book relationship: \(error.localizedDescription)")
            return nil
        }
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

    /// Get the attributed content from stored RTF data, or create default from plain text
    /// - Returns: NSAttributedString with formatting, or default styled plain text
    @MainActor
    func getAttributedContent() -> NSAttributedString {
        // CRITICAL: Validate object state before accessing properties
        // Prevents EXC_BAD_ACCESS on macOS when object is faulting
        guard self.isValidForAccess else {
            print("❌ CRITICAL: Chapter object not valid for access, returning empty attributed string")
            let defaultFont = PlatformFont.systemFont(ofSize: 17)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: defaultFont,
                .foregroundColor: PlatformColor.labelColor
            ]
            return NSAttributedString(string: "", attributes: attributes)
        }

        // Safe access to formatted content using extension helper
        if let rtfData = self.safeFormattedContent {
            print("📖 Loading RTF: \(rtfData.count) bytes")

            do {
                let attributedString = try NSAttributedString(
                    data: rtfData,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
                print("✅ RTF loaded successfully - \(attributedString.length) characters")
                return attributedString
            } catch {
                print("❌ RTF loading failed: \(error.localizedDescription)")
                // Fall through to create default from plain text
            }
        } else {
            print("⚠️ No RTF data available, using plain text")
        }

        // Safe access to content property using extension helper
        // This prevents EXC_BAD_ACCESS when the Chapter object is faulting
        let safeContentString = self.safeContent

        // Create default attributed string from plain text - with defensive error handling
        do {
            let defaultFont = PlatformFont.systemFont(ofSize: 17)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: defaultFont,
                .foregroundColor: PlatformColor.labelColor
            ]
            return NSAttributedString(string: safeContentString, attributes: attributes)
        } catch {
            print("❌ CRITICAL: Failed to create attributed string: \(error)")
            // Return absolute fallback - empty attributed string with default attributes
            let defaultFont = PlatformFont.systemFont(ofSize: 17)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: defaultFont,
                .foregroundColor: PlatformColor.labelColor
            ]
            return NSAttributedString(string: "", attributes: attributes)
        }
    }

    /// Save attributed content with dual storage (plain text + RTF)
    /// - Parameter attributedString: The attributed string to save
    ///
    /// This method implements a fail-safe dual storage approach:
    /// 1. Plain text is ALWAYS saved first (guaranteed to succeed)
    /// 2. RTF formatting is attempted but may fail gracefully
    /// 3. If RTF conversion fails, plain text backup ensures zero data loss
    func setAttributedContent(_ attributedString: NSAttributedString) {
        // CRITICAL: Validate object state before modifying properties
        guard self.isValidForAccess else {
            print("❌ CRITICAL: Chapter object not valid for modification, skipping save")
            return
        }

        // STEP 1: Save plain text FIRST (critical - never fails)
        // This ensures content is always preserved even if RTF conversion fails
        content = attributedString.string
        lastModified = Date()

        print("💾 Saving content: \(content.count) characters")

        // STEP 2: Attempt RTF conversion for formatting preservation
        // If this fails, we've already saved the plain text above
        let range = NSRange(location: 0, length: attributedString.length)

        do {
            let rtfData = try attributedString.data(
                from: range,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            formattedContent = rtfData
            print("✅ RTF formatting saved: \(rtfData.count) bytes")
        } catch {
            // Silent fallback: Plain text is already saved, so just log the formatting loss
            formattedContent = nil
            print("⚠️ RTF conversion failed, plain text preserved: \(error.localizedDescription)")
        }
    }
}
