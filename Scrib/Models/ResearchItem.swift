//
//  ResearchItem.swift
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

// MARK: - Cross-Platform Color Extensions
extension PlatformColor {
    fileprivate static var labelColor: PlatformColor {
        #if canImport(UIKit)
        return UIColor.label
        #elseif canImport(AppKit)
        return NSColor.labelColor
        #endif
    }
}

/// Represents a research item or reference material
///
/// Research items store reference materials, web links, images, PDFs,
/// and other supporting documentation for the book project.
@Model
final class ResearchItem {
    /// Unique identifier for the research item
    @Attribute(.unique) var id: UUID

    /// The item's title
    var title: String

    /// The item content/notes
    var content: String

    /// Sort order within the parent book (0-indexed)
    var order: Int

    /// Timestamp when the item was first created
    var dateCreated: Date

    /// Timestamp of the most recent edit
    var lastModified: Date

    /// Rich text formatting data (stored as RTF)
    var formattedContent: Data?

    /// Reference to the parent book
    var book: Book?

    /// Type of research item
    var itemType: ResearchItemType

    /// Source URL or citation
    var source: String

    /// Tags for organization
    var tags: [String]

    /// File attachment data (for PDFs, images, etc.)
    var attachmentData: Data?

    /// Attachment filename
    var attachmentFilename: String?

    /// Attachment MIME type
    var attachmentMimeType: String?

    /// Color label for visual organization
    var colorLabel: String

    /// Initialize a new research item
    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        order: Int = 0,
        dateCreated: Date = Date(),
        lastModified: Date = Date(),
        itemType: ResearchItemType = .general,
        source: String = "",
        tags: [String] = [],
        attachmentData: Data? = nil,
        attachmentFilename: String? = nil,
        attachmentMimeType: String? = nil,
        colorLabel: String = ""
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.order = order
        self.dateCreated = dateCreated
        self.lastModified = lastModified
        self.itemType = itemType
        self.source = source
        self.tags = tags
        self.attachmentData = attachmentData
        self.attachmentFilename = attachmentFilename
        self.attachmentMimeType = attachmentMimeType
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
        return title.isEmpty ? "Untitled Research" : title
    }

    /// Content preview (first 100 characters)
    var contentPreview: String {
        let preview = content.prefix(100)
        return String(preview)
    }

    /// Returns true if the item has no content
    var isEmpty: Bool {
        content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachmentData == nil
    }

    /// Check if item has an attachment
    var hasAttachment: Bool {
        attachmentData != nil
    }
}

// MARK: - Research Item Type
enum ResearchItemType: String, Codable, CaseIterable, Identifiable {
    case general = "General"
    case webLink = "Web Link"
    case document = "Document"
    case image = "Image"
    case pdf = "PDF"
    case quote = "Quote"
    case reference = "Reference"
    case historical = "Historical"
    case technical = "Technical"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "doc.text"
        case .webLink: return "link"
        case .document: return "doc"
        case .image: return "photo"
        case .pdf: return "doc.richtext"
        case .quote: return "quote.bubble"
        case .reference: return "book.closed"
        case .historical: return "clock"
        case .technical: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - Comparable
extension ResearchItem: Comparable {
    static func < (lhs: ResearchItem, rhs: ResearchItem) -> Bool {
        lhs.order < rhs.order
    }
}

// MARK: - Helper Methods
extension ResearchItem {
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
