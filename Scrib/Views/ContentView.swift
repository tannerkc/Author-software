//
//  ContentView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// Root view for the Scrib application
///
/// ContentView implements the three-column layout structure:
/// - Sidebar: List of Books
/// - Content: List of Chapters in the selected Book
/// - Detail: Chapter editor for the selected Chapter
///
/// This mirrors the Apple Notes layout and navigation pattern.
struct ContentView: View {
    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// All books, sorted by last modified (most recent first)
    @Query(sort: \Book.lastModified, order: .reverse) private var books: [Book]

    /// Currently selected book ID (UUID-based for stable macOS selection)
    @State private var selectedBookId: UUID?

    /// Currently selected chapter ID (UUID-based for stable macOS selection)
    @State private var selectedChapterId: UUID?

    /// Column visibility state
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    /// Look up the currently selected book from its ID
    private var selectedBook: Book? {
        guard let id = selectedBookId else { return nil }
        return books.first(where: { $0.id == id })
    }

    /// Look up the currently selected chapter from its ID
    private var selectedChapter: Chapter? {
        guard let id = selectedChapterId,
              let book = selectedBook else { return nil }
        return book.chapters.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - Sidebar (Books)
            BookListView(
                books: books,
                selection: $selectedBookId
            )
            .navigationSplitViewColumnWidth(
                min: 200,
                ideal: 250,
                max: 300
            )
        } content: {
            // MARK: - Content (Chapters)
            // Direct conditional view - ZStack workaround no longer needed in modern SwiftUI
            // and was blocking selection interaction on macOS
            if let book = selectedBook {
                ChapterListView(
                    book: book,
                    selection: $selectedChapterId
                )
                .navigationSplitViewColumnWidth(
                    min: 200,
                    ideal: 300,
                    max: 400
                )
            } else {
                ContentUnavailableView(
                    "No Book Selected",
                    systemImage: "book.closed",
                    description: Text("Select a book from the sidebar to view its chapters")
                )
            }
        } detail: {
            // MARK: - Detail (Editor)
            if let chapter = selectedChapter {
                ChapterEditorView(chapter: chapter)
                    .id(chapter.id)  // Force view rebuild when selection changes (SwiftData fix)
            } else if selectedBook != nil {
                ContentUnavailableView(
                    "No Chapter Selected",
                    systemImage: "doc.text",
                    description: Text("Select a chapter to begin writing")
                )
            } else {
                ContentUnavailableView(
                    "Welcome to Scrib",
                    systemImage: "pencil.and.list.clipboard",
                    description: Text("Create a book to start writing your manuscript")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Previews
#Preview("With Sample Data") {
    ContentView()
        .modelContainer(DataStore.preview().modelContainer)
}

#Preview("Empty State") {
    ContentView()
        .modelContainer(DataStore(inMemory: true).modelContainer)
}
