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
@MainActor
struct ContentView: View {
    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// All books, sorted by last modified (most recent first)
    /// Indexed on lastModified for efficient sorting (see Book model)
    @Query(sort: \Book.lastModified, order: .reverse) private var books: [Book]

    /// Currently selected book ID (UUID-based for stable macOS selection)
    @State private var selectedBookId: UUID?

    /// Currently selected chapter ID (UUID-based for stable macOS selection)
    @State private var selectedChapterId: UUID?

    /// Column visibility state
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    /// Cached filtered chapters for display
    /// CRITICAL: Store filtered chapters to avoid repeated filtering of allChapters
    @State private var chaptersToShow: [Chapter] = []

    /// Search text for filtering chapters (controlled by editor toolbar search)
    @State private var chapterSearchText = ""

    /// Look up the currently selected book from its ID
    private var selectedBook: Book? {
        guard let id = selectedBookId else { return nil }
        return books.first(where: { $0.id == id })
    }

    /// Look up the currently selected chapter from its ID
    /// Uses cached chaptersToShow array for efficient lookup
    private var selectedChapter: Chapter? {
        guard let id = selectedChapterId else { return nil }
        return chaptersToShow.first(where: { $0.id == id })
    }

    /// Filtered chapters based on search text
    /// Searches both chapter titles and content (case-insensitive)
    private var filteredChapters: [Chapter] {
        if chapterSearchText.isEmpty {
            return chaptersToShow
        } else {
            return chaptersToShow.filter { chapter in
                chapter.title.localizedCaseInsensitiveContains(chapterSearchText) ||
                chapter.content.localizedCaseInsensitiveContains(chapterSearchText)
            }
        }
    }

    /// Handle chapter selection from inspector or other sources
    /// - Parameter chapter: The chapter to select
    private func handleChapterSelection(_ chapter: Chapter) {
        // Prevent unnecessary updates if already selected
        guard selectedChapterId != chapter.id else {
            print("⏭️ Chapter already selected, skipping update")
            return
        }

        print("📍 Selecting chapter from inspector: \(chapter.extractedTitle)")

        // Direct assignment is safe because ContentView is @MainActor
        // No need for Task wrapper (Swift 6.2 best practice)
        selectedChapterId = chapter.id

        print("✅ Chapter selection updated")
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // SIDEBAR: Books - Ultra-simple inline implementation
            List(books, selection: $selectedBookId) { book in
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)

                    #if os(macOS)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                            .font(.body)
                        Text("\(book.chapterCount) chapters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    #else
                    Text(book.title)
                        .font(.body)
                    #endif
                }
                .tag(book.id)
            }
            .navigationTitle("Books")
            .toolbar {
                #if os(macOS)
                Button {

                } label: {
                    Label("New Book", systemImage: "book.badge.plus")
                }
                #else
                Button("New Book") { }
                #endif
            }

        } content: {
            // CONTENT: Chapters - Standard List selection pattern (Apple HIG)
            if selectedBook != nil {
                // Use proper List selection binding for consistency with sidebar
                // This follows 2025 NavigationSplitView best practices
                List(filteredChapters, selection: $selectedChapterId) { chapter in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chapter.title.isEmpty ? "Untitled" : chapter.title)
                            .font(.headline)
                        if !chapter.content.isEmpty {
                            Text(chapter.content)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tag(chapter.id)
                }
                .navigationTitle(selectedBook?.title ?? "Chapters")
                .toolbar {
                    #if os(macOS)
                    Button {

                    } label: {
                        Label("New Chapter", systemImage: "square.and.pencil")
                    }
                    #else
                    Button("New Chapter") { }
                    #endif
                }
            } else {
                Text("Select a book from the sidebar")
                    .foregroundStyle(.secondary)
            }

        } detail: {
            // DETAIL: Editor - Keep existing ChapterEditorView
            if let chapter = selectedChapter {
                ChapterEditorView(
                    chapter: chapter,
                    searchText: $chapterSearchText,
                    onChapterSelect: handleChapterSelection
                )
                .id(chapter.id)
                // .id() is REQUIRED to properly reset view state when switching chapters
                // Without it, onAppear doesn't fire and old content remains visible
                // The cached chapters approach prevents the infinite recursion that .id() previously caused
            } else {
                Text("Select a chapter to begin writing")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selectedBookId) { oldValue, newValue in
            // CRITICAL: Only run if bookId ACTUALLY changed
            guard oldValue != newValue else {
                print("⏭️ Book ID didn't change, skipping chapter load")
                return
            }

            // Load and cache chapters for the selected book
            // Access book.chapters ONCE with significant delay to break recursion
            Task { @MainActor in
                // Add delay to ensure we're completely out of the current render cycle
                try? await Task.sleep(for: .milliseconds(50))

                guard !Task.isCancelled else { return }

                if let book = selectedBook {
                    chaptersToShow = book.chapters.sorted { $0.order < $1.order }
                    print("📚 Loaded \(chaptersToShow.count) chapters")
                } else {
                    chaptersToShow = []
                }
            }
        }
        .onAppear {
            // Initialize chapters for initially selected book ONCE on appear
            // CRITICAL: Only access book.chapters here, not in .task which runs on EVERY view update
            if let book = selectedBook {
                chaptersToShow = book.chapters.sorted { $0.order < $1.order }
                print("📚 Initial load: \(chaptersToShow.count) chapters")
            }
        }
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
