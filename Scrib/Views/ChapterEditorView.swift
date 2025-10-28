//
//  ChapterEditorView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
fileprivate typealias PlatformFont = UIFont
fileprivate typealias PlatformColor = UIColor

fileprivate extension UIColor {
    static var labelColor: UIColor { .label }
    static var secondaryLabelColor: UIColor { .secondaryLabel }
    static var tertiaryLabelColor: UIColor { .tertiaryLabel }
}
#elseif canImport(AppKit)
import AppKit
fileprivate typealias PlatformFont = NSFont
fileprivate typealias PlatformColor = NSColor
#endif

/// Detail pane view for editing chapter content
///
/// ChapterEditorView provides a distraction-free writing environment with
/// real-time word/character counts, auto-save, and a clean interface
/// inspired by Apple Notes.
///
/// This view uses modern SwiftData patterns with @Bindable
/// for automatic change tracking and persistence.
@MainActor
struct ChapterEditorView: View {
    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// Scene phase for detecting app backgrounding
    @Environment(\.scenePhase) private var scenePhase

    /// The chapter being edited (passed directly to avoid @Query rebuild triggers)
    /// Made optional to safely handle SwiftData loading issues
    var chapter: Chapter?

    /// Search text binding for filtering chapter list (macOS only)
    /// Controlled by the toolbar search bar but filters the chapter list in ContentView
    @Binding var searchText: String

    /// Zen mode binding for distraction-free writing (macOS only)
    /// When enabled, hides sidebar and chapter list, showing only the editor
    @Binding var isZenModeEnabled: Bool

    /// Callback to handle chapter selection from inspector (macOS only)
    var onChapterSelect: ((Chapter) -> Void)?

    /// View model for chapter operations (initialized on appear)
    @State private var viewModel: ChapterViewModel?

    /// Local state for the rich text editor (bound to chapter content)
    @State private var attributedText: NSAttributedString = NSAttributedString()

    /// CRITICAL: Closure to get current textStorage content (prevents race condition data loss)
    /// This provides access to fresh textStorage data instead of stale binding
    @State private var getCurrentTextStorageContent: (() -> NSAttributedString)?

    /// Focus state for the editor
    @FocusState private var isEditorFocused: Bool

    /// Selected text range for formatting operations
    @State private var textSelection: NSRange = NSRange(location: 0, length: 0)

    /// Sheet presentation states
    @State private var showingCharacterMarker = false
    @State private var showingInlineNote = false
    @State private var showingMetadata = false
    @State private var showingLinkInsertion = false
    @State private var showingTableInsertion = false

    /// Format menu visibility
    @State private var showingFormatMenu = false

    #if os(macOS)
    /// Format popover visibility (macOS only)
    @State private var showingFormatPopover = false
    #endif

    /// Text formatting state
    @State private var currentTextStyle: TextStyle = .body

    /// Currently active text formats at cursor/selection (for format menu button states)
    @State private var activeFormats: Set<TextFormat> = []

    /// Simulated selected text for sheets (will be enhanced with actual selection)
    @State private var currentSelection = ""

    /// Debounced save task for formatting changes
    @State private var saveTask: Task<Void, Never>?

    /// Show export sheet
    @State private var showingExportSheet = false

    #if os(macOS)
    /// Inspector visibility state (persisted)
    @AppStorage("isInspectorVisible") private var isInspectorVisibleStorage: Bool = false

    /// Inspector presentation state
    @State private var isInspectorPresented: Bool = false
    #endif

    var body: some View {
        Group {
            if let chapter = chapter {
                editorContent(for: chapter)
            } else {
                VStack {
                    Text("Chapter not available")
                        .foregroundStyle(.secondary)
                        .font(.headline)
                    Text("Please try selecting the chapter again")
                        .foregroundStyle(.tertiary)
                        .font(.subheadline)
                }
            }
        }
    }

