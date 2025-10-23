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

    /// Local state for the rich text editor (bound to chapter content)
    @State private var attributedText: NSAttributedString = NSAttributedString()

    /// Focus state for the editor
    @FocusState private var isEditorFocused: Bool

    /// Selected text range for formatting operations
    @State private var textSelection: NSRange = NSRange(location: 0, length: 0)

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
            // MARK: - Rich Text Editor (Apple Notes style)
            // Supports text styling (Title, Heading, Body) and character formatting
            RichTextEditor(
                attributedText: $attributedText,
                selectedRange: $textSelection,
                isFocused: $isEditorFocused,
                onTextChange: { newAttributedText in
                    // Update chapter content with plain text for storage
                    let plainText = newAttributedText.string
                    viewModel?.updateChapterContent(chapter, content: plainText)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MARK: - Adaptive Keyboard Toolbar
            #if os(iOS)
            AdaptiveKeyboardToolbar(
                selectedRange: .constant(nil),
                content: .constant(attributedText.string),
                wordCount: chapter.wordCount,
                onFormatAction: handleFormatAction
            )
            #endif
        }
        .navigationTitle("")  // No navigation title - content speaks for itself
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = ChapterViewModel(modelContext: modelContext)
            }

            // Initialize attributed text from chapter content
            // TODO: Load formatted content if available, otherwise create from plain text
            let defaultFont = UIFont.systemFont(ofSize: 17)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: defaultFont,
                .foregroundColor: UIColor.label
            ]
            attributedText = NSAttributedString(string: chapter.content, attributes: attributes)

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
        .sheet(isPresented: $showingFormatToolbar) {
            FormatToolbar(
                selectedStyle: $currentTextStyle,
                onApplyFormat: handleTextFormat,
                onDismiss: {
                    showingFormatToolbar = false
                    isEditorFocused = true
                }
            )
            .presentationDetents([.height(170)])
            .presentationDragIndicator(.visible)
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
            isEditorFocused = false
            // Delay to allow keyboard to dismiss before showing sheet
            Task {
                try? await Task.sleep(for: .milliseconds(100))
                showingFormatToolbar = true
            }
        case .bold:
            handleTextFormat(.bold)
        case .italic:
            handleTextFormat(.italic)
        case .underline:
            handleTextFormat(.underline)
        case .strikethrough:
            handleTextFormat(.strikethrough)
        case .highlight(let color):
            handleTextFormat(.highlight(color))
        case .bulletList:
            handleTextFormat(.bulletList)
        case .numberedList:
            handleTextFormat(.numberedList)
        case .checklist:
            handleTextFormat(.checklist)
        case .quote:
            // TODO: Implement quote formatting
            print("Quote formatting not yet implemented")
        case .link:
            // TODO: Implement link insertion
            print("Link formatting not yet implemented")
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

    /// Handle text formatting from the format menu
    /// - Parameter format: The text format to apply
    private func handleTextFormat(_ format: TextFormat) {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)

        // Determine range to apply formatting
        var targetRange: NSRange

        switch format {
        case .style(let style):
            // For text styles, apply to entire paragraph or selected text
            if textSelection.length > 0 {
                targetRange = textSelection
            } else {
                // Apply to current paragraph
                targetRange = RichTextEditor.paragraphRange(for: textSelection, in: attributedText)
            }
            RichTextEditor.applyTextStyle(style, to: mutableText, range: targetRange)
            currentTextStyle = style

        case .bold, .italic, .underline, .strikethrough, .highlight, .textColor:
            // For character formatting, apply to selected text
            if textSelection.length > 0 {
                targetRange = textSelection
                RichTextEditor.applyCharacterFormat(format, to: mutableText, range: targetRange)
            } else {
                // No selection - apply to current paragraph for convenience
                targetRange = RichTextEditor.paragraphRange(for: textSelection, in: attributedText)
                RichTextEditor.applyCharacterFormat(format, to: mutableText, range: targetRange)
            }

        case .bulletList, .numberedList, .checklist:
            // For lists, insert at line start
            let paragraphRange = RichTextEditor.paragraphRange(for: textSelection, in: attributedText)
            let listMarker: String
            switch format {
            case .bulletList: listMarker = "• "
            case .numberedList: listMarker = "1. "
            case .checklist: listMarker = "☐ "
            default: listMarker = ""
            }

            mutableText.insert(NSAttributedString(string: listMarker), at: paragraphRange.location)

        case .indent, .outdent:
            // TODO: Implement indentation
            print("Indent/Outdent not yet implemented")
        }

        // Update the attributed text
        attributedText = mutableText
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
