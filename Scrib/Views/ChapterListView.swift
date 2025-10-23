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

    /// The book whose chapters are being displayed
    let book: Book

    /// Currently selected chapter (two-way binding)
    @Binding var selection: Chapter?

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

    var body: some View {
        List(selection: $selection) {
            ForEach(filteredChapters) { chapter in
                ChapterRowView(chapter: chapter)
                    .tag(chapter)
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
            .onMove { source, destination in
                reorderChapters(from: source, to: destination)
            }
        }
        .navigationTitle(book.title)
        .searchable(text: $searchText, prompt: "Search chapters")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewChapterSheet = true
                } label: {
                    Label("New Chapter", systemImage: "plus")
                }
            }

            #if os(iOS)
            ToolbarItem(placement: .secondaryAction) {
                EditButton()
            }
            #endif

            #if os(macOS)
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Button {
                        showingNewChapterSheet = true
                    } label: {
                        Label("New Chapter", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
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
        }
    }

    // MARK: - Computed Properties

    /// Sorted and filtered chapters
    private var filteredChapters: [Chapter] {
        let sorted = book.sortedChapters

        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { chapter in
                chapter.title.localizedCaseInsensitiveContains(searchText) ||
                chapter.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Actions

    /// Create a new chapter
    private func createChapter() {
        guard !chapterTitle.isEmpty else { return }

        let chapter = viewModel?.createChapter(
            in: book,
            title: chapterTitle
        )
        selection = chapter

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
        if selection?.id == chapter.id {
            selection = nil
        }

        viewModel?.deleteChapter(chapter)
    }

    /// Duplicate a chapter
    private func duplicateChapter(_ chapter: Chapter) {
        let newChapter = viewModel?.duplicateChapter(chapter)
        selection = newChapter
    }

    /// Reorder chapters
    private func reorderChapters(from source: IndexSet, to destination: Int) {
        viewModel?.reorderChapters(in: book, from: source, to: destination)
    }
}

// MARK: - Chapter Row View

/// Individual row view for a chapter in the list
struct ChapterRowView: View {
    let chapter: Chapter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: chapter.isEmpty ? "doc" : "doc.text.fill")
                    .foregroundStyle(chapter.isEmpty ? .secondary : .primary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if !chapter.isEmpty {
                        Text(chapter.contentPreview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("Empty chapter")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if chapter.wordCount > 0 {
                        Text("\(chapter.wordCount) words")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(chapter.lastModified, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
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
            .navigationBarTitleDisplayMode(.inline)
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
