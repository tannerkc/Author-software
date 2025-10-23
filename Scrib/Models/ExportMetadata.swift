//
//  ExportMetadata.swift
//  Scrib
//
//  Created by Claude on 2025-01-23.
//

import Foundation
import UIKit

/// Metadata for book exports (EPUB, PDF, DOCX)
@MainActor
struct ExportMetadata: Sendable {
    var title: String
    var author: String
    var description: String
    var genre: String
    var language: String
    var publisher: String
    var publishDate: Date
    var isbn: String
    var copyright: String

    init(
        title: String = "",
        author: String = "",
        description: String = "",
        genre: String = "",
        language: String = "en",
        publisher: String = "",
        publishDate: Date = Date(),
        isbn: String = "",
        copyright: String = ""
    ) {
        self.title = title
        self.author = author
        self.description = description
        self.genre = genre
        self.language = language
        self.publisher = publisher
        self.publishDate = publishDate
        self.isbn = isbn
        self.copyright = copyright
    }

    /// Create metadata from a Book instance
    static func from(book: Book) -> ExportMetadata {
        ExportMetadata(
            title: book.title,
            author: "",
            description: "",
            genre: book.genre,
            publishDate: book.dateCreated
        )
    }
}

/// Export format options
enum ExportFormat: String, CaseIterable, Sendable {
    case pdf = "PDF"
    case docx = "DOCX"
    case epub = "EPUB"

    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .docx: return "docx"
        case .epub: return "epub"
        }
    }

    var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .docx: return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case .epub: return "application/epub+zip"
        }
    }

    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .docx: return "doc.text"
        case .epub: return "book.closed"
        }
    }
}

/// Configuration for export operations
@MainActor
struct ExportConfiguration: Sendable {
    var format: ExportFormat
    var metadata: ExportMetadata
    var includeCoverPage: Bool
    var includeTableOfContents: Bool
    var pageSize: PageSize
    var fontSize: Double
    var fontName: String
    var lineSpacing: Double

    init(
        format: ExportFormat,
        metadata: ExportMetadata = ExportMetadata(),
        includeCoverPage: Bool = true,
        includeTableOfContents: Bool = true,
        pageSize: PageSize = .usLetter,
        fontSize: Double = 12.0,
        fontName: String = "Times New Roman",
        lineSpacing: Double = 1.5
    ) {
        self.format = format
        self.metadata = metadata
        self.includeCoverPage = includeCoverPage
        self.includeTableOfContents = includeTableOfContents
        self.pageSize = pageSize
        self.fontSize = fontSize
        self.fontName = fontName
        self.lineSpacing = lineSpacing
    }
}

/// Page size options for PDF export
enum PageSize: String, CaseIterable, Sendable {
    case usLetter = "US Letter"
    case a4 = "A4"
    case a5 = "A5"
    case custom = "Custom"

    var size: CGSize {
        switch self {
        case .usLetter: return CGSize(width: 612, height: 792) // 8.5" x 11" in points
        case .a4: return CGSize(width: 595, height: 842) // 210mm x 297mm in points
        case .a5: return CGSize(width: 420, height: 595) // 148mm x 210mm in points
        case .custom: return CGSize(width: 612, height: 792) // Default to US Letter
        }
    }

    var margins: UIEdgeInsets {
        UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72) // 1 inch margins
    }
}