    @ViewBuilder
    private func editorContent(for chapter: Chapter) -> some View {
        VStack(spacing: 0) {
                // MARK: - Rich Text Editor (Apple Notes style)
                // Supports text styling (Title, Heading, Body) and character formatting
                RichTextEditor(
                    attributedText: $attributedText,
                    selectedRange: $textSelection,
                    isFocused: $isEditorFocused,
                    isEditable: true, // Always editable - cursor and selection work at all times
                    shouldHideKeyboard: showingFormatMenu, // Hide keyboard with custom inputView (Apple Notes behavior)
                    onAttributesChanged: { formats in
                        // Update active formats for format menu button states
                        activeFormats = formats
                    },
                    getCurrentContent: $getCurrentTextStorageContent // CRITICAL: Access to fresh textStorage
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
                activeFormats: activeFormats,
                onFormatAction: handleFormatAction
            )
            #endif
        }
        .navigationTitle("")  // No navigation title - content speaks for itself
        .adaptiveNavigationBarTitleDisplayMode(.inline)
        .task {
            // CRITICAL: Load content in async task with INCREASED delay
            // Direct property access in onAppear triggers SwiftData faults → model context changes → view rebuild → INFINITE RECURSION
            // Task with delay breaks the synchronous cycle

            // Initialize view model
            if viewModel == nil {
                viewModel = ChapterViewModel(modelContext: modelContext)
            }

            #if os(macOS)
            // Sync AppStorage to State for inspector visibility
            isInspectorPresented = isInspectorVisibleStorage
            #endif

            // CRITICAL: Increased delay from 100ms to 200ms
            // This ensures ALL view updates and SwiftData operations complete first
            // Prevents blocking the UI thread during initial render
            try? await Task.sleep(for: .milliseconds(200))

            guard !Task.isCancelled else { return }

            // CRITICAL: Explicitly run on MainActor
            // AppKit classes (NSColor, NSAttributedString) MUST be accessed from main thread
            // .task can run on background threads, causing EXC_BAD_ACCESS
            await MainActor.run {
                loadChapterContent(chapter)
            }
        }
        .onDisappear {
            // CRITICAL: Force save when navigating away to ensure no data loss
            // BUT: Skip save if getCurrentTextStorageContent is nil (view just created, not used yet)
            // This prevents newly created views from overwriting with empty content during zen mode transitions
            #if os(macOS)
            guard getCurrentTextStorageContent != nil else {
                print("⏭️ Skipping force save - view just created, closure not set yet")
                return
            }
            #endif
            forceSave(chapter)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Save when app moves to background
            if newPhase == .background {
                forceSave(chapter)
            }
        }
        #if os(macOS)
        .onChange(of: isInspectorPresented) { _, newValue in
            // Persist inspector visibility state
            isInspectorVisibleStorage = newValue
        }
        #endif
        #if os(iOS)
        .sheet(isPresented: $showingFormatMenu) {
            FormatMenuSheet(
                currentTextStyle: $currentTextStyle,
                activeFormats: activeFormats,
                onFormatAction: handleTextFormat
            )
            .presentationDetents([.height(250)])
            .presentationBackgroundInteraction(.enabled) // Key modifier: allows interaction with editor!
            .interactiveDismissDisabled()
            .presentationDragIndicator(.hidden)
        }
        #endif
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
        .sheet(isPresented: $showingLinkInsertion) {
            LinkInsertionSheet(selectedText: currentSelection) { url, displayText in
                insertLink(url: url, displayText: displayText)
            }
        }
        .sheet(isPresented: $showingTableInsertion) {
            TableInsertionSheet { rows, columns in
                insertTable(rows: rows, columns: columns)
            }
        }
        .sheet(isPresented: $showingMetadata) {
            if let viewModel = viewModel {
                ChapterMetadataSheet(
                    chapter: chapter,
                    viewModel: viewModel
                )
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            // Get the parent book for export
            // CRITICAL: Use safe relationship access to prevent EXC_BAD_ACCESS
            if let book = chapter.safeBook {
                ExportView(book: book, chapter: chapter)
            }
        }
        // MARK: - Format Menu Keyboard Management (Apple Notes behavior)
        .onChange(of: showingFormatMenu) { _, isShowing in
            if isShowing {
                // Dismiss keyboard when format menu opens
                // Custom inputView keeps text view interactive (cursor visible, movable, text selectable)
                isEditorFocused = false
            } else {
                // Restore keyboard when format menu closes
                // Small delay ensures smooth animation transition
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    // Check if task was cancelled (view disappeared)
                    guard !Task.isCancelled else { return }
                    isEditorFocused = true
                }
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
            // macOS toolbar - comprehensive format tools + search + export + inspector
            ToolbarItemGroup(placement: .primaryAction) {
                // Format popover (Aa button) - matches Apple Notes design
                Button {
                    showingFormatPopover.toggle()
                } label: {
                    Label("Format", systemImage: "textformat")
                }
                .help("Text formatting")
                .popover(isPresented: $showingFormatPopover, arrowEdge: .bottom) {
                    FormatPopoverView(
                        currentTextStyle: $currentTextStyle,
                        activeFormats: activeFormats,
                        onFormatAction: handleTextFormat
                    )
                }

                // Core content tools
                Button {
                    handleFormatAction(.quote)
                } label: {
                    Label("Quote", systemImage: "text.quote")
                }
                .help("Insert quote")

                Button {
                    handleFormatAction(.link)
                } label: {
                    Label("Link", systemImage: "link")
                }
                .help("Insert link")

                Button {
                    handleFormatAction(.image)
                } label: {
                    Label("Image", systemImage: "photo")
                }
                .help("Insert image")

                Button {
                    handleFormatAction(.table)
                } label: {
                    Label("Table", systemImage: "tablecells")
                }
                .help("Insert table")

                Divider()

                // Scrib-specific authoring tools
                Button {
                    handleFormatAction(.markCharacter)
                } label: {
                    Label("Mark Character", systemImage: "person.fill.badge.plus")
                }
                .help("Mark character")

                Button {
                    handleFormatAction(.addNote)
                } label: {
                    Label("Add Note", systemImage: "note.text.badge.plus")
                }
                .help("Add note")

                Button {
                    handleFormatAction(.markScene)
                } label: {
                    Label("Mark Scene", systemImage: "mappin.circle")
                }
                .help("Mark scene location")

                Button {
                    handleFormatAction(.markPOV)
                } label: {
                    Label("Mark POV", systemImage: "eye.fill")
                }
                .help("Mark point of view")

                Button {
                    handleFormatAction(.setMetadata)
                } label: {
                    Label("Metadata", systemImage: "tag.fill")
                }
                .help("Set chapter metadata")

                Spacer()

                // Word count display
                HStack(spacing: 4) {
                    Text("\(chapter.wordCount)")
                        .font(.caption.monospacedDigit())
                        .fontWeight(.medium)
                    Text("words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
            }

            // Right side: Export, Zen Mode, and Inspector
            ToolbarItem(placement: .automatic) {
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export chapter")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    isZenModeEnabled.toggle()
                } label: {
                    Label("Zen Mode", systemImage: isZenModeEnabled ? "arrow.down.right.and.arrow.up.left.rectangle" : "arrow.up.left.and.arrow.down.right.rectangle")
                }
                .keyboardShortcut("f", modifiers: [.command, .control])
                .help("Toggle Zen Mode (^⌘F)")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    isInspectorPresented.toggle()
                } label: {
                    Label("Inspector", systemImage: "sidebar.right")
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
                .help("Toggle Inspector")
            }
            #endif
        }
        #if os(macOS)
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search")
        .inspector(isPresented: $isInspectorPresented) {
            // CRITICAL: Use safe relationship access to prevent EXC_BAD_ACCESS
            // chapter.book might be faulting on macOS when chapter is first selected
            if let book = chapter.safeBook {
                InspectorView(
                    book: book,
                    chapter: chapter,
                    onChapterSelect: { selectedChapter in
                        // Handle chapter selection from outline
                        // This navigates to the selected chapter in the main view
                        print("Selected chapter from inspector: \(selectedChapter.extractedTitle)")
                        onChapterSelect?(selectedChapter)
                    }
                )
            }
        }
        #endif
        #if os(macOS)
        // MARK: - Keyboard Shortcuts for Alignment (macOS only)
        .background(
            // Invisible buttons with keyboard shortcuts
            VStack {
                Button("Left Align") {
                    handleTextFormat(.alignLeft)
                }
                .keyboardShortcut("{", modifiers: .command)
                .hidden()

                Button("Center Align") {
                    handleTextFormat(.alignCenter)
                }
                .keyboardShortcut("|", modifiers: .command)
                .hidden()

                Button("Right Align") {
                    handleTextFormat(.alignRight)
                }
                .keyboardShortcut("}", modifiers: .command)
                .hidden()
            }
        )
        #endif
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
            // Implement quote block formatting with visual styling
            // CRITICAL: Get FRESH content from textStorage, not stale binding
            guard let currentText = getCurrentTextStorageContent?() else {
                print("❌ CRITICAL: Cannot get current textStorage content for quote block")
                return
            }
            let mutableText = NSMutableAttributedString(attributedString: currentText)

            // Determine range (selected text or current paragraph)
            let targetRange: NSRange
            if textSelection.length > 0 {
                // Use selection, but expand to full paragraphs
                targetRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            } else {
                // Use current paragraph
                targetRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            }

            guard targetRange.location != NSNotFound && targetRange.length > 0 else { return }

            // Check if already a quote block by looking for the specific combination of attributes
            // A quote block has: headIndent=20, background color, and possibly italic font
            let existingAttributes = mutableText.attributes(at: targetRange.location, effectiveRange: nil)
            let hasQuoteIndent = (existingAttributes[.paragraphStyle] as? NSParagraphStyle)?.headIndent == 20
            let hasQuoteBackground: Bool
            #if canImport(UIKit)
            if let bgColor = existingAttributes[.backgroundColor] as? UIColor {
                hasQuoteBackground = (bgColor != .clear && bgColor.cgColor.alpha > 0)
            } else {
                hasQuoteBackground = false
            }
            #else
            if let bgColor = existingAttributes[.backgroundColor] as? NSColor {
                hasQuoteBackground = (bgColor != .clear && bgColor.alphaComponent > 0)
            } else {
                hasQuoteBackground = false
            }
            #endif
            let isAlreadyQuoted = hasQuoteIndent && hasQuoteBackground

            if isAlreadyQuoted {
                // Remove quote block styling
                removeQuoteBlockStyling(from: mutableText, range: targetRange)
            } else {
                // Apply quote block styling
                applyQuoteBlockStyling(to: mutableText, range: targetRange)
            }

            attributedText = mutableText
        case .link:
            // Show link insertion sheet
            // Get selected text if any
            if textSelection.length > 0 {
                // CRITICAL: Get FRESH content from textStorage
                if let freshText = getCurrentTextStorageContent?() {
                    currentSelection = (freshText.string as NSString).substring(with: textSelection)
                } else {
                    currentSelection = ""
                }
            } else {
                currentSelection = ""
            }
            showingLinkInsertion = true
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
            if let chapter = chapter, let metadata = chapter.metadata {
                metadata.sceneLocation = "Scene"
            }
            showingMetadata = true
        case .markPOV:
            // Quick-set POV
            showingMetadata = true
        case .image:
            // Show native file picker for image insertion (macOS only)
            #if os(macOS)
            showImagePicker()
            #else
            print("Image insertion not implemented on iOS")
            #endif
        case .table:
            // Show table insertion sheet
            showingTableInsertion = true
        case .cycleAlignment:
            // Cycle through alignments: left → center → right → justified → left
            let nextAlignment: TextFormat
            if activeFormats.contains(.alignLeft) {
                nextAlignment = .alignCenter
            } else if activeFormats.contains(.alignCenter) {
                nextAlignment = .alignRight
            } else if activeFormats.contains(.alignRight) {
                nextAlignment = .alignJustified
            } else {
                nextAlignment = .alignLeft
            }
            handleTextFormat(nextAlignment)
        default:
            print("Format action not yet implemented: \(action)")
        }
    }

    /// Handle text formatting from the format menu with intelligent toggling
    /// - Parameter format: The text format to apply or remove
    private func handleTextFormat(_ format: TextFormat) {
        // CRITICAL: Get FRESH content from textStorage, not stale binding
        // This prevents race condition where typing hasn't updated binding yet
        guard let currentText = getCurrentTextStorageContent?() else {
            print("❌ CRITICAL: Cannot get current textStorage content")
            return
        }
        let mutableText = NSMutableAttributedString(attributedString: currentText)

        // Track selection adjustment for operations that insert/delete text
        // Will be applied AFTER attributedText update to prevent restoration conflicts
        var selectionAdjustment: (paragraphLocation: Int, delta: Int)? = nil

        // Determine range to apply formatting
        var targetRange: NSRange

        switch format {
        case .style(let style):
            // For text styles, apply to entire paragraph or selected text
            if textSelection.length > 0 {
                targetRange = textSelection
            } else {
                // Apply to current paragraph
                targetRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            }
            RichTextEditor.applyTextStyle(style, to: mutableText, range: targetRange)
            currentTextStyle = style

        case .bold, .italic, .underline, .strikethrough, .highlight, .textColor:
            // For character formatting, check if active and toggle
            if textSelection.length > 0 {
                targetRange = textSelection
            } else {
                // No selection - apply to current paragraph for convenience
                targetRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            }

            // CRITICAL: Detect formats FRESH from current text - don't trust stale activeFormats state
            let currentFormats = RichTextEditor.detectActiveFormats(in: currentText, at: textSelection)
            let isActive = currentFormats.contains(where: { existingFormat in
                // For formats with associated values (colors), compare the base type
                switch (format, existingFormat) {
                case (.bold, .bold), (.italic, .italic), (.underline, .underline), (.strikethrough, .strikethrough):
                    return true
                case (.highlight, .highlight), (.textColor, .textColor):
                    return true
                default:
                    return false
                }
            })

            // Toggle: if active, remove; if inactive, apply
            if isActive {
                RichTextEditor.removeCharacterFormat(format, from: mutableText, range: targetRange)
            } else {
                RichTextEditor.applyCharacterFormat(format, to: mutableText, range: targetRange)
            }

        case .bulletList, .numberedList, .checklist:
            // Get the current paragraph range
            let paragraphRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            guard paragraphRange.location != NSNotFound && paragraphRange.length > 0 else { break }

            let paragraphText = (currentText.string as NSString).substring(with: paragraphRange)

            // Determine the new list marker
            let newMarker: String
            switch format {
            case .bulletList: newMarker = "• "
            case .numberedList: newMarker = "1. "
            case .checklist: newMarker = "☐ "
            default: newMarker = ""
            }

            // Detect any existing list marker at the start of the paragraph (FRESH detection)
            var existingMarkerRange: NSRange?
            var existingMarkerType: TextFormat?

            if paragraphText.hasPrefix("• ") {
                existingMarkerRange = NSRange(location: paragraphRange.location, length: 2)
                existingMarkerType = .bulletList
            } else if let match = paragraphText.range(of: "^\\d+\\.\\s", options: .regularExpression) {
                let length = paragraphText.distance(from: paragraphText.startIndex, to: match.upperBound)
                existingMarkerRange = NSRange(location: paragraphRange.location, length: length)
                existingMarkerType = .numberedList
            } else if paragraphText.hasPrefix("☐ ") || paragraphText.hasPrefix("☑ ") {
                existingMarkerRange = NSRange(location: paragraphRange.location, length: 2)
                existingMarkerType = .checklist
            }

            // CRITICAL: Use FRESH detection - check if same list type is already present
            let isAlreadyActive = (existingMarkerType == format)

            // Track text length changes for selection adjustment
            var selectionDelta = 0

            // Apply list formatting logic
            if isAlreadyActive {
                // Toggle OFF: Remove the existing marker
                if let markerRange = existingMarkerRange {
                    mutableText.deleteCharacters(in: markerRange)
                    // Adjust selection: text was deleted
                    selectionDelta = -markerRange.length
                }
            } else if let markerRange = existingMarkerRange {
                // Switch list types: Replace the existing marker
                let oldMarkerLength = markerRange.length
                mutableText.replaceCharacters(in: markerRange, with: "")

                // Insert new marker with proper attributes
                let markerAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: PlatformColor.labelColor, // Adapts to light/dark mode
                    .font: PlatformFont.systemFont(ofSize: 17)
                ]
                let attributedMarker = NSAttributedString(string: newMarker, attributes: markerAttributes)
                mutableText.insert(attributedMarker, at: paragraphRange.location)

                // Adjust selection: old marker removed, new marker added
                selectionDelta = newMarker.count - oldMarkerLength
            } else {
                // No existing marker: Insert new marker with proper attributes
                let markerAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: PlatformColor.labelColor, // Adapts to light/dark mode
                    .font: PlatformFont.systemFont(ofSize: 17)
                ]
                let attributedMarker = NSAttributedString(string: newMarker, attributes: markerAttributes)
                mutableText.insert(attributedMarker, at: paragraphRange.location)

                // Adjust selection: text was inserted
                selectionDelta = newMarker.count
            }

            // Store selection adjustment to apply AFTER text update
            // This prevents the RichTextEditor's restoration logic from overwriting our adjustment
            selectionAdjustment = (paragraphRange.location, selectionDelta)

        case .indent:
            // Apply indentation to current paragraph or selected paragraphs
            let paragraphRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            RichTextEditor.applyIndent(to: mutableText, range: paragraphRange)

        case .outdent:
            // Remove indentation from current paragraph or selected paragraphs
            let paragraphRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            RichTextEditor.applyOutdent(to: mutableText, range: paragraphRange)

        case .alignLeft:
            // Apply left alignment to current paragraph or selected paragraphs
            let paragraphRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            RichTextEditor.applyTextAlignment(.left, to: mutableText, range: paragraphRange)

        case .alignCenter:
            // Apply center alignment to current paragraph or selected paragraphs
            let paragraphRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            RichTextEditor.applyTextAlignment(.center, to: mutableText, range: paragraphRange)

        case .alignRight:
            // Apply right alignment to current paragraph or selected paragraphs
            let paragraphRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            RichTextEditor.applyTextAlignment(.right, to: mutableText, range: paragraphRange)

        case .alignJustified:
            // Apply justified alignment to current paragraph or selected paragraphs
            let paragraphRange = RichTextEditor.paragraphRange(for: textSelection, in: currentText)
            RichTextEditor.applyTextAlignment(.justified, to: mutableText, range: paragraphRange)
        }

