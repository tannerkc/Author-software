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

    /// Focus state for the editor
    @FocusState private var isEditorFocused: Bool

    /// Selected text range for toolbar context awareness
    @State private var selectedRange: Range<String.Index>?

    /// Sheet presentation states
    @State private var showingCharacterMarker = false
    @State private var showingInlineNote = false
    @State private var showingMetadata = false

    /// Format toolbar visibility (replaces keyboard when true)
    @State private var showingFormatToolbar = false

    /// Chapter metadata
    @State private var chapterMetadata = ChapterMetadata()

    /// Text formatting state
    @State private var currentTextStyle: TextStyle = .body

    /// Simulated selected text for sheets (will be enhanced with actual selection)
    @State private var currentSelection = ""

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Free-form Text Editor (Apple Notes style)
            // First line becomes the title, everything else is body content
            TextEditor(text: $editorText)
                .font(.system(size: 17, design: .default))
                .lineSpacing(4)
                .padding(.horizontal, 20)
                .padding(.top, 12)
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

            // MARK: - Adaptive Keyboard Toolbar or Format Toolbar
            #if os(iOS)
            if showingFormatToolbar {
                FormatToolbar(
                    selectedStyle: $currentTextStyle,
                    onApplyFormat: handleTextFormat,
                    onDismiss: {
                        showingFormatToolbar = false
                        isEditorFocused = true
                    }
                )
            } else {
                AdaptiveKeyboardToolbar(
                    selectedRange: $selectedRange,
                    content: $editorText,
                    wordCount: chapter.wordCount,
                    onFormatAction: handleFormatAction
                )
            }
            #endif
        }
        .navigationTitle("")  // No navigation title - content speaks for itself
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = ChapterViewModel(modelContext: modelContext)
            }
            editorText = chapter.content
            // Auto-focus for immediate typing
            Task {
                try? await Task.sleep(for: .milliseconds(100))
                isEditorFocused = true
            }
        }
        .sheet(isPresented: $showingCharacterMarker) {
            CharacterMarkerSheet(selectedText: currentSelection) { marker in
                print("Marked character: \(marker.name)")
                // TODO: Save character marker to chapter
            }
        }
        .sheet(isPresented: $showingInlineNote) {
            InlineNoteSheet(selectedText: currentSelection) { note in
                print("Created note: \(note.content)")
                // TODO: Save inline note to chapter
            }
        }
        .sheet(isPresented: $showingMetadata) {
            ChapterMetadataSheet(metadata: $chapterMetadata) {
                print("Saved metadata")
                // TODO: Persist chapter metadata
            }
        }
        .toolbar {
            #if os(iOS)
            // Top right: Share and ellipsis menu
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: chapter.content, subject: Text(chapter.extractedTitle)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        // Export chapter
                    } label: {
                        Label("Export Chapter", systemImage: "square.and.arrow.up.on.square")
                    }

                    Button {
                        // Chapter info/metadata
                    } label: {
                        Label("Chapter Info", systemImage: "info.circle")
                    }

                    Divider()

                    Button {
                        viewModel?.saveChapter(chapter)
                    } label: {
                        Label("Save Now", systemImage: "arrow.down.doc")
                    }

                    Divider()

                    Button(role: .destructive) {
                        // Delete chapter
                    } label: {
                        Label("Delete Chapter", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
            #else
            // macOS toolbar
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

    // MARK: - Format Actions

    /// Handle formatting actions from the keyboard toolbar
    /// - Parameter action: The formatting action to perform
    private func handleFormatAction(_ action: AdaptiveKeyboardToolbar.FormatAction) {
        switch action {
        case .showFormatMenu:
            showingFormatToolbar = true
            isEditorFocused = false
        case .bold:
            applyMarkdown(prefix: "**", suffix: "**")
        case .italic:
            applyMarkdown(prefix: "*", suffix: "*")
        case .underline:
            applyMarkdown(prefix: "<u>", suffix: "</u>")
        case .strikethrough:
            applyMarkdown(prefix: "~~", suffix: "~~")
        case .highlight(let color):
            applyMarkdown(prefix: "==", suffix: "==")
        case .bulletList:
            insertAtLineStart("- ")
        case .numberedList:
            insertAtLineStart("1. ")
        case .checklist:
            insertAtLineStart("- [ ] ")
        case .quote:
            insertAtLineStart("> ")
        case .link:
            applyMarkdown(prefix: "[", suffix: "](url)")
        case .markCharacter:
            currentSelection = "Selected text"  // Will be enhanced with actual selection
            showingCharacterMarker = true
        case .addNote:
            currentSelection = "Selected text"
            showingInlineNote = true
        case .setMetadata:
            showingMetadata = true
        case .markScene:
            // Quick-set scene location
            chapterMetadata.sceneLocation = "Scene"
            showingMetadata = true
        case .markPOV:
            // Quick-set POV
            showingMetadata = true
        default:
            print("Format action not yet implemented: \(action)")
        }
    }

    /// Apply markdown formatting around selected text
    private func applyMarkdown(prefix: String, suffix: String) {
        // Simple implementation - will be enhanced with proper selection handling
        editorText += "\(prefix)text\(suffix)"
    }

    /// Insert text at the start of the current line
    private func insertAtLineStart(_ text: String) {
        // Simple implementation - will be enhanced with proper cursor positioning
        editorText += "\n\(text)"
    }

    /// Handle text formatting from the format menu
    /// - Parameter format: The text format to apply
    private func handleTextFormat(_ format: TextFormat) {
        switch format {
        case .style(let style):
            currentTextStyle = style
            // TODO: Apply text style to selected text or current paragraph
            print("Applied text style: \(style)")
        case .bold:
            applyMarkdown(prefix: "**", suffix: "**")
        case .italic:
            applyMarkdown(prefix: "*", suffix: "*")
        case .underline:
            applyMarkdown(prefix: "<u>", suffix: "</u>")
        case .strikethrough:
            applyMarkdown(prefix: "~~", suffix: "~~")
        case .highlight(let color):
            print("Applied highlight color: \(color)")
        case .textColor(let color):
            print("Applied text color: \(color)")
        case .bulletList:
            insertAtLineStart("- ")
        case .numberedList:
            insertAtLineStart("1. ")
        case .checklist:
            insertAtLineStart("- [ ] ")
        case .indent:
            print("Indent")
        case .outdent:
            print("Outdent")
        }
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
