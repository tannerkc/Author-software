//
//  Note.swift
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

fileprivate extension UIColor {
    static var labelColor: UIColor { .label }
    static var secondaryLabelColor: UIColor { .secondaryLabel }
    static var tertiaryLabelColor: UIColor { .tertiaryLabel }
}
#elseif canImport(AppKit)
import AppKit
fileprivate typealias PlatformFont = NSFont
fileprivate typealias PlatformColor = NSColor
#endif

/// Represents a writer's note or idea
///
/// Notes are for brainstorming, ideas, character development, and general
/// non-manuscript content. They're organized separately from chapters and scenes
/// in the Materials section.
@Model
final class Note {
    /// Unique identifier for the note
    @Attribute(.unique) var id: UUID

    /// The note's title
    var title: String

    /// The note content
    var content: String

    /// Sort order within the parent book (0-indexed)
    var order: Int

    /// Timestamp when the note was first created
    var dateCreated: Date

    /// Timestamp of the most recent edit
    var lastModified: Date

    /// Rich text formatting data (stored as RTF)
    var formattedContent: Data?

    /// Reference to the parent book
    var book: Book?

    /// Note category/type
    var category: NoteCategory

    /// Tags for organization
    var tags: [String]

    /// Color label for visual organization
    var colorLabel: String

    /// Pin note to top of list
    var isPinned: Bool

    /// Initialize a new note
    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        order: Int = 0,
        dateCreated: Date = Date(),
        lastModified: Date = Date(),
        category: NoteCategory = .general,
        tags: [String] = [],
        colorLabel: String = "",
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.order = order
        self.dateCreated = dateCreated
        self.lastModified = lastModified
        self.category = category
        self.tags = tags
        self.colorLabel = colorLabel
        self.isPinned = isPinned
    }

    /// Calculate the word count
    var wordCount: Int {
        let words = content.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }

    /// Calculate the character count
    var characterCount: Int {
        content.count
    }

    /// Extract title from first line if empty
    var extractedTitle: String {
        if let firstLine = content.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first {
            let extracted = String(firstLine).trimmingCharacters(in: .whitespaces)
            if !extracted.isEmpty {
                return extracted
            }
        }
        return title.isEmpty ? "Untitled Note" : title
    }

    /// Content preview (first 100 characters)
    var contentPreview: String {
        let preview = content.prefix(100)
        return String(preview)
    }

    /// Returns true if the note has no content
    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Note Category
enum NoteCategory: String, Codable, CaseIterable, Identifiable {
    case general = "General"
    case character = "Character"
    case plot = "Plot"
    case worldBuilding = "World Building"
    case research = "Research"
    case brainstorm = "Brainstorm"
    case outline = "Outline"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "note.text"
        case .character: return "person.text.rectangle"
        case .plot: return "chart.line.uptrend.xyaxis"
        case .worldBuilding: return "globe"
        case .research: return "book"
        case .brainstorm: return "lightbulb"
        case .outline: return "list.bullet.indent"
        }
    }
}

// MARK: - Comparable
extension Note: Comparable {
    static func < (lhs: Note, rhs: Note) -> Bool {
        // Pinned notes always come first
        if lhs.isPinned != rhs.isPinned {
            return lhs.isPinned
        }
        return lhs.order < rhs.order
    }
}

// MARK: - Helper Methods
extension Note {
    /// Update the content and refresh the lastModified timestamp
    func updateContent(_ newContent: String) {
        content = newContent
        lastModified = Date()
    }

    /// Update the title and refresh the lastModified timestamp
    func updateTitle(_ newTitle: String) {
        title = newTitle
        lastModified = Date()
    }

    /// Get the attributed content from stored RTF data
    @MainActor
    func getAttributedContent() -> NSAttributedString {
        if let rtfData = formattedContent {
            do {
                let attributedString = try NSAttributedString(
                    data: rtfData,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
                return attributedString
            } catch {
                print("❌ RTF loading failed: \(error.localizedDescription)")
            }
        }

        // Create default attributed string from plain text
        let defaultFont = PlatformFont.systemFont(ofSize: 17)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .foregroundColor: PlatformColor.labelColor
        ]
        return NSAttributedString(string: content, attributes: attributes)
    }

    /// Save attributed content with dual storage (plain text + RTF)
    func setAttributedContent(_ attributedString: NSAttributedString) {
        content = attributedString.string
        lastModified = Date()

        let range = NSRange(location: 0, length: attributedString.length)
        do {
            let rtfData = try attributedString.data(
                from: range,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            formattedContent = rtfData
        } catch {
            formattedContent = nil
            print("⚠️ RTF conversion failed: \(error.localizedDescription)")
        }
    }
}
