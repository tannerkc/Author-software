//
//  ChapterListView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// Middle column view displaying chapters for the selected book
///
/// ChapterListView shows all chapters belonging to a book, with support
/// for drag-and-drop reordering, creation, deletion, and selection.
struct ChapterListView: View {
    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// Edit mode for the list
    @Environment(\.editMode) private var editMode

    /// The book whose chapters are being displayed
    let book: Book

    /// Currently selected chapter ID (UUID-based for stable macOS selection)
    @Binding var selection: UUID?

    /// View model for chapter operations
    @State private var viewModel: ChapterViewModel?

    /// Controls display of new chapter sheet
    @State private var showingNewChapterSheet = false

    /// Controls display of rename alert
    @State private var showingRenameAlert = false

    /// Chapter being renamed
    @State private var chapterToRename: Chapter?

    /// Text field content for new/renamed chapter title
    @State private var chapterTitle = ""

    /// Search text for filtering chapters
    @State private var searchText = ""

    /// Show export sheet
    @State private var showingExportSheet = false

    /// Show materials view
    @State private var showingMaterials = false

    /// Controls banner animation on appear
    @State private var showMaterialsBanner = false

    /// Task for animating banner (can be cancelled to prevent memory issues)
    @State private var bannerAnimationTask: Task<Void, Never>?

    // MARK: - Metadata Filters

    /// Filter by POV character
    @State private var filterPOV: String? = nil

    /// Filter by completion status (nil = all, true = completed, false = incomplete)
    @State private var filterCompleted: Bool? = nil

    /// Filter by chapter type
    @State private var filterType: ChapterType? = nil

    var body: some View {
        List(selection: $selection) {
            ForEach(filteredChapters) { chapter in
                chapterListRow(for: chapter)
            }
            #if os(iOS)
            // Only enable drag-to-reorder on iOS
            // macOS: .onMove gesture recognizer blocks List selection (documented SwiftUI bug)
            .onMove { source, destination in
                reorderChapters(from: source, to: destination)
            }
            #endif
        }
        #if os(macOS)
        .listStyle(.inset)  // Inset style appropriate for content column selection on macOS
        #endif
        #if os(iOS)
        .scrollContentBackground(.hidden) // iOS 26: Enable Liquid Glass transparency
        #endif
        .searchable(text: $searchText, prompt: "Search Chapters")
        .navigationTitle(book.title)
        .toolbar {
            #if os(iOS)
            // Top toolbar: Share, Filter, and ellipsis menu on right
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: book.title) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }

