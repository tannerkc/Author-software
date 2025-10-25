//
//  NoteListView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// List view displaying all notes for a book
struct NoteListView: View {
    let book: Book
    let viewModel: MaterialViewModel

    @State private var searchText = ""
    @State private var selectedNote: Note?
    @State private var showingEditor = false

    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return book.sortedNotes
        } else {
            return book.sortedNotes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        Group {
            if book.notes.isEmpty {
                MaterialEmptyStateView(
                    icon: "note.text",
                    title: "No Notes",
                    message: "Notes are for brainstorming, character development, and story ideas. Tap the + button to create your first note."
                )
            } else {
                List {
                    ForEach(filteredNotes) { note in
                        NoteRow(note: note)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedNote = note
                                showingEditor = true
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    viewModel.toggleNotePinned(note)
                                } label: {
                                    Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteNote(note)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    _ = viewModel.duplicateNote(note)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    viewModel.toggleNotePinned(note)
                                } label: {
                                    Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
                                }

                                Button {
                                    _ = viewModel.duplicateNote(note)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }

                                Button(role: .destructive) {
                                    viewModel.deleteNote(note)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .searchable(text: $searchText, prompt: "Search notes")
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteEditorView(note: note, viewModel: viewModel)
        }
    }
}

// MARK: - Note Row

struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Text(note.extractedTitle)
                    .font(.headline)

                Spacer()

                Label(note.category.rawValue, systemImage: note.category.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !note.contentPreview.isEmpty {
                Text(note.contentPreview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Tags
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            HStack {
                Text(note.lastModified.smartFormatted)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text("\(note.wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NoteListView(
            book: {
                let book = Book(title: "Sample Book")
                let note = Note(
                    title: "Character Ideas",
                    content: "Need to develop the antagonist's backstory...",
                    category: .character,
                    tags: ["brainstorm", "antagonist"],
                    isPinned: true
                )
                note.book = book
                book.notes = [note]
                return book
            }(),
            viewModel: MaterialViewModel(modelContext: ModelContext(
                try! ModelContainer(for: Book.self, Note.self)
            ))
        )
    }
}
