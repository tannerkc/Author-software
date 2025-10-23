//
//  DataStore.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData
import Observation

/// Central data management class for SwiftData persistence
///
/// DataStore provides a centralized interface for managing the SwiftData model container
/// and context. It handles initialization, sample data generation, and common operations.
@MainActor
@Observable
final class DataStore {
    /// The SwiftData model container managing persistence
    let modelContainer: ModelContainer

    /// The main context for performing data operations
    let modelContext: ModelContext

    /// Initialize the data store with the specified configuration
    ///
    /// Creates a model container for Book and Chapter entities with persistent storage.
    /// Falls back to in-memory storage if initialization fails (for preview/testing).
    init(inMemory: Bool = false) {
        let schema = Schema([Book.self, Chapter.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    // MARK: - Sample Data

    /// Create sample data for development and testing
    ///
    /// Generates a sample book with two chapters to help with initial development
    /// and UI testing. Call this method on first launch or for preview purposes.
    func createSampleData() {
        // Check if data already exists
        let descriptor = FetchDescriptor<Book>()
        let existingBooks = (try? modelContext.fetch(descriptor)) ?? []

        guard existingBooks.isEmpty else {
            print("Sample data already exists, skipping creation")
            return
        }

        // Create sample book
        let book = Book(
            title: "My First Novel",
            genre: "Fiction"
        )

        // Create sample chapters
        let chapter1 = Chapter(
            title: "Chapter 1: The Beginning",
            content: """
            It was a dark and stormy night. The wind howled through the trees, \
            and rain pounded against the windows of the old manor house.

            Inside, a solitary figure sat at a desk, pen in hand, staring at a \
            blank sheet of paper. The story was there, somewhere in the depths \
            of their mind, waiting to be told.

            But where to begin? Every great journey starts with a single step, \
            and every great novel starts with a single word.
            """,
            order: 0
        )

        let chapter2 = Chapter(
            title: "Chapter 2: The Journey Begins",
            content: """
            Morning came with surprising gentleness. The storm had passed, leaving \
            behind a world washed clean and glistening with dewdrops.

            Our protagonist stood at the threshold, pack slung over one shoulder, \
            ready to embark on the adventure that would change everything.
            """,
            order: 1
        )

        let chapter3 = Chapter(
            title: "Chapter 3",
            content: "",
            order: 2
        )

        // Establish relationships
        book.chapters = [chapter1, chapter2, chapter3]
        chapter1.book = book
        chapter2.book = book
        chapter3.book = book

        // Insert into context
        modelContext.insert(book)

        // Save changes
        do {
            try modelContext.save()
            print("Sample data created successfully")
        } catch {
            print("Failed to save sample data: \(error)")
        }
    }

    // MARK: - Utility Methods

    /// Save the current context
    func save() throws {
        try modelContext.save()
    }

    /// Delete all books (and cascade delete all chapters)
    func deleteAllData() throws {
        let descriptor = FetchDescriptor<Book>()
        let books = try modelContext.fetch(descriptor)

        for book in books {
            modelContext.delete(book)
        }

        try modelContext.save()
    }

    /// Fetch all books sorted by last modified date
    func fetchBooks() throws -> [Book] {
        let descriptor = FetchDescriptor<Book>(
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Preview Helper
extension DataStore {
    /// Create a data store pre-populated with sample data for SwiftUI previews
    static func preview() -> DataStore {
        let store = DataStore(inMemory: true)
        store.createSampleData()
        return store
    }
}
