//
//  Scene.swift
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

/// Represents a scene within a book
///
/// Scenes are smaller writing units than chapters, often representing a single
/// continuous action or setting. In Scrivener-style organization, multiple scenes
/// can be combined into chapters during compilation.
@Model
final class Scene {
    /// Unique identifier for the scene
    @Attribute(.unique) var id: UUID

    /// The scene's title
    var title: String

    /// The actual scene content (plain text, Markdown-friendly)
    var content: String

    /// Sort order within the parent book (0-indexed)
    var order: Int

    /// Timestamp when the scene was first created
    var dateCreated: Date

    /// Timestamp of the most recent edit
    var lastModified: Date

    /// Rich text formatting data (stored as RTF)
    var formattedContent: Data?

    /// Reference to the parent book
    var book: Book?

    /// Scene synopsis/summary for outlining
    var synopsis: String

    /// Scene status (draft, revised, final)
    var status: SceneStatus

    /// POV character for this scene
    var povCharacter: String

    /// Scene location/setting
    var location: String

    /// Time of day for the scene
    var timeOfDay: String

    /// Story date/timeline position
    var storyDate: Date?

    /// Color label for visual organization
    var colorLabel: String

    /// Initialize a new scene
    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        order: Int = 0,
        dateCreated: Date = Date(),
        lastModified: Date = Date(),
        synopsis: String = "",
        status: SceneStatus = .draft,
        povCharacter: String = "",
        location: String = "",
        timeOfDay: String = "",
        storyDate: Date? = nil,
        colorLabel: String = ""
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.order = order
        self.dateCreated = dateCreated
        self.lastModified = lastModified
        self.synopsis = synopsis
        self.status = status
        self.povCharacter = povCharacter
        self.location = location
        self.timeOfDay = timeOfDay
        self.storyDate = storyDate
        self.colorLabel = colorLabel
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
        return title.isEmpty ? "Untitled Scene" : title
    }

    /// Content preview (first 100 characters)
    var contentPreview: String {
        let preview = content.prefix(100)
        return String(preview)
    }

    /// Returns true if the scene has no content
    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Scene Status
enum SceneStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "Draft"
    case revised = "Revised"
    case final = "Final"
    case needsWork = "Needs Work"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .draft: return "pencil"
        case .revised: return "checkmark"
        case .final: return "checkmark.circle.fill"
        case .needsWork: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Comparable
extension Scene: Comparable {
    static func < (lhs: Scene, rhs: Scene) -> Bool {
        lhs.order < rhs.order
    }
}

// MARK: - Helper Methods
extension Scene {
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
