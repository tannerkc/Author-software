//
//  ExportManager.swift
//  Scrib
//
//  Created by Claude on 2025-01-23.
//

import Foundation
import UniformTypeIdentifiers

/// Result of an export operation
enum ExportResult: Sendable {
    case success(URL)
    case failure(ExportError)
}

/// Export errors
enum ExportError: LocalizedError, Sendable {
    case invalidFormat
    case emptyContent
    case fileWriteFailed
    case conversionFailed(String)
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid export format"
        case .emptyContent:
            return "No content to export"
        case .fileWriteFailed:
            return "Failed to write export file"
        case .conversionFailed(let details):
            return "Export conversion failed: \(details)"
        case .unsupportedFormat:
            return "Export format not yet supported"
        }
    }
}

/// Main export coordinator for book and chapter exports
/// - Uses Swift 6.2 actor isolation for thread-safe operations
@MainActor
final class ExportManager: Sendable {
    static let shared = ExportManager()

    private init() {}

    /// Export a single chapter
    /// - Parameters:
    ///   - chapter: Chapter to export
    ///   - configuration: Export configuration
    /// - Returns: URL of exported file
    func exportChapter(
        _ chapter: Chapter,
        configuration: ExportConfiguration
    ) async throws -> URL {
        guard !chapter.isEmpty else {
            throw ExportError.emptyContent
        }

        let task = Task(name: "Export Chapter: \(chapter.extractedTitle)") {
            try await performExport(
                title: chapter.extractedTitle,
                content: [chapter],
                configuration: configuration
            )
        }

        return try await task.value
    }

    /// Export an entire book (all chapters in order)
    /// - Parameters:
    ///   - book: Book to export
    ///   - configuration: Export configuration
    /// - Returns: URL of exported file
    func exportBook(
        _ book: Book,
        configuration: ExportConfiguration
    ) async throws -> URL {
        guard book.chapterCount > 0 else {
            throw ExportError.emptyContent
        }

        let task = Task(name: "Export Book: \(book.title)") {
            try await performExport(
                title: book.title,
                content: book.sortedChapters,
                configuration: configuration
            )
        }

        return try await task.value
    }

    /// Perform the actual export based on format
    private func performExport(
        title: String,
        content: [Chapter],
        configuration: ExportConfiguration
    ) async throws -> URL {
        switch configuration.format {
        case .pdf:
            return try await PDFExporter.export(
                title: title,
                chapters: content,
                configuration: configuration
            )
        case .docx:
            return try await DOCXExporter.export(
                title: title,
                chapters: content,
                configuration: configuration
            )
        case .epub:
            return try await EPUBExporter.export(
                title: title,
                chapters: content,
                configuration: configuration
            )
        }
    }

    /// Generate a temporary file URL for export
    static func temporaryFileURL(
        for title: String,
        format: ExportFormat
    ) -> URL {
        let fileName = sanitizeFileName(title)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension(format.fileExtension)
        return fileURL
    }

    /// Sanitize a string for use as a filename
    private static func sanitizeFileName(_ string: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return string
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(200) // Limit filename length
            .description
    }
}
