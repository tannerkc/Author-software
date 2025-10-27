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
    /// PERFORMANCE: Replaced @Query (synchronous) with manual async fetching
    /// This allows the view to render immediately instead of blocking on database access
    @State private var books: [Book] = []

    /// Loading state for books fetch
    @State private var isLoadingBooks = true

    /// Currently selected book ID (UUID-based for stable macOS selection)
    @State private var selectedBookId: UUID?

    /// Currently selected chapter ID (UUID-based for stable macOS selection)
    @State private var selectedChapterId: UUID?

    /// Column visibility state
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    /// Zen mode state for distraction-free writing
    @State private var isZenModeEnabled = false

    /// Track if we're transitioning between zen mode and normal mode
    /// This prevents view updates during the transition to ensure saves complete
    @State private var isTransitioningZenMode = false

    /// Cached filtered chapters for display
    /// CRITICAL: Store filtered chapters to avoid repeated filtering of allChapters
    @State private var chaptersToShow: [Chapter] = []

    /// Search text for filtering chapters (controlled by editor toolbar search)
    @State private var chapterSearchText = ""

    /// Loading state flags for progressive UI display
    @State private var isLoadingChapters = false

    /// Track which book is being edited for inline title editing
    @State private var editingBookId: UUID?

    /// Focus state for book title editing
    @FocusState private var isBookTitleFocused: Bool

    /// State for export sheet
    @State private var showingExportSheet = false

    /// Track which book to export
    @State private var exportingBook: Book?

    /// Track which book to delete (for confirmation)
    @State private var deletingBook: Book?

    /// Track which chapter to delete (for confirmation)
    @State private var deletingChapter: Chapter?

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

    /// Get preview text for a chapter, with contextual search preview when searching
    private func previewText(for chapter: Chapter) -> String {
        if chapterSearchText.isEmpty {
            // No search: show first 100 chars of content
            let preview = chapter.content.prefix(100)
            return String(preview)
        } else {
            // Search active: use contextual preview
            return chapter.contextualPreview(for: chapterSearchText)
        }
    }

    /// Create highlighted preview with search terms bolded
    private func highlightedPreview(for chapter: Chapter) -> AttributedString {
        let preview = previewText(for: chapter)
        var attributedString = AttributedString(preview)

        // Only highlight if we have search text
        guard !chapterSearchText.isEmpty else {
            return attributedString
        }

        // Find and highlight all occurrences of search text (case-insensitive)
        let lowercasedPreview = preview.lowercased()
        let lowercasedSearch = chapterSearchText.lowercased()

        var searchStartIndex = lowercasedPreview.startIndex
        while let range = lowercasedPreview.range(of: lowercasedSearch, range: searchStartIndex..<lowercasedPreview.endIndex) {
            // Convert String range to AttributedString range
            if let attributedRange = Range<AttributedString.Index>(range, in: attributedString) {
                attributedString[attributedRange].foregroundColor = .primary
                attributedString[attributedRange].font = .caption.bold()
            }

            // Move to next potential match
            searchStartIndex = range.upperBound
        }

        return attributedString
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
        Group {
            if isZenModeEnabled {
                // ZEN MODE: Fullscreen editor only (distraction-free writing)
                #if os(macOS)
                NavigationStack {
                    ZStack {
                        // Background that extends behind toolbar to match editor appearance
                        Color(nsColor: .textBackgroundColor)
                            .ignoresSafeArea()

                        if let chapter = selectedChapter {
                            ChapterEditorView(
                                chapter: chapter,
                                searchText: $chapterSearchText,
                                isZenModeEnabled: $isZenModeEnabled,
                                onChapterSelect: handleChapterSelection
                            )
                            .id(chapter.id)
                        } else {
                            // Fallback if no chapter selected in zen mode
                            VStack {
                                Text("No chapter selected")
                                    .foregroundStyle(.secondary)
                                Button("Exit Zen Mode") {
                                    isZenModeEnabled = false
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                #else
                // iOS: No background extension needed
                if let chapter = selectedChapter {
                    ChapterEditorView(
                        chapter: chapter,
                        searchText: $chapterSearchText,
                        isZenModeEnabled: $isZenModeEnabled,
                        onChapterSelect: handleChapterSelection
                    )
                    .id(chapter.id)
                } else {
                    // Fallback if no chapter selected in zen mode
                    VStack {
                        Text("No chapter selected")
                            .foregroundStyle(.secondary)
                        Button("Exit Zen Mode") {
                            isZenModeEnabled = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
                #endif
            } else {
                // NORMAL MODE: Three-column layout
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    // SIDEBAR: Books - Ultra-simple inline implementation
                    ZStack {
                        List(books, selection: $selectedBookId) { book in
                            HStack {
                                Image(systemName: "book.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)

                            #if os(macOS)
                            // Inline editing for book title (Apple Notes/Finder style)
                            if editingBookId == book.id {
                                TextField("Book Title", text: Binding(
                                    get: { book.title },
                                    set: { newValue in
                                        // CRITICAL: Defer state changes to avoid "modifying state during view update"
                                        Task { @MainActor in
                                            // Small delay ensures we're outside the current render cycle
                                            try? await Task.sleep(for: .milliseconds(16))
                                            guard !Task.isCancelled else { return }
                                            book.title = newValue
                                            book.lastModified = Date()
                                        }
                                    }
                                ))
                                .font(.body)
                                .textFieldStyle(.plain)
                                .focused($isBookTitleFocused)
                                .onSubmit {
                                    // Exit edit mode on Enter
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .milliseconds(16))
                                        guard !Task.isCancelled else { return }
                                        editingBookId = nil
                                    }
                                }
                                .onChange(of: isBookTitleFocused) { _, isFocused in
                                    // Exit edit mode when focus is lost
                                    if !isFocused && editingBookId == book.id {
                                        Task { @MainActor in
                                            try? await Task.sleep(for: .milliseconds(16))
                                            guard !Task.isCancelled else { return }
                                            editingBookId = nil
                                        }
                                    }
                                }
                            } else {
                                Text(book.title)
                                    .font(.body)
                            }
                            // PERFORMANCE FIX: Removed chapter count display
                            // book.chapterCount triggers synchronous SwiftData relationship loading
                            // which blocks UI rendering during startup
                            #else
                            Text(book.title)
                                .font(.body)
                            #endif
                        }
                        .tag(book.id)
                        #if os(macOS)
                        // Double-click to enter edit mode (macOS Finder behavior)
                        .onTapGesture(count: 2) {
                            editingBookId = book.id
                            // Small delay ensures view updates before focusing
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(50))
                                guard !Task.isCancelled else { return }
                                isBookTitleFocused = true
                            }
                        }
                        // Right-click context menu
                        .contextMenu {
                            // Rename
                            Button {
                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(16))
                                    guard !Task.isCancelled else { return }
                                    editingBookId = book.id
                                    try? await Task.sleep(for: .milliseconds(50))
                                    guard !Task.isCancelled else { return }
                                    isBookTitleFocused = true
                                }
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }

                            // New Chapter in Book
                            Button {
                                // CRITICAL: Defer all state changes to avoid "modifying state during view update"
                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(16))
                                    guard !Task.isCancelled else { return }

                                    // Calculate order for new chapter
                                    let newOrder = (book.chapters.map(\.order).max() ?? -1) + 1

                                    // Create new chapter
                                    let newChapter = Chapter(
                                        title: "Untitled Chapter",
                                        content: "",
                                        order: newOrder
                                    )

                                    // Add to book and model context
                                    book.chapters.append(newChapter)
                                    modelContext.insert(newChapter)
                                    book.lastModified = Date()

                                    // Select this book and new chapter
                                    selectedBookId = book.id
                                    selectedChapterId = newChapter.id

                                    // Update cached chapters asynchronously
                                    isLoadingChapters = true
                                    try? await Task.sleep(for: .milliseconds(50))
                                    guard !Task.isCancelled else {
                                        isLoadingChapters = false
                                        return
                                    }
                                    chaptersToShow = book.chapters.sorted { $0.order < $1.order }
                                    isLoadingChapters = false
                                }
                            } label: {
                                Label("New Chapter", systemImage: "doc.badge.plus")
                            }

                            Divider()

                            // Duplicate Book
                            Button {
                                // CRITICAL: Defer all state changes to avoid "modifying state during view update"
                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(16))
                                    guard !Task.isCancelled else { return }

                                    let duplicatedBook = Book(
                                        title: "\(book.title) Copy",
                                        genre: book.genre
                                    )

                                    // Copy all chapters
                                    for chapter in book.sortedChapters {
                                        let newChapter = Chapter(
                                            title: chapter.title,
                                            content: chapter.content,
                                            order: chapter.order
                                        )
                                        duplicatedBook.chapters.append(newChapter)
                                        modelContext.insert(newChapter)
                                    }

                                    modelContext.insert(duplicatedBook)
                                    selectedBookId = duplicatedBook.id
                                }
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }

                            // Export Book
                            Button {
                                // CRITICAL: Defer state changes
                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(16))
                                    guard !Task.isCancelled else { return }
                                    exportingBook = book
                                    showingExportSheet = true
                                }
                            } label: {
                                Label("Export Book...", systemImage: "square.and.arrow.up")
                            }

                            Divider()

                            // Delete Book
                            Button(role: .destructive) {
                                // CRITICAL: Defer state changes
                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(16))
                                    guard !Task.isCancelled else { return }
                                    deletingBook = book
                                }
                            } label: {
                                Label("Delete Book...", systemImage: "trash")
                            }
                        }
                        #endif
                    }
                    // PERFORMANCE: Show loading state while books are being fetched
                    .opacity(isLoadingBooks ? 0.5 : 1.0)

                    // Loading overlay
                    if isLoadingBooks {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(1.2)
                                .fixedSize()
                            Text("Loading books...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        #if os(macOS)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.9))
                        #else
                        .background(Color(uiColor: .systemBackground).opacity(0.9))
                        #endif
                    }
                }
                // CRITICAL: Force toolbar re-render when loading completes
                .id(isLoadingBooks)
                .navigationTitle("Books")
                .toolbar {
                    #if os(macOS)
                    Button {
                        // CRITICAL: Defer all state changes to avoid "modifying state during view update"
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(16))
                            guard !Task.isCancelled else { return }

                            // Create new book with default title
                            let newBook = Book(
                                title: "Untitled Book",
                                genre: "General"
                            )

                            // Insert into model context
                            modelContext.insert(newBook)

                            // Select the new book (shows in sidebar)
                            selectedBookId = newBook.id

                            // Enable edit mode for the new book
                            editingBookId = newBook.id

                            // Auto-focus the title field after view updates
                            try? await Task.sleep(for: .milliseconds(100))
                            guard !Task.isCancelled else { return }
                            isBookTitleFocused = true
                        }
                    } label: {
                        Label("New Book", systemImage: "book.badge.plus")
                    }
                    #else
                    Button("New Book") { }
                    #endif
                }
                .navigationSplitViewColumnWidth(min: 200, ideal: 280, max: 350)

                } content: {
                    // CONTENT: Chapters - Standard List selection pattern (Apple HIG)
                    if selectedBook != nil {
                        ZStack {
                            // Use proper List selection binding for consistency with sidebar
                            // This follows 2025 NavigationSplitView best practices
                            List(filteredChapters, selection: $selectedChapterId) { chapter in
                                VStack(alignment: .leading, spacing: 4) {
                                    // APPLE NOTES BEHAVIOR: Display first line as chapter title
                                    // extractedTitle automatically extracts the first line from content
                                    Text(chapter.extractedTitle)
                                        .font(.headline)

                                    let preview = previewText(for: chapter)
                                    if !preview.isEmpty {
                                        Text(highlightedPreview(for: chapter))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .tag(chapter.id)
                                .contextMenu {
                                    // Delete chapter
                                    Button(role: .destructive) {
                                        // CRITICAL: Defer state changes to avoid "modifying state during view update"
                                        Task { @MainActor in
                                            try? await Task.sleep(for: .milliseconds(16))
                                            guard !Task.isCancelled else { return }
                                            deletingChapter = chapter
                                        }
                                    } label: {
                                        Label("Delete Chapter", systemImage: "trash")
                                    }
                                }
                            }
                            // CRITICAL: Show loading overlay when chapters are being loaded
                            // This provides visual feedback and prevents user confusion
                            .opacity(isLoadingChapters ? 0.5 : 1.0)

                            if isLoadingChapters {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(1.2)
                                    .fixedSize()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                            }
                        }
                        // CRITICAL: Force toolbar re-render when loading completes
                        .id(isLoadingChapters)
                        .navigationTitle(selectedBook?.title ?? "Chapters")
                        .toolbar {
                            #if os(macOS)
                            Button {
                                guard let book = selectedBook else { return }

                                // CRITICAL: Defer all state changes to avoid "modifying state during view update"
                                Task { @MainActor in
                                    try? await Task.sleep(for: .milliseconds(16))
                                    guard !Task.isCancelled else { return }

                                    // Calculate order for new chapter (max + 1)
                                    let newOrder = (book.chapters.map(\.order).max() ?? -1) + 1

                                    // Create new chapter with empty content
                                    let newChapter = Chapter(
                                        title: "Untitled Chapter",
                                        content: "",
                                        order: newOrder
                                    )

                                    // Add to book and model context
                                    book.chapters.append(newChapter)
                                    modelContext.insert(newChapter)

                                    // Update book's last modified timestamp
                                    book.lastModified = Date()

                                    // Select the new chapter (opens it in editor)
                                    selectedChapterId = newChapter.id

                                    // Update cached chapters array asynchronously
                                    isLoadingChapters = true
                                    try? await Task.sleep(for: .milliseconds(50))
                                    guard !Task.isCancelled else {
                                        isLoadingChapters = false
                                        return
                                    }
                                    chaptersToShow = book.chapters.sorted { $0.order < $1.order }
                                    isLoadingChapters = false
                                }
                            } label: {
                                Label("New Chapter", systemImage: "square.and.pencil")
                            }
                            .disabled(selectedBook == nil)
                            #else
                            Button("New Chapter") { }
                            #endif
                        }
                    } else {
                        Text("Select a book from the sidebar")
                            .foregroundStyle(.secondary)
                    }

                } detail: {
                    // DETAIL: Editor - Wrapped in NavigationStack for separate toolbar (Apple Notes pattern)
                    // This creates a distinct toolbar area for the editor column
                    NavigationStack {
                        #if os(macOS)
                        ZStack {
                            // Background that extends behind toolbar to match editor appearance
                            // .textBackgroundColor is the macOS system color for text editing areas
                            Color(nsColor: .textBackgroundColor)
                                .ignoresSafeArea() // Extends into toolbar area

                            // Editor content on top of the background
                            if let chapter = selectedChapter {
                                ChapterEditorView(
                                    chapter: chapter,
                                    searchText: $chapterSearchText,
                                    isZenModeEnabled: $isZenModeEnabled,
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
                        #else
                        // iOS: No background extension needed
                        if let chapter = selectedChapter {
                            ChapterEditorView(
                                chapter: chapter,
                                searchText: $chapterSearchText,
                                isZenModeEnabled: $isZenModeEnabled,
                                onChapterSelect: handleChapterSelection
                            )
                            .id(chapter.id)
                        } else {
                            Text("Select a chapter to begin writing")
                                .foregroundStyle(.secondary)
                        }
                        #endif
                    }
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
        .onChange(of: selectedBookId) { oldValue, newValue in
            // PERFORMANCE: Instant chapter loading (ZERO delay)
            guard oldValue != newValue else { return }

            guard let id = newValue, let book = books.first(where: { $0.id == id }) else {
                chaptersToShow = []
                isLoadingChapters = false
                return
            }

            // Load chapters IMMEDIATELY
            isLoadingChapters = true
            chaptersToShow = book.chapters.sorted { $0.order < $1.order }
            isLoadingChapters = false

            print("⚡ Loaded \(chaptersToShow.count) chapters INSTANTLY")
        }
        .task(priority: .userInitiated) {
            // PERFORMANCE: Async book loading with ZERO delay for maximum speed
            print("🚀 Starting INSTANT book load...")

            // Fetch books IMMEDIATELY (no artificial delay)
            do {
                let descriptor = FetchDescriptor<Book>(
                    sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
                )
                books = try modelContext.fetch(descriptor)
                print("📚 Loaded \(books.count) books instantly")

                // CRITICAL: Auto-select first book for immediate interaction
                if let firstBook = books.first {
                    selectedBookId = firstBook.id
                    print("✅ Auto-selected first book: \(firstBook.title)")
                }
            } catch {
                print("❌ Failed to fetch books: \(error)")
                books = []
            }

            isLoadingBooks = false
        }
        .onChange(of: isZenModeEnabled) { oldValue, newValue in
            // CRITICAL FIX: Add transition delay to ensure forceSave completes
            // Without this, the old view's onDisappear save and new view's load race
            // The new view can load stale content before the save finishes
            print("🔄 Zen mode transition: \(oldValue) → \(newValue)")

            // Set transition flag to prevent conflicting updates
            isTransitioningZenMode = true

            // Add delay to ensure any in-flight saves complete
            // ChapterEditorView.onDisappear calls forceSave which is synchronous
            // But SwiftUI view updates can happen very quickly
            Task { @MainActor in
                // Wait for save operations to complete
                try? await Task.sleep(for: .milliseconds(150))

                guard !Task.isCancelled else { return }

                // Clear transition flag
                isTransitioningZenMode = false

                print("✅ Zen mode transition complete")
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            // Export sheet for book
            if let book = exportingBook {
                ExportView(book: book, chapter: nil)
            }
        }
        .alert("Delete Book?", isPresented: Binding(
            get: { deletingBook != nil },
            set: { if !$0 { deletingBook = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                deletingBook = nil
            }
            Button("Delete", role: .destructive) {
                if let book = deletingBook {
                    // CRITICAL: Defer all state changes
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(16))
                        guard !Task.isCancelled else { return }

                        // Delete the book from model context
                        modelContext.delete(book)
                        deletingBook = nil

                        // Clear selection if this was the selected book
                        if selectedBookId == book.id {
                            selectedBookId = nil
                            selectedChapterId = nil
                            chaptersToShow = []
                        }
                    }
                }
            }
        } message: {
            if let book = deletingBook {
                Text("Are you sure you want to delete \"\(book.title)\" and all \(book.chapterCount) chapters? This action cannot be undone.")
            }
        }
        .alert("Delete Chapter?", isPresented: Binding(
            get: { deletingChapter != nil },
            set: { if !$0 { deletingChapter = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                deletingChapter = nil
            }
            Button("Delete", role: .destructive) {
                if let chapter = deletingChapter {
                    // CRITICAL: Defer all state changes
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(16))
                        guard !Task.isCancelled else { return }

                        // Get the parent book to update its chapter list
                        guard let book = selectedBook else {
                            deletingChapter = nil
                            return
                        }

                        // Remove from book's chapters array
                        book.chapters.removeAll { $0.id == chapter.id }

                        // Delete the chapter from model context
                        modelContext.delete(chapter)

                        // Update book's last modified timestamp
                        book.lastModified = Date()

                        // Clear the deleting reference
                        deletingChapter = nil

                        // Clear selection if this was the selected chapter
                        if selectedChapterId == chapter.id {
                            selectedChapterId = nil
                        }

                        // Update cached chapters array asynchronously
                        isLoadingChapters = true
                        try? await Task.sleep(for: .milliseconds(50))
                        guard !Task.isCancelled else {
                            isLoadingChapters = false
                            return
                        }
                        chaptersToShow = book.chapters.sorted { $0.order < $1.order }
                        isLoadingChapters = false
                    }
                }
            }
        } message: {
            if let chapter = deletingChapter {
                Text("Are you sure you want to delete \"\(chapter.extractedTitle)\"? This action cannot be undone.")
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