            // Filter menu
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingNewChapterSheet = true
                    } label: {
                        Label("New Chapter", systemImage: "doc.badge.plus")
                    }

                    Button {
                        withAnimation {
                            if editMode?.wrappedValue == .active {
                                editMode?.wrappedValue = .inactive
                            } else {
                                editMode?.wrappedValue = .active
                            }
                        }
                    } label: {
                        Label(editMode?.wrappedValue == .active ? "Done" : "Edit", systemImage: "arrow.up.and.down")
                    }

                    Divider()

                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export Book", systemImage: "square.and.arrow.up.on.square")
                    }

                    Divider()

                    Button(role: .destructive) {
                        // Delete book action
                    } label: {
                        Label("Delete Book", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }

            // Bottom toolbar: Native search field and compose button
            DefaultToolbarItem(kind: .search, placement: .bottomBar)

            ToolbarSpacer(.flexible, placement: .bottomBar)

            ToolbarItem(placement: .bottomBar) {
                Button {
                    showingNewChapterSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                }
            }
            #else
            // macOS toolbar
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewChapterSheet = true
                } label: {
                    Label("New Chapter", systemImage: "plus")
                }
            }

            // Filter menu (macOS)
            ToolbarItem(placement: .secondaryAction) {
                filterMenu
            }

            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Button {
                        showingNewChapterSheet = true
                    } label: {
                        Label("New Chapter", systemImage: "doc.badge.plus")
                    }

                    Divider()

                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export Book", systemImage: "square.and.arrow.up.on.square")
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis")
                }
            }
            #endif
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            #if os(iOS)
            if showMaterialsBanner {
                MaterialsBanner(book: book)
                    .onTapGesture {
                        showingMaterials = true
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            #endif
        }
        .sheet(isPresented: $showingNewChapterSheet) {
            NewChapterSheet(
                title: $chapterTitle,
                onSave: {
                    createChapter()
                },
                onCancel: {
                    showingNewChapterSheet = false
                    chapterTitle = ""
                }
            )
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(book: book)
        }
        .sheet(isPresented: $showingMaterials) {
            // TODO: Add MaterialsView and related files to Xcode project
            // MaterialsView(book: book)
            Text("Materials view coming soon")
        }
        .alert("Rename Chapter", isPresented: $showingRenameAlert) {
            TextField("Title", text: $chapterTitle)

            Button("Cancel", role: .cancel) {
                chapterTitle = ""
                chapterToRename = nil
            }

            Button("Rename") {
                renameChapter()
            }
        }
        .overlay {
            if book.chapters.isEmpty {
                ContentUnavailableView {
                    Label("No Chapters", systemImage: "doc.text")
                } description: {
                    Text("Add your first chapter to start writing")
                } actions: {
                    Button("New Chapter") {
                        showingNewChapterSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ChapterViewModel(modelContext: modelContext)
            }

            // Animate banner in with delay (using Task for proper cleanup)
            bannerAnimationTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }

                withAnimation(.spring()) {
                    showMaterialsBanner = true
                }
            }
        }
        .onDisappear {
            // Cancel any pending banner animation to prevent crash on deallocated view
            bannerAnimationTask?.cancel()
            bannerAnimationTask = nil
        }
    }

    // MARK: - Computed Properties

    /// Sorted and filtered chapters (applies both search and metadata filters)
    private var filteredChapters: [Chapter] {
        var chapters = book.sortedChapters

        // Apply search filter
        if !searchText.isEmpty {
            chapters = chapters.filter { chapter in
                chapter.title.localizedCaseInsensitiveContains(searchText) ||
                chapter.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply POV filter
        if let povFilter = filterPOV {
            chapters = chapters.filter { chapter in
                chapter.metadata?.povCharacter == povFilter
            }
        }

        // Apply completion status filter
        if let completedFilter = filterCompleted {
            chapters = chapters.filter { chapter in
                chapter.metadata?.isCompleted == completedFilter
            }
        }

        // Apply chapter type filter
        if let typeFilter = filterType {
            chapters = chapters.filter { chapter in
                chapter.metadata?.chapterType == typeFilter
            }
        }

        return chapters
    }

    /// Unique POV characters from all chapters with metadata
    private var uniquePOVCharacters: [String] {
        let allPOVs = book.chapters.compactMap { $0.metadata?.povCharacter }.filter { !$0.isEmpty }
        return Array(Set(allPOVs)).sorted()
    }

    /// Number of active filters
    private var activeFilterCount: Int {
        var count = 0
        if filterPOV != nil { count += 1 }
        if filterCompleted != nil { count += 1 }
        if filterType != nil { count += 1 }
        return count
    }

    // MARK: - Actions

    /// Create a new chapter
    private func createChapter() {
        guard !chapterTitle.isEmpty else { return }

        let chapter = viewModel?.createChapter(
            in: book,
            title: chapterTitle
        )
        selection = chapter?.id

        showingNewChapterSheet = false
        chapterTitle = ""
    }

    /// Rename a chapter
    private func renameChapter() {
        guard let chapter = chapterToRename, !chapterTitle.isEmpty else { return }

        viewModel?.updateChapterTitle(chapter, title: chapterTitle)

        chapterTitle = ""
        chapterToRename = nil
    }

    /// Delete a chapter
    private func deleteChapter(_ chapter: Chapter) {
        // Clear selection if deleting the selected chapter
        if selection == chapter.id {
            selection = nil
        }

        viewModel?.deleteChapter(chapter)
    }

    /// Duplicate a chapter
    private func duplicateChapter(_ chapter: Chapter) {
        let newChapter = viewModel?.duplicateChapter(chapter)
        selection = newChapter?.id
    }

    /// Reorder chapters
    private func reorderChapters(from source: IndexSet, to destination: Int) {
        viewModel?.reorderChapters(in: book, from: source, to: destination)
    }

    /// Clear all active filters
    private func clearFilters() {
        filterPOV = nil
        filterCompleted = nil
        filterType = nil
    }

    // MARK: - Filter Menu

    /// Filter menu for metadata-based filtering
    private var filterMenu: some View {
        Menu {
            povFilterSection
            statusFilterSection
            chapterTypeFilterSection
            clearFiltersSection
        } label: {
            Label(
                "Filter",
                systemImage: activeFilterCount > 0 ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease"
            )
        }
        .badge(activeFilterCount > 0 ? activeFilterCount : 0)
    }

    @ViewBuilder
    private var povFilterSection: some View {
        if !uniquePOVCharacters.isEmpty {
            Section("POV Character") {
                ForEach(uniquePOVCharacters, id: \.self) { pov in
                    Button {
                        filterPOV = (filterPOV == pov) ? nil : pov
                    } label: {
                        Label(pov, systemImage: filterPOV == pov ? "checkmark" : "person.circle")
                    }
                }
            }
        }
    }

    private var statusFilterSection: some View {
        Section("Status") {
            Button {
                filterCompleted = (filterCompleted == true) ? nil : true
            } label: {
                Label("Completed", systemImage: filterCompleted == true ? "checkmark" : "checkmark.circle")
            }

            Button {
                filterCompleted = (filterCompleted == false) ? nil : false
            } label: {
                Label("Incomplete", systemImage: filterCompleted == false ? "checkmark" : "circle")
            }
        }
    }

    private var chapterTypeFilterSection: some View {
        Section("Chapter Type") {
            ForEach(ChapterType.allCases) { type in
                Button {
                    filterType = (filterType == type) ? nil : type
                } label: {
                    Label(type.rawValue, systemImage: filterType == type ? "checkmark" : type.icon)
                }
            }
        }
    }

    @ViewBuilder
    private var clearFiltersSection: some View {
        if activeFilterCount > 0 {
            Section {
                Button(role: .destructive) {
                    clearFilters()
                } label: {
                    Label("Clear All Filters", systemImage: "xmark.circle")
                }
            }
        }
    }

    // MARK: - View Builders

    /// Creates a chapter list row with platform-specific navigation
    @ViewBuilder
    private func chapterListRow(for chapter: Chapter) -> some View {
        // macOS NavigationSplitView uses plain rows with .tag(), NOT NavigationLink
        // NavigationLink is for iOS navigation stacks
        ChapterRowView(chapter: chapter, searchText: searchText.isEmpty ? nil : searchText)
            .tag(chapter.id)  // Selection binding pattern for macOS
            .id(chapter.id)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteChapter(chapter)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                chapterToRename = chapter
                chapterTitle = chapter.title
                showingRenameAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button {
                duplicateChapter(chapter)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                deleteChapter(chapter)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Chapter Row View

/// Individual row view for a chapter in the list
struct ChapterRowView: View {
    let chapter: Chapter
    var searchText: String? = nil

    /// Get the appropriate preview text based on whether search is active
    private var previewText: String {
        if let search = searchText, !search.isEmpty {
            return chapter.contextualPreview(for: search)
        } else {
            return chapter.contentPreview
        }
    }

    /// Create highlighted attributed string for preview text
    private func highlightedPreview() -> AttributedString {
        let preview = previewText
        var attributedString = AttributedString(preview)

        // Only highlight if we have search text
        guard let search = searchText, !search.isEmpty else {
            return attributedString
        }

        // Find and highlight all occurrences of search text (case-insensitive)
        let lowercasedPreview = preview.lowercased()
        let lowercasedSearch = search.lowercased()

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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: chapter.isEmpty ? "doc" : "doc.text.fill")
                    .foregroundStyle(chapter.isEmpty ? .secondary : .primary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.extractedTitle)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if !previewText.isEmpty {
                        Text(highlightedPreview())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Empty chapter")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .italic()
                    }

                    // Metadata badges
                    if let metadata = chapter.metadata {
                        metadataBadges(for: metadata)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if chapter.wordCount > 0 {
                        Text("\(chapter.wordCount) words")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(chapter.lastModified.simpleFormatted)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)  // Fill width for full clickable area
        .padding(.vertical, 4)
        .contentShape(Rectangle())  // Make entire row clickable including empty space
    }

    // MARK: - Metadata Badges

    /// Display metadata badges for POV, type, status, and tags
    @ViewBuilder
    private func metadataBadges(for metadata: ChapterMetadata) -> some View {
        HStack(spacing: 6) {
            // POV character badge
            if !metadata.povCharacter.isEmpty {
                Label(metadata.povCharacter, systemImage: "person.circle")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Chapter type badge (only if not standard)
            if metadata.chapterType != .standard {
                Label(metadata.chapterType.rawValue, systemImage: metadata.chapterType.icon)
                    .font(.caption2)
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.purple.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Completion status badge
            if metadata.isCompleted {
                Label("Complete", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.1))
                    .clipShape(Capsule())
            } else if metadata.needsRevision {
                Label("Revision", systemImage: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Tags (show first 3)
            if !metadata.tags.isEmpty {
                ForEach(metadata.tags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }

                // Show "+N more" if there are additional tags
                if metadata.tags.count > 3 {
                    Text("+\(metadata.tags.count - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tertiary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - New Chapter Sheet

/// Sheet for creating a new chapter
struct NewChapterSheet: View {
    @Binding var title: String

    let onSave: () -> Void
    let onCancel: () -> Void

    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Chapter Details") {
                    TextField("Title", text: $title)
                        .focused($isTitleFocused)
                }

                Section {
                    Text("Create a new chapter for your manuscript.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Chapter")
            #if os(iOS)
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onSave()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
}

// MARK: - Materials Banner

/// Banner view for accessing book materials
struct MaterialsBanner: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("Materials")
                    .font(.footnote)

                HStack(spacing: 12) {
                    if book.sceneCount > 0 {
                        Label("\(book.sceneCount)", systemImage: "film")
                            .font(.caption2)
                    }
                    if book.noteCount > 0 {
                        Label("\(book.noteCount)", systemImage: "note.text")
                            .font(.caption2)
                    }
                    if book.researchItemCount > 0 {
                        Label("\(book.researchItemCount)", systemImage: "book")
                            .font(.caption2)
                    }
                    if book.characterCount > 0 {
                        Label("\(book.characterCount)", systemImage: "person.2")
                            .font(.caption2)
                    }
                    
                    if [book.sceneCount, book.noteCount, book.researchItemCount, book.characterCount].allSatisfy({ $0 == 0 }) {
                        Text("No materials yet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
        .padding(.horizontal, 28)
        .padding(.bottom, 5)
    }
}

// MARK: - Previews
#Preview("With Chapters") {
    let store = DataStore.preview()

    NavigationSplitView {
        Text("Sidebar")
    } content: {
        if let book = try? store.fetchBooks().first {
            ChapterListView(
                book: book,
                selection: .constant(nil)
            )
        }
    } detail: {
        Text("Detail")
    }
    .modelContainer(store.modelContainer)
}

#Preview("Empty State") {
    let emptyBook = Book(title: "Empty Book")

    NavigationSplitView {
        Text("Sidebar")
    } content: {
        ChapterListView(
            book: emptyBook,
            selection: .constant(nil)
        )
    } detail: {
        Text("Detail")
    }
    .modelContainer(DataStore(inMemory: true).modelContainer)
}
