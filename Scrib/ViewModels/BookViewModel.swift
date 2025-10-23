//
//  BookViewModel.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData
import Observation

/// View model for managing Book operations
///
/// BookViewModel handles all CRUD operations for books and provides
/// business logic for book management in a SwiftUI-friendly way.
@MainActor
@Observable
final class BookViewModel {
    /// The SwiftData model context
    private let modelContext: ModelContext

    /// Currently displayed error message
    var errorMessage: String?

    /// Indicates if an operation is in progress
    var isLoading: Bool = false

    /// Initialize with a model context
    /// - Parameter modelContext: The SwiftData context for persistence
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Create a new book
    /// - Parameters:
    ///   - title: The book's title
    ///   - genre: The book's genre (defaults to "General")
    /// - Returns: The newly created book
    @discardableResult
    func createBook(title: String, genre: String = "General") -> Book {
        let book = Book(title: title, genre: genre)
        modelContext.insert(book)
        saveContext()
        return book
    }

    // MARK: - Update

    /// Update a book's metadata
    /// - Parameters:
    ///   - book: The book to update
    ///   - title: New title (optional)
    ///   - genre: New genre (optional)
    func updateBook(_ book: Book, title: String? = nil, genre: String? = nil) {
        if let title = title {
            book.title = title
        }
        if let genre = genre {
            book.genre = genre
        }
        book.lastModified = Date()
        saveContext()
    }

    /// Mark a book as modified (updates lastModified timestamp)
    /// - Parameter book: The book to mark as modified
    func markBookAsModified(_ book: Book) {
        book.lastModified = Date()
        saveContext()
    }

    // MARK: - Delete

    /// Delete a book and all its chapters (cascade delete)
    /// - Parameter book: The book to delete
    func deleteBook(_ book: Book) {
        modelContext.delete(book)
        saveContext()
    }

    /// Delete multiple books
    /// - Parameter books: Array of books to delete
    func deleteBooks(_ books: [Book]) {
        for book in books {
            modelContext.delete(book)
        }
        saveContext()
    }

    // MARK: - Fetch

    /// Fetch all books sorted by last modified date
    /// - Returns: Array of books, most recently modified first
    func fetchBooks() -> [Book] {
        let descriptor = FetchDescriptor<Book>(
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch books: \(error.localizedDescription)"
            return []
        }
    }

    /// Fetch books filtered by genre
    /// - Parameter genre: The genre to filter by
    /// - Returns: Array of books in the specified genre
    func fetchBooks(byGenre genre: String) -> [Book] {
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.genre == genre },
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch books: \(error.localizedDescription)"
            return []
        }
    }

    /// Search books by title
    /// - Parameter searchText: The text to search for
    /// - Returns: Array of books matching the search text
    func searchBooks(_ searchText: String) -> [Book] {
        guard !searchText.isEmpty else {
            return fetchBooks()
        }

        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { book in
                book.title.localizedStandardContains(searchText)
            },
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to search books: \(error.localizedDescription)"
            return []
        }
    }

    // MARK: - Utility

    /// Duplicate a book with all its chapters
    /// - Parameter book: The book to duplicate
    /// - Returns: The newly created duplicate book
    @discardableResult
    func duplicateBook(_ book: Book) -> Book {
        let newBook = Book(
            title: "\(book.title) (Copy)",
            genre: book.genre
        )

        // Duplicate all chapters
        for chapter in book.sortedChapters {
            let newChapter = Chapter(
                title: chapter.title,
                content: chapter.content,
                order: chapter.order
            )
            newChapter.book = newBook
            newBook.chapters.append(newChapter)
            modelContext.insert(newChapter)
        }

        modelContext.insert(newBook)
        saveContext()
        return newBook
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