        // Update the attributed text
        attributedText = mutableText

        // Apply selection adjustment if needed (e.g., after list marker insertion/deletion)
        // This happens AFTER text update to prevent RichTextEditor restoration conflicts
        if let adjustment = selectionAdjustment,
           textSelection.location >= adjustment.paragraphLocation {
            textSelection = NSRange(
                location: max(adjustment.paragraphLocation, textSelection.location + adjustment.delta),
                length: textSelection.length
            )
        }

        // CRITICAL: Synchronously update activeFormats to prevent UI state divergence
        // We CANNOT rely on textViewDidChangeSelection callback - it's unreliable
        // This ensures the format menu buttons immediately reflect the actual text state
        activeFormats = RichTextEditor.detectActiveFormats(in: mutableText, at: textSelection)
    }

    // MARK: - Chapter Loading

    /// Load chapter content when view appears
    /// - Parameter chapter: The chapter to load
    @MainActor
    private func loadChapterContent(_ chapter: Chapter) {
        // CRITICAL: Validate chapter object before accessing properties
        // Prevents EXC_BAD_ACCESS on macOS when object is faulting
        guard chapter.isValidForAccess else {
            print("❌ CRITICAL: Chapter object not valid for content loading")
            // Set empty attributed text with default formatting
            let defaultFont = PlatformFont.systemFont(ofSize: 17)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: defaultFont,
                .foregroundColor: PlatformColor.labelColor
            ]
            attributedText = NSAttributedString(string: "", attributes: attributes)
            return
        }

        // REMOVED: modelContext.processPendingChanges()
        // This was causing infinite recursion by triggering view rebuilds during selection
        // SwiftData will handle pending changes automatically

        // Load formatted content (RTF) or create default from plain text
        // getAttributedContent() now has its own validation
        attributedText = chapter.getAttributedContent()

        // APPLE NOTES BEHAVIOR: Initialize empty chapters with title-style formatting
        // This ensures the first line is automatically styled as a title (28pt bold)
        if attributedText.string.isEmpty {
            // Create attributed string with title-style font
            let titleFont = PlatformFont.systemFont(ofSize: 28, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: PlatformColor.labelColor
            ]
            // CRITICAL: Use zero-width space (U+200B) instead of empty string
            // Empty attributed strings discard their attributes because there are no characters
            // The zero-width space is invisible but preserves the title-style attributes
            // so updateTypingAttributes() can access them
            attributedText = NSAttributedString(string: "\u{200B}", attributes: attributes)

            // CRITICAL: Set cursor position to start (before zero-width space)
            // This prevents backspace from trying to delete it immediately
            // ONLY for empty chapters - chapters with content use normal cursor positioning
            textSelection = NSRange(location: 0, length: 0)

            // Set current text style to title for format menu display
            currentTextStyle = .title

            // Auto-focus for immediate typing (ONLY for empty chapters)
            // CRITICAL: Increased delay ensures NSTextView is fully initialized and ready for focus
            // Existing chapters with content should NOT auto-focus - user clicks to focus naturally
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                // Check if task was cancelled (view disappeared before sleep completed)
                guard !Task.isCancelled else { return }
                isEditorFocused = true
            }

            print("📝 Initialized empty chapter with title-style formatting (zero-width space at position 0)")
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
                // BALANCED DELAY: Wait for 150ms of inactivity before saving
                // Optimized for real-time list updates while reducing rapid-fire saves during fast typing
                try await Task.sleep(for: .milliseconds(150))

                // Check if task was cancelled during sleep
                guard !Task.isCancelled else { return }

                // VALIDATION: Verify text hasn't changed since capture
                // This prevents saving stale content if another update happened
                guard text.string == attributedText.string else {
                    print("⏭️ Skipping stale save - content changed during delay")
                    return
                }

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

    /// Force an immediate save (for onDisappear, Cmd+S, backgrounding, zen mode transitions)
    /// - Parameter chapter: The chapter to save
    private func forceSave(_ chapter: Chapter) {
        // Cancel any pending debounced save
        saveTask?.cancel()
        saveTask = nil

        // VALIDATION: Check chapter is valid for access
        guard chapter.isValidForAccess else {
            print("❌ Force save aborted: chapter not valid for access")
            return
        }

        // CRITICAL FIX: Get FRESH content directly from text view
        // The attributedText binding may be stale due to deferred updates in textDidChange
        // Using getCurrentTextStorageContent() bypasses the binding and gets real-time content
        let contentToSave: NSAttributedString
        if let getCurrentContent = getCurrentTextStorageContent {
            contentToSave = getCurrentContent()
            print("🔒 Force saving (from text view directly)")
        } else {
            contentToSave = attributedText
            print("🔒 Force saving (from binding - fallback)")
        }

        let contentLength = contentToSave.length
        let contentHash = contentToSave.string.hashValue
        print("   ID: \(chapter.id), length: \(contentLength), hash: \(contentHash)")

        chapter.setAttributedContent(contentToSave)

        // Trigger SwiftData save - SYNCHRONOUS on main actor
        do {
            try modelContext.save()
            print("✅ Force save complete - verified \(chapter.content.count) chars written")
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
        // VALIDATION: Check chapter is valid for access
        guard chapter.isValidForAccess else {
            print("❌ Auto-save aborted: chapter not valid for access")
            return
        }

        let contentLength = text.length
        let contentHash = text.string.hashValue
        print("💾 Auto-saving chapter (ID: \(chapter.id), length: \(contentLength), hash: \(contentHash))...")

        // Update chapter with new content
        chapter.setAttributedContent(text)

        // Update parent book's lastModified timestamp
        // CRITICAL: Use safe relationship access to prevent EXC_BAD_ACCESS
        if let parentBook = chapter.safeBook {
            parentBook.lastModified = Date()
        } else {
            print("⚠️ WARNING: Chapter has no parent book relationship during save")
        }

        // Trigger SwiftData save
        do {
            try modelContext.save()
            print("✅ Auto-save complete - verified \(chapter.content.count) chars written")
        } catch {
            print("❌ Auto-save failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Link Insertion

    /// Insert a hyperlink at the current cursor position or replace selected text
    /// - Parameters:
    ///   - url: The URL to link to
    ///   - displayText: The text to display for the link
    private func insertLink(url: String, displayText: String) {
        // CRITICAL: Get FRESH content from textStorage, not stale binding
        guard let currentText = getCurrentTextStorageContent?() else {
            print("❌ CRITICAL: Cannot get current textStorage content for link insertion")
            return
        }
        let mutableText = NSMutableAttributedString(attributedString: currentText)

        // Create link attributes
        #if canImport(UIKit)
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .link: url,
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: UIFont.systemFont(ofSize: 17)
        ]
        #else
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .link: url,
            .foregroundColor: NSColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: NSFont.systemFont(ofSize: 17)
        ]
        #endif

        let linkString = NSAttributedString(string: displayText, attributes: linkAttributes)

        // Replace selected text or insert at cursor
        if textSelection.length > 0 {
            // Replace selected text with link
            mutableText.replaceCharacters(in: textSelection, with: linkString)
            // Update selection to end of inserted link
            textSelection = NSRange(location: textSelection.location + displayText.count, length: 0)
        } else {
            // Insert at cursor position
            mutableText.insert(linkString, at: textSelection.location)
            // Update selection to end of inserted link
            textSelection = NSRange(location: textSelection.location + displayText.count, length: 0)
        }

        // Update the attributed text
        attributedText = mutableText
    }

    // MARK: - Image Insertion

    #if os(macOS)
    /// Show native macOS file picker for image selection
    private func showImagePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.message = "Select an image to insert"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task { @MainActor in
                    await self.insertImage(from: url)
                }
            }
        }
    }

    /// Insert an image from a file URL into the text
    /// - Parameter url: The file URL of the image
    @MainActor
    private func insertImage(from url: URL) async {
        guard let image = NSImage(contentsOf: url) else {
            print("❌ Failed to load image from: \(url)")
            return
        }

        // Create text attachment
        let attachment = NSTextAttachment()
        attachment.image = image

        // Scale image if too large (max width 600pt)
        let maxWidth: CGFloat = 600
        if image.size.width > maxWidth {
            let scale = maxWidth / image.size.width
            attachment.bounds = CGRect(
                x: 0,
                y: 0,
                width: maxWidth,
                height: image.size.height * scale
            )
        } else {
            attachment.bounds = CGRect(origin: .zero, size: image.size)
        }

        // Create attributed string from attachment
        let attachmentString = NSAttributedString(attachment: attachment)

        // CRITICAL: Get FRESH content from textStorage, not stale binding
        guard let currentText = getCurrentTextStorageContent?() else {
            print("❌ CRITICAL: Cannot get current textStorage content for image insertion")
            return
        }
        let mutableText = NSMutableAttributedString(attributedString: currentText)

        // Insert at cursor position
        mutableText.insert(attachmentString, at: textSelection.location)

        // Add newline after image for better formatting
        let newline = NSAttributedString(
            string: "\n",
            attributes: [
                .font: NSFont.systemFont(ofSize: 17),
                .foregroundColor: NSColor.labelColor
            ]
        )
        mutableText.insert(newline, at: textSelection.location + 1)

        // Update the attributed text
        attributedText = mutableText

        // Move cursor after image and newline
        textSelection = NSRange(location: textSelection.location + 2, length: 0)

        print("✅ Image inserted successfully")
    }
    #endif

    // MARK: - Table Insertion

    /// Insert a formatted table at the current cursor position
    /// - Parameters:
    ///   - rows: Number of rows
    ///   - columns: Number of columns
    private func insertTable(rows: Int, columns: Int) {
        // CRITICAL: Get FRESH content from textStorage, not stale binding
        guard let currentText = getCurrentTextStorageContent?() else {
            print("❌ CRITICAL: Cannot get current textStorage content for table insertion")
            return
        }
        let mutableText = NSMutableAttributedString(attributedString: currentText)

        #if canImport(UIKit)
        let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let textColor = UIColor.label
        let separatorColor = UIColor.separator
        #else
        let font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        let textColor = NSColor.labelColor
        let separatorColor = NSColor.separatorColor
        #endif

        // Create table as formatted text
        // Calculate column width (approximate - 15 characters per column)
        let columnWidth = 15

        var tableText = "\n" // Start with newline

        // Top border
        tableText += "┌" + (0..<columns).map { _ in String(repeating: "─", count: columnWidth) }.joined(separator: "┬") + "┐\n"

        // Header row (first row)
        for row in 0..<rows {
            tableText += "│"
            for col in 0..<columns {
                let cellContent = row == 0 ? "Header \(col + 1)" : "Cell"
                let padding = String(repeating: " ", count: max(0, columnWidth - cellContent.count - 1))
                tableText += " " + cellContent + padding + "│"
            }
            tableText += "\n"

            // Separator after header or between rows
            if row == 0 {
                // Header separator (thicker)
                tableText += "├" + (0..<columns).map { _ in String(repeating: "─", count: columnWidth) }.joined(separator: "┼") + "┤\n"
            } else if row < rows - 1 {
                // Regular separator
                tableText += "├" + (0..<columns).map { _ in String(repeating: "─", count: columnWidth) }.joined(separator: "┼") + "┤\n"
            }
        }

        // Bottom border
        tableText += "└" + (0..<columns).map { _ in String(repeating: "─", count: columnWidth) }.joined(separator: "┴") + "┘\n"

        // Create attributed string with monospaced font
        let tableAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let tableString = NSAttributedString(string: tableText, attributes: tableAttributes)

        // Insert at cursor position
        mutableText.insert(tableString, at: textSelection.location)

        // Update the attributed text
        attributedText = mutableText

        // Move cursor after table
        textSelection = NSRange(location: textSelection.location + tableText.count, length: 0)

        print("✅ Table (\(rows)×\(columns)) inserted successfully")
    }

    // MARK: - Quote Block Styling

    /// Apply quote block styling to the given text range
    /// - Parameters:
    ///   - text: The mutable attributed string to modify
    ///   - range: The range to apply quote styling to
    private func applyQuoteBlockStyling(to text: NSMutableAttributedString, range: NSRange) {
        // REDESIGNED: Paragraph-style approach WITH visual markers for clarity
        // The typingAttributes system ensures attributes persist when typing
        // Visual markers ("┃ ") provide clear quote block indication

        // Create paragraph style with distinctive indentation
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20 // Left indentation
        paragraphStyle.firstLineHeadIndent = 20
        paragraphStyle.tailIndent = -10 // Right margin

        #if canImport(UIKit)
        // Get current font at range start to preserve size, then make italic
        let currentFont: UIFont
        if text.length > range.location {
            currentFont = text.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont
                ?? UIFont.systemFont(ofSize: 17, weight: .regular)
        } else {
            currentFont = UIFont.systemFont(ofSize: 17, weight: .regular)
        }
        let italicFont = currentFont.with(traits: .traitItalic)

        // Apply quote block attributes to the entire range
        // These will be preserved by typingAttributes when user types
        text.addAttributes([
            .paragraphStyle: paragraphStyle,
            .backgroundColor: UIColor.systemGray6, // Light background
            .foregroundColor: UIColor.secondaryLabel, // Slightly muted text
            .font: italicFont
        ], range: range)

        // Add visual left border using "┃ " marker at paragraph start
        // Insert markers at the beginning of each line in the range
        let paragraphRanges = getParagraphRanges(in: text, for: range)
        var offset = 0
        for paragraphRange in paragraphRanges {
            let adjustedLocation = paragraphRange.location + offset
            let borderMarker = NSAttributedString(
                string: "┃ ",
                attributes: [
                    .foregroundColor: UIColor.systemBlue,
                    .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
                ]
            )
            text.insert(borderMarker, at: adjustedLocation)
            offset += 2 // Account for inserted characters
        }
        #else
        // macOS version
        let currentFont: NSFont
        if text.length > range.location {
            currentFont = text.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
                ?? NSFont.systemFont(ofSize: 17, weight: .regular)
        } else {
            currentFont = NSFont.systemFont(ofSize: 17, weight: .regular)
        }
        let italicFont = currentFont.with(traits: .italic)

        text.addAttributes([
            .paragraphStyle: paragraphStyle,
            .backgroundColor: NSColor.quaternaryLabelColor, // Light background
            .foregroundColor: NSColor.secondaryLabelColor, // Slightly muted text
            .font: italicFont
        ], range: range)

        // Add visual left border
        let paragraphRanges = getParagraphRanges(in: text, for: range)
        var offset = 0
        for paragraphRange in paragraphRanges {
            let adjustedLocation = paragraphRange.location + offset
            let borderMarker = NSAttributedString(
                string: "┃ ",
                attributes: [
                    .foregroundColor: NSColor.systemBlue,
                    .font: NSFont.systemFont(ofSize: 17, weight: .semibold)
                ]
            )
            text.insert(borderMarker, at: adjustedLocation)
            offset += 2
        }
        #endif
    }

    /// Remove quote block styling from the given text range
    /// - Parameters:
    ///   - text: The mutable attributed string to modify
    ///   - range: The range to remove quote styling from
    private func removeQuoteBlockStyling(from text: NSMutableAttributedString, range: NSRange) {
        // Remove border markers first (before resetting attributes)
        let paragraphRanges = getParagraphRanges(in: text, for: range)
        var offset = 0

        for paragraphRange in paragraphRanges.reversed() {
            let adjustedRange = NSRange(
                location: paragraphRange.location - offset,
                length: min(paragraphRange.length, text.length - (paragraphRange.location - offset))
            )

            if adjustedRange.location >= 0 && adjustedRange.location < text.length {
                let paragraphText = (text.string as NSString).substring(with: adjustedRange)
                if paragraphText.hasPrefix("┃ ") {
                    let markerRange = NSRange(location: adjustedRange.location, length: 2)
                    text.deleteCharacters(in: markerRange)
                    offset += 2
                }
            }
        }

        // Reset to default paragraph style and formatting
        let defaultParagraphStyle = NSMutableParagraphStyle()
        defaultParagraphStyle.headIndent = 0
        defaultParagraphStyle.firstLineHeadIndent = 0
        defaultParagraphStyle.tailIndent = 0

        // Recalculate range after marker deletion
        let adjustedRange = NSRange(
            location: range.location,
            length: min(range.length, text.length - range.location)
        )

        #if canImport(UIKit)
        // Get current font to preserve size
        let currentFont: UIFont
        if text.length > adjustedRange.location {
            currentFont = text.attribute(.font, at: adjustedRange.location, effectiveRange: nil) as? UIFont
                ?? UIFont.systemFont(ofSize: 17, weight: .regular)
        } else {
            currentFont = UIFont.systemFont(ofSize: 17, weight: .regular)
        }
        // Remove italic trait if present
        let regularFont = currentFont.removingSymbolicTraits(.traitItalic) ?? currentFont

        text.addAttributes([
            .paragraphStyle: defaultParagraphStyle,
            .backgroundColor: UIColor.clear,
            .foregroundColor: UIColor.label,
            .font: regularFont
        ], range: adjustedRange)
        #else
        // macOS version
        let currentFont: NSFont
        if text.length > adjustedRange.location {
            currentFont = text.attribute(.font, at: adjustedRange.location, effectiveRange: nil) as? NSFont
                ?? NSFont.systemFont(ofSize: 17, weight: .regular)
        } else {
            currentFont = NSFont.systemFont(ofSize: 17, weight: .regular)
        }
        // Remove italic trait if present
        let regularFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: .italicFontMask)

        text.addAttributes([
            .paragraphStyle: defaultParagraphStyle,
            .backgroundColor: NSColor.clear,
            .foregroundColor: NSColor.labelColor,
            .font: regularFont
        ], range: adjustedRange)
        #endif
    }

    /// Get individual paragraph ranges within a larger range
    /// - Parameters:
    ///   - text: The attributed string
    ///   - range: The overall range to search within
    /// - Returns: Array of paragraph ranges
    private func getParagraphRanges(in text: NSAttributedString, for range: NSRange) -> [NSRange] {
        var paragraphRanges: [NSRange] = []
        let string = text.string as NSString

        string.enumerateSubstrings(in: range, options: .byParagraphs) { _, paragraphRange, _, _ in
            paragraphRanges.append(paragraphRange)
        }

        return paragraphRanges
    }
}

// MARK: - Font Extensions

#if canImport(UIKit)
extension UIFont {
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
#else
extension NSFont {
    func with(traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
#endif

// MARK: - Previews
#Preview("With Content") {
    let store = DataStore.preview()

    if let book = try? store.fetchBooks().first,
       let chapter = book.chapters.first {
        ChapterEditorView(chapter: chapter, searchText: .constant(""), isZenModeEnabled: .constant(false))
            .modelContainer(store.modelContainer)
    }
}

#Preview("Empty Chapter") {
    let store = DataStore(inMemory: true)
    let chapter = Chapter(title: "Untitled Chapter", content: "")
    store.modelContainer.mainContext.insert(chapter)

    return ChapterEditorView(chapter: chapter, searchText: .constant(""), isZenModeEnabled: .constant(false))
        .modelContainer(store.modelContainer)
}
