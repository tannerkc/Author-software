//
//  ChapterViewModel.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData
import Observation

/// View model for managing Chapter operations
///
/// ChapterViewModel handles all CRUD operations for chapters, including
/// auto-save functionality with debouncing and chapter reordering.
@MainActor
@Observable
final class ChapterViewModel {
    /// The SwiftData model context
    private let modelContext: ModelContext

    /// Currently displayed error message
    var errorMessage: String?

    /// Indicates if an operation is in progress
    var isLoading: Bool = false

    /// Tracks the last save time for display
    var lastSaveTime: Date?

    /// Auto-save task for debouncing
    private var autoSaveTask: Task<Void, Never>?

    /// Auto-save delay in seconds (1 second debounce)
    private let autoSaveDelay: TimeInterval = 1.0

    /// Initialize with a model context
    /// - Parameter modelContext: The SwiftData context for persistence
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Create a new chapter in a book
    /// - Parameters:
    ///   - book: The parent book
    ///   - title: The chapter's title
    ///   - content: Initial content (defaults to empty string)
    /// - Returns: The newly created chapter
    @discardableResult
    func createChapter(in book: Book, title: String, content: String = "") -> Chapter {
        // Determine the order for the new chapter (append to end)
        let maxOrder = book.chapters.map(\.order).max() ?? -1
        let newOrder = maxOrder + 1

        let chapter = Chapter(
            title: title,
            content: content,
            order: newOrder
        )

        chapter.book = book
        book.chapters.append(chapter)
        book.lastModified = Date()

        modelContext.insert(chapter)
        saveContext()

        return chapter
    }

    // MARK: - Update

    /// Update a chapter's content with auto-save debouncing
    /// - Parameters:
    ///   - chapter: The chapter to update
    ///   - content: New content
    func updateChapterContent(_ chapter: Chapter, content: String) {
        chapter.content = content
        // Sync the extracted title back to the title property for backward compatibility
        chapter.title = chapter.extractedTitle
        scheduleAutoSave(for: chapter)
    }

    /// Update a chapter's title immediately
    /// - Parameters:
    ///   - chapter: The chapter to update
    ///   - title: New title
    func updateChapterTitle(_ chapter: Chapter, title: String) {
        chapter.title = title
        chapter.lastModified = Date()
        chapter.book?.lastModified = Date()
        saveContext()
    }

    /// Manually save a chapter (for Cmd+S or explicit save)
    /// - Parameter chapter: The chapter to save
    func saveChapter(_ chapter: Chapter) {
        // Cancel any pending auto-save
        autoSaveTask?.cancel()
        autoSaveTask = nil

        chapter.lastModified = Date()
        chapter.book?.lastModified = Date()
        saveContext()
        lastSaveTime = Date()
    }

    // MARK: - Delete

    /// Delete a chapter
    /// - Parameter chapter: The chapter to delete
    func deleteChapter(_ chapter: Chapter) {
        // Update book's lastModified
        chapter.book?.lastModified = Date()

        // Reorder remaining chapters
        if let book = chapter.book {
            let remainingChapters = book.chapters.filter { $0.id != chapter.id }
            for (index, ch) in remainingChapters.sorted(by: { $0.order < $1.order }).enumerated() {
                ch.order = index
            }
        }

        modelContext.delete(chapter)
        saveContext()
    }

    /// Delete multiple chapters
    /// - Parameter chapters: Array of chapters to delete
    func deleteChapters(_ chapters: [Chapter]) {
        for chapter in chapters {
            chapter.book?.lastModified = Date()
            modelContext.delete(chapter)
        }
        saveContext()
    }

    // MARK: - Reorder

