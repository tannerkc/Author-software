//
//  ChapterEditorView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// Detail pane view for editing chapter content
///
/// ChapterEditorView provides a distraction-free writing environment with
/// real-time word/character counts, auto-save, and a clean interface
/// inspired by Apple Notes.
struct ChapterEditorView: View {
    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// The chapter being edited
    let chapter: Chapter

    /// View model for chapter operations
    @State private var viewModel: ChapterViewModel?

    /// Local state for the text editor (bound to chapter content)
    @State private var editorText: String = ""

    /// Controls title editing mode
    @State private var isEditingTitle = false

    /// Title text field content
    @State private var titleText: String = ""

    /// Focus state for the editor
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Title Bar
            titleBar

            Divider()

            // MARK: - Text Editor
            TextEditor(text: $editorText)
                .font(.system(size: 16, design: .default))
                .lineSpacing(6)
                .padding()
                .focused($isEditorFocused)
                .onChange(of: editorText) { _, newValue in
                    viewModel?.updateChapterContent(chapter, content: newValue)
                }
                .scrollContentBackground(.hidden)
                #if os(macOS)
                .background(Color(nsColor: .textBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif

            Divider()

            // MARK: - Status Bar
            statusBar
        }
        .navigationTitle(chapter.title)
        .onAppear {
            if viewModel == nil {
                viewModel = ChapterViewModel(modelContext: modelContext)
            }
            editorText = chapter.content
            titleText = chapter.title
            isEditorFocused = true
        }
        .toolbar {
            #if os(macOS)
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel?.saveChapter(chapter)
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            #endif
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            if isEditingTitle {
                TextField("Chapter Title", text: $titleText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        saveTitle()
                    }

                Button {
                    saveTitle()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Button {
                    titleText = chapter.title
                    isEditingTitle = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let book = chapter.book {
                        Text(book.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    isEditingTitle = true
                    titleText = chapter.title
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            // Word count
            Label("\(chapter.wordCount) words", systemImage: "doc.text")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()
                .frame(height: 12)

            // Character count
            Label("\(chapter.characterCount) characters", systemImage: "textformat.abc")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Last saved indicator
            if let lastSaveTime = viewModel?.lastSaveTime {
                Label(
                    "Saved \(lastSaveTime, style: .relative)",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.green)
            } else {
                #if os(macOS)
                Label("Auto-save enabled", systemImage: "icloud")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #endif
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(.systemGroupedBackground))
        #endif
    }

    // MARK: - Actions

    private func saveTitle() {
        guard !titleText.trimmingCharacters(in: .whitespaces).isEmpty else {
            titleText = chapter.title
            isEditingTitle = false
            return
        }

        viewModel?.updateChapterTitle(chapter, title: titleText)
        isEditingTitle = false
    }
}

// MARK: - Previews
#Preview("With Content") {
    let store = DataStore.preview()

    if let book = try? store.fetchBooks().first,
       let chapter = book.chapters.first {
        ChapterEditorView(chapter: chapter)
            .modelContainer(store.modelContainer)
    }
}

#Preview("Empty Chapter") {
    let chapter = Chapter(title: "Untitled Chapter", content: "")

    ChapterEditorView(chapter: chapter)
        .modelContainer(DataStore(inMemory: true).modelContainer)
}
