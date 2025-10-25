//
//  BookListView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// Sidebar view displaying all books
///
/// BookListView shows the collection of books in a list format,
/// mirroring the folder list in Apple Notes. Users can create,
/// rename, delete, and select books from this view.
struct BookListView: View {
    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// Array of all books
    let books: [Book]

    /// Currently selected book (two-way binding)
    @Binding var selection: Book?

    /// View model for book operations
    @State private var viewModel: BookViewModel?

    /// Controls display of new book sheet
    @State private var showingNewBookSheet = false

    /// Controls display of rename alert
    @State private var showingRenameAlert = false

    /// Book being renamed
    @State private var bookToRename: Book?

    /// Text field content for new book title
    @State private var newBookTitle = ""

    /// Text field content for new book genre
    @State private var newBookGenre = "General"

    /// Search text for filtering books
    @State private var searchText = ""

    /// Book to export
    @State private var bookToExport: Book?

    /// Show export sheet
    @State private var showingExportSheet = false

    var body: some View {
        List(selection: $selection) {
            ForEach(filteredBooks) { book in
                BookRowView(book: book)
                    .tag(book)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteBook(book)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            bookToRename = book
                            newBookTitle = book.title
                            newBookGenre = book.genre
                            showingRenameAlert = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Button {
                            duplicateBook(book)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

                        Button {
                            bookToExport = book
                            showingExportSheet = true
                        } label: {
                            Label("Export Book", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive) {
                            deleteBook(book)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle("Books")
        .searchable(text: $searchText, prompt: "Search Books")
        .toolbar {
            #if os(iOS)
            // Top toolbar: New Book button first, then Edit button
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewBookSheet = true
                } label: {
                    Label("New Book", systemImage: "square.and.pencil")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    // Edit mode will be handled by NavigationStack
                }
            }

            // Bottom toolbar: Search bar
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            #else
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewBookSheet = true
                } label: {
                    Label("New Book", systemImage: "plus")
                }
            }
            #endif
        }
        .sheet(isPresented: $showingNewBookSheet) {
            NewBookSheet(
                title: $newBookTitle,
                genre: $newBookGenre,
                onSave: {
                    createBook()
                },
                onCancel: {
                    showingNewBookSheet = false
                    resetNewBookFields()
                }
            )
        }
        .alert("Rename Book", isPresented: $showingRenameAlert) {
            TextField("Title", text: $newBookTitle)
            TextField("Genre", text: $newBookGenre)

            Button("Cancel", role: .cancel) {
                resetNewBookFields()
            }

            Button("Rename") {
                renameBook()
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            if let book = bookToExport {
                ExportView(book: book)
            }
        }
        .overlay {
            if books.isEmpty {
                ContentUnavailableView {
                    Label("No Books", systemImage: "book.closed")
                } description: {
                    Text("Create your first book to start writing")
                } actions: {
                    Button("New Book") {
                        showingNewBookSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = BookViewModel(modelContext: modelContext)
            }
        }
    }

    // MARK: - Computed Properties

    /// Filtered books based on search text
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.genre.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Actions

    /// Create a new book
    private func createBook() {
        guard !newBookTitle.isEmpty else { return }

        let book = viewModel?.createBook(title: newBookTitle, genre: newBookGenre)
        selection = book

        showingNewBookSheet = false
        resetNewBookFields()
    }

    /// Rename the selected book
    private func renameBook() {
        guard let book = bookToRename, !newBookTitle.isEmpty else { return }

        viewModel?.updateBook(book, title: newBookTitle, genre: newBookGenre)
        resetNewBookFields()
    }

    /// Delete a book
    private func deleteBook(_ book: Book) {
        // Clear selection if deleting the selected book
        if selection?.id == book.id {
            selection = nil
        }

        viewModel?.deleteBook(book)
    }

    /// Duplicate a book
    private func duplicateBook(_ book: Book) {
        let newBook = viewModel?.duplicateBook(book)
        selection = newBook
    }

    /// Reset the new book form fields
    private func resetNewBookFields() {
        newBookTitle = ""
        newBookGenre = "General"
        bookToRename = nil
    }
}

// MARK: - Book Row View

/// Individual row view for a book in the list
struct BookRowView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(book.genre)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text("\(book.chapterCount) chapters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(book.lastModified.simpleFormatted)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if book.totalWordCount > 0 {
                        Text("\(book.totalWordCount.formatted()) words")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
//        .padding(.vertical, 4)
    }
}

// MARK: - New Book Sheet

/// Sheet for creating a new book
struct NewBookSheet: View {
    @Binding var title: String
    @Binding var genre: String

    let onSave: () -> Void
    let onCancel: () -> Void

    @FocusState private var isTitleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Book Details") {
                    TextField("Title", text: $title)
                        .focused($isTitleFocused)

                    TextField("Genre", text: $genre)
                }

                Section {
                    Text("Create a new book to organize your chapters and manuscript.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Book")
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

// MARK: - Previews
#Preview("With Books") {
    NavigationSplitView {
        BookListView(
            books: [
                Book(title: "My Novel", genre: "Fiction"),
                Book(title: "Memoir", genre: "Non-Fiction"),
                Book(title: "Poetry Collection", genre: "Poetry")
            ],
            selection: .constant(nil)
        )
    } detail: {
        Text("Detail")
    }
    .modelContainer(DataStore.preview().modelContainer)
}

#Preview("Empty State") {
    NavigationSplitView {
        BookListView(
            books: [],
            selection: .constant(nil)
        )
    } detail: {
        Text("Detail")
    }
    .modelContainer(DataStore(inMemory: true).modelContainer)
}