    /// Reorder chapters within a book
    /// - Parameters:
    ///   - book: The book containing the chapters
    ///   - source: Source indices
    ///   - destination: Destination index
    func reorderChapters(in book: Book, from source: IndexSet, to destination: Int) {
        var sortedChapters = book.sortedChapters

        // Perform the move
        sortedChapters.move(fromOffsets: source, toOffset: destination)

        // Update order properties
        for (index, chapter) in sortedChapters.enumerated() {
            chapter.order = index
        }

        book.lastModified = Date()
        saveContext()
    }

    // MARK: - Utility

    /// Duplicate a chapter within the same book
    /// - Parameter chapter: The chapter to duplicate
    /// - Returns: The newly created duplicate chapter
    @discardableResult
    func duplicateChapter(_ chapter: Chapter) -> Chapter? {
        guard let book = chapter.book else { return nil }

        let newChapter = Chapter(
            title: "\(chapter.title) (Copy)",
            content: chapter.content,
            order: chapter.order + 1
        )

        // Shift subsequent chapters
        for ch in book.chapters where ch.order > chapter.order {
            ch.order += 1
        }

        newChapter.book = book
        book.chapters.append(newChapter)
        book.lastModified = Date()

        modelContext.insert(newChapter)
        saveContext()

        return newChapter
    }

    /// Move a chapter to a different book
    /// - Parameters:
    ///   - chapter: The chapter to move
    ///   - targetBook: The destination book
    func moveChapter(_ chapter: Chapter, to targetBook: Book) {
        // Remove from current book
        chapter.book?.lastModified = Date()

        // Add to target book
        let maxOrder = targetBook.chapters.map(\.order).max() ?? -1
        chapter.order = maxOrder + 1
        chapter.book = targetBook
        targetBook.chapters.append(chapter)
        targetBook.lastModified = Date()

        saveContext()
    }

    // MARK: - Metadata Operations

    /// Create or get metadata for a chapter
    /// - Parameter chapter: The chapter
    /// - Returns: The chapter's metadata (existing or newly created)
    func getOrCreateMetadata(for chapter: Chapter) -> ChapterMetadata {
        if let existing = chapter.metadata {
            return existing
        }

        let metadata = ChapterMetadata()
        metadata.chapter = chapter
        chapter.metadata = metadata

        modelContext.insert(metadata)
        saveContext()

        return metadata
    }

    /// Update chapter metadata
    /// - Parameters:
    ///   - chapter: The chapter
    ///   - metadata: The metadata to update
    func updateMetadata(for chapter: Chapter, with metadata: ChapterMetadata) {
        metadata.lastModified = Date()
        chapter.lastModified = Date()
        chapter.book?.lastModified = Date()
        saveContext()
    }

    /// Delete chapter metadata
    /// - Parameter chapter: The chapter whose metadata to delete
    func deleteMetadata(for chapter: Chapter) {
        guard let metadata = chapter.metadata else { return }

        chapter.metadata = nil
        modelContext.delete(metadata)
        chapter.lastModified = Date()
        chapter.book?.lastModified = Date()
        saveContext()
    }

    // MARK: - Auto-Save

    /// Schedule an auto-save with debouncing
    /// - Parameter chapter: The chapter to auto-save
    private func scheduleAutoSave(for chapter: Chapter) {
        // Cancel any existing auto-save task
        autoSaveTask?.cancel()

        // Schedule new auto-save task
        autoSaveTask = Task { [weak self] in
            guard let self else { return }

            // Wait for the debounce delay
            try? await Task.sleep(for: .seconds(self.autoSaveDelay))

            // Check if task was cancelled
            guard !Task.isCancelled else { return }

            // Perform the save
            await self.performAutoSave(for: chapter)
        }
    }

    /// Perform the actual auto-save
    /// - Parameter chapter: The chapter to save
    private func performAutoSave(for chapter: Chapter) {
        chapter.lastModified = Date()
        chapter.book?.lastModified = Date()
        saveContext()
        lastSaveTime = Date()
    }

    // MARK: - Private Helpers

    /// Save the model context and handle any errors
    private func saveContext() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print("Save error: \(error)")
        }
    }
}
