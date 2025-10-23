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
///
/// This view uses modern SwiftData patterns with @Bindable
/// for automatic change tracking and persistence.
struct ChapterEditorView: View {
    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// Scene phase for detecting app backgrounding
    @Environment(\.scenePhase) private var scenePhase

    /// The chapter being edited (passed directly to avoid @Query rebuild triggers)
    @Bindable var chapter: Chapter

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

    /// Format menu visibility
    @State private var showingFormatMenu = false

    /// Chapter metadata
    @State private var chapterMetadata = ChapterMetadata()

    /// Text formatting state
    @State private var currentTextStyle: TextStyle = .body

    /// Simulated selected text for sheets (will be enhanced with actual selection)
    @State private var currentSelection = ""

    /// Debounced save task for formatting changes
    @State private var saveTask: Task<Void, Never>?

    /// Show export sheet
    @State private var showingExportSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Rich Text Editor (Apple Notes style)
            // Supports text styling (Title, Heading, Body) and character formatting
            RichTextEditor(
                attributedText: $attributedText,
                selectedRange: $textSelection,
                isFocused: $isEditorFocused,
                isEditable: !showingFormatMenu // Allow selection but prevent typing while format menu is open
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(chapter.id) // CRITICAL: Stable identity prevents view recreation
            .onChange(of: attributedText) { _, newValue in
                // Trigger debounced save when text changes
                // This uses .onChange instead of a closure parameter to maintain stable view identity
                debouncedSave(newValue, chapter: chapter)
            }

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
            loadChapterContent(chapter)
        }
        .onDisappear {
            // CRITICAL: Force save when navigating away to ensure no data loss
            forceSave(chapter)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Save when app moves to background
            if newPhase == .background {
                forceSave(chapter)
            }
        }
        .sheet(isPresented: $showingFormatMenu) {
            FormatMenuSheet(
                currentTextStyle: $currentTextStyle,
                onFormatAction: handleTextFormat
            )
            .presentationDetents([.height(250)])
            .presentationBackgroundInteraction(.enabled) // Key modifier!
            .interactiveDismissDisabled()
            .presentationDragIndicator(.hidden)
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
        .sheet(isPresented: $showingExportSheet) {
            // Get the parent book for export
            if let book = chapter.book {
                ExportView(book: book, chapter: chapter)
            }
        }
        .onChange(of: showingFormatMenu) { _, isShowing in
            // Dismiss keyboard when format menu opens
            if isShowing {
                isEditorFocused = false
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
                        showingExportSheet = true
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
                        forceSave(chapter)
                    } label: {
                        Label("Save Now", systemImage: "arrow.down.doc")
                    }
                    .keyboardShortcut("s", modifiers: .command)

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
                    forceSave(chapter)
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
            showingFormatMenu = true
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

    // MARK: - Chapter Loading

    /// Load chapter content when view appears
    /// - Parameter chapter: The chapter to load
    private func loadChapterContent(_ chapter: Chapter) {
        // Load formatted content (RTF) or create default from plain text
        attributedText = chapter.getAttributedContent()

        // Auto-focus for immediate typing
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            isEditorFocused = true
        }

        print("📖 Loaded chapter: \(chapter.extractedTitle)")
    }

    // MARK: - Save Operations

    /// Debounce save operations to avoid excessive writes during typing
    /// - Parameters:
    ///   - text: The attributed text to save
    ///   - chapter: The chapter to update
    private func debouncedSave(_ text: NSAttributedString, chapter: Chapter) {
        // Cancel any existing save task
        saveTask?.cancel()

        // Create new save task with delay
        saveTask = Task { @MainActor in
            do {
                // Wait for 500ms of inactivity before saving
                try await Task.sleep(for: .milliseconds(500))

                // Check if task was cancelled during sleep
                guard !Task.isCancelled else { return }

                // Perform the save
                performSave(text, chapter: chapter)
            } catch is CancellationError {
                // Task was cancelled - this is normal, don't log
            } catch {
                // Unexpected error
                print("⚠️ Save task error: \(error.localizedDescription)")
            }
        }
    }

    /// Force an immediate save (for onDisappear, Cmd+S, backgrounding)
    /// - Parameter chapter: The chapter to save
    private func forceSave(_ chapter: Chapter) {
        // Cancel any pending debounced save
        saveTask?.cancel()
        saveTask = nil

        // Save immediately with current attributed text
        print("🔒 Force saving chapter...")
        chapter.setAttributedContent(attributedText)

        // Trigger SwiftData save
        do {
            try modelContext.save()
            print("✅ Force save complete")
        } catch {
            print("❌ Force save failed: \(error.localizedDescription)")
        }
    }

    /// Perform the actual save operation
    /// - Parameters:
    ///   - text: The attributed text to save
    ///   - chapter: The chapter to update
    @MainActor
    private func performSave(_ text: NSAttributedString, chapter: Chapter) {
        print("💾 Auto-saving chapter...")

        // Update chapter with new content
        chapter.setAttributedContent(text)

        // Update parent book's lastModified timestamp
        chapter.book?.lastModified = Date()

        // Trigger SwiftData save
        do {
            try modelContext.save()
            print("✅ Auto-save complete")
        } catch {
            print("❌ Auto-save failed: \(error.localizedDescription)")
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
    let store = DataStore(inMemory: true)
    let chapter = Chapter(title: "Untitled Chapter", content: "")
    store.modelContainer.mainContext.insert(chapter)

    return ChapterEditorView(chapter: chapter)
        .modelContainer(store.modelContainer)
}
