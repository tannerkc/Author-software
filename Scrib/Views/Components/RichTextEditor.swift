//
//  RichTextEditor.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

/// Rich text editor supporting NSAttributedString formatting
///
/// Wraps UITextView to provide rich text editing capabilities that SwiftUI's
/// TextEditor doesn't support. Allows text styling (Title, Heading, Body) and
/// character formatting (bold, italic, underline) like Apple Notes.
struct RichTextEditor: UIViewRepresentable {
    /// The attributed text content
    @Binding var attributedText: NSAttributedString

    /// Current text selection range
    @Binding var selectedRange: NSRange

    /// Focus state binding
    var isFocused: FocusState<Bool>.Binding

    /// Whether the text view is editable (allows typing and keyboard)
    /// When false, users can still select text and move cursor
    var isEditable: Bool = true

    /// Whether to hide the keyboard using custom inputView
    /// When true, keyboard is hidden but text view remains fully interactive
    /// (cursor visible, can be moved, text can be selected)
    var shouldHideKeyboard: Bool = false

    /// Callback for reporting current text attributes at selection
    /// Called whenever the selection changes to update format button states
    var onAttributesChanged: ((Set<TextFormat>) -> Void)? = nil

    func makeUIView(context: Context) -> UITextView {
        // Return the coordinator's persistent text view instance
        // This ensures the same UITextView is reused across SwiftUI updates
        // makeUIView is only called ONCE when the view is first created
        return context.coordinator.textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Detect if attributed text changed (text content OR formatting attributes)
        // Uses NSAttributedString.isEqual which compares both text and attributes
        let attributedTextChanged = !textView.attributedText.isEqual(to: attributedText)

        // Update UITextView when:
        // 1. Attributed text changed (text or formatting)
        // 2. NOT from user typing (prevents circular updates)
        if attributedTextChanged && !context.coordinator.isUpdatingFromUser {
            let oldSelectedRange = textView.selectedRange
            textView.attributedText = attributedText
            context.coordinator.lastKnownText = attributedText.string

            // CRITICAL: Check if selectedRange binding was updated programmatically
            // If binding differs from old UITextView position, use binding value (cursor should move)
            // Otherwise, restore old position to keep cursor stable during external changes
            if selectedRange.location != oldSelectedRange.location ||
               selectedRange.length != oldSelectedRange.length {
                // Binding was updated programmatically - use new value
                // This allows cursor to move when list markers are inserted/deleted
                if selectedRange.location != NSNotFound &&
                   selectedRange.location <= textView.attributedText.length {
                    textView.selectedRange = selectedRange
                }
            } else {
                // No programmatic update - restore old position for stability
                // This keeps cursor in place during normal text/formatting changes
                if oldSelectedRange.location != NSNotFound &&
                   oldSelectedRange.location <= textView.attributedText.length {
                    textView.selectedRange = oldSelectedRange
                }
            }

            // Only manage focus for text content changes (switching chapters)
            // Don't steal focus for formatting changes
            let textContentChanged = textView.attributedText.string != context.coordinator.lastKnownText
            if textContentChanged && isFocused.wrappedValue && !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }

            // Update typing attributes to match current cursor position
            // This ensures formatting is preserved when user starts typing
            context.coordinator.updateTypingAttributes(textView)
        }

        // Update editability
        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }

        // CRITICAL: Use custom inputView to hide keyboard while keeping text view interactive
        // This is the iOS best practice for hiding keyboard without making view non-interactive
        if shouldHideKeyboard && textView.inputView == nil {
            // Hide keyboard by setting empty input view
            // Text view remains first responder, cursor visible, fully interactive
            textView.inputView = UIView() // Empty view = no keyboard
            textView.reloadInputViews()
        } else if !shouldHideKeyboard && textView.inputView != nil {
            // Restore keyboard by removing custom input view
            textView.inputView = nil
            textView.reloadInputViews()
        }

        // CRITICAL: Do NOT manage focus during normal typing
        // This was causing the keyboard to dismiss on every keystroke
        // Focus should only be managed during external changes (above)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isUpdatingFromUser = false

        /// Cache of the last text content we know about
        /// Used to prevent circular updates and detect genuine external changes
        var lastKnownText = ""

        /// Persistent UITextView instance (Malcolm Hall pattern)
        /// This ensures the same view is reused across SwiftUI updates
        lazy var textView: UITextView = {
            let tv = UITextView()
            tv.delegate = self

            // Appearance matching TextEditor
            tv.font = .systemFont(ofSize: 17)
            tv.backgroundColor = .systemBackground
            tv.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
            tv.textContainer.lineFragmentPadding = 0

            // Enable rich text features
            tv.allowsEditingTextAttributes = true
            tv.typingAttributes = defaultTypingAttributes()

            // Accessibility
            tv.isAccessibilityElement = true
            tv.accessibilityLabel = "Chapter content"

            return tv
        }()

        init(_ parent: RichTextEditor) {
            self.parent = parent
            // Initialize with current text to avoid false external change detection
            self.lastKnownText = parent.attributedText.string
        }

        /// Default typing attributes for body text
        private func defaultTypingAttributes() -> [NSAttributedString.Key: Any] {
            [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.label
            ]
        }

        func textViewDidChange(_ textView: UITextView) {
            // Cache the current text to prevent circular updates
            lastKnownText = textView.attributedText.string

            // Mark that we're updating from user input
            // This prevents updateUIView from overwriting the text
            isUpdatingFromUser = true

            // Update binding synchronously
            // The parent's .onChange will handle debounced saving
            parent.attributedText = textView.attributedText

            // Reset flag immediately after update
            // This is safe because updateUIView checks lastKnownText as well
            isUpdatingFromUser = false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Update selected range synchronously
            parent.selectedRange = textView.selectedRange

            // CRITICAL: Update typingAttributes to match formatting at cursor position
            // This ensures newly typed characters inherit the current formatting
            updateTypingAttributes(textView)

            // Report current text attributes at selection for format button states
            if let callback = parent.onAttributesChanged {
                let activeFormats = RichTextEditor.detectActiveFormats(
                    in: textView.attributedText,
                    at: textView.selectedRange
                )
                callback(activeFormats)
            }
        }

        /// Update UITextView's typingAttributes to match attributes at cursor position
        /// This ensures that newly typed characters inherit the current formatting
        private func updateTypingAttributes(_ textView: UITextView) {
            guard textView.attributedText.length > 0 else {
                // Empty text - use defaults
                textView.typingAttributes = defaultTypingAttributes()
                return
            }

            // Determine position to sample attributes from
            let sampleLocation: Int
            if textView.selectedRange.length > 0 {
                // Selection exists - sample from start of selection
                sampleLocation = textView.selectedRange.location
            } else if textView.selectedRange.location > 0 {
                // Cursor position - sample from character before cursor
                sampleLocation = textView.selectedRange.location - 1
            } else {
                // At the very beginning - sample from first character
                sampleLocation = 0
            }

            // Ensure valid location
            guard sampleLocation >= 0 && sampleLocation < textView.attributedText.length else {
                textView.typingAttributes = defaultTypingAttributes()
                return
            }

            // Get attributes at the sample location
            let attributes = textView.attributedText.attributes(at: sampleLocation, effectiveRange: nil)

            // Build typing attributes from current attributes
            // Start with defaults and override with current formatting
            var typingAttributes = defaultTypingAttributes()

            // Preserve font (includes bold, italic traits)
            if let font = attributes[.font] as? UIFont {
                typingAttributes[.font] = font
            }

            // Preserve text color
            if let foregroundColor = attributes[.foregroundColor] as? UIColor {
                typingAttributes[.foregroundColor] = foregroundColor
            }

            // Preserve highlight (background color)
            if let backgroundColor = attributes[.backgroundColor] as? UIColor,
               backgroundColor != .clear && backgroundColor.cgColor.alpha > 0 {
                typingAttributes[.backgroundColor] = backgroundColor
            }

            // Preserve underline
            if let underlineStyle = attributes[.underlineStyle] as? Int,
               underlineStyle > 0 {
                typingAttributes[.underlineStyle] = underlineStyle
            }

            // Preserve strikethrough
            if let strikethroughStyle = attributes[.strikethroughStyle] as? Int,
               strikethroughStyle > 0 {
                typingAttributes[.strikethroughStyle] = strikethroughStyle
            }

            // Preserve paragraph style (critical for quote blocks, lists, indentation)
            if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
                typingAttributes[.paragraphStyle] = paragraphStyle
            }

            // Update the text view's typing attributes
            textView.typingAttributes = typingAttributes
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            // Update focus state when editing begins
            parent.isFocused.wrappedValue = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            // Update focus state when editing ends
            parent.isFocused.wrappedValue = false
        }
    }
}

// MARK: - Text Formatting Helpers

extension RichTextEditor {
    /// Apply text style to attributed string at range
    static func applyTextStyle(_ style: TextStyle, to attributedText: NSMutableAttributedString, range: NSRange) {
        let font: UIFont

        switch style {
        case .title:
            font = .systemFont(ofSize: 28, weight: .bold)
        case .heading:
            font = .systemFont(ofSize: 22, weight: .bold)
        case .subheading:
            font = .systemFont(ofSize: 18, weight: .semibold)
        case .body:
            font = .systemFont(ofSize: 17, weight: .regular)
        case .monospaced:
            font = .monospacedSystemFont(ofSize: 17, weight: .regular)
        }

        attributedText.addAttribute(.font, value: font, range: range)
    }

    /// Apply character formatting (bold, italic, underline)
    static func applyCharacterFormat(_ format: TextFormat, to attributedText: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }

        switch format {
        case .bold:
            // Get current font and make it bold
            attributedText.enumerateAttribute(.font, in: range) { value, subrange, _ in
                if let currentFont = value as? UIFont {
                    let boldFont = currentFont.addingSymbolicTraits(.traitBold) ?? currentFont
                    attributedText.addAttribute(.font, value: boldFont, range: subrange)
                }
            }

        case .italic:
            attributedText.enumerateAttribute(.font, in: range) { value, subrange, _ in
                if let currentFont = value as? UIFont {
                    let italicFont = currentFont.addingSymbolicTraits(.traitItalic) ?? currentFont
                    attributedText.addAttribute(.font, value: italicFont, range: subrange)
                }
            }

        case .underline:
            attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)

        case .strikethrough:
            attributedText.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)

        case .highlight(let color):
            attributedText.addAttribute(.backgroundColor, value: UIColor(color), range: range)

        case .textColor(let color):
            attributedText.addAttribute(.foregroundColor, value: UIColor(color), range: range)

        default:
            break
        }
    }

    /// Remove character formatting (toggle off)
    static func removeCharacterFormat(_ format: TextFormat, from attributedText: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }

        switch format {
        case .bold:
            // Remove bold trait from font
            attributedText.enumerateAttribute(.font, in: range) { value, subrange, _ in
                if let currentFont = value as? UIFont {
                    let regularFont = currentFont.removingSymbolicTraits(.traitBold) ?? currentFont
                    attributedText.addAttribute(.font, value: regularFont, range: subrange)
                }
            }

        case .italic:
            attributedText.enumerateAttribute(.font, in: range) { value, subrange, _ in
                if let currentFont = value as? UIFont {
                    let regularFont = currentFont.removingSymbolicTraits(.traitItalic) ?? currentFont
                    attributedText.addAttribute(.font, value: regularFont, range: subrange)
                }
            }

        case .underline:
            attributedText.removeAttribute(.underlineStyle, range: range)

        case .strikethrough:
            attributedText.removeAttribute(.strikethroughStyle, range: range)

        case .highlight:
            attributedText.removeAttribute(.backgroundColor, range: range)

        case .textColor:
            // Reset to default label color
            attributedText.addAttribute(.foregroundColor, value: UIColor.label, range: range)

        default:
            break
        }
    }

    /// Get the range of the current paragraph (line) containing the cursor
    static func paragraphRange(for selectedRange: NSRange, in text: NSAttributedString) -> NSRange {
        let string = text.string as NSString
        return string.paragraphRange(for: selectedRange)
    }

    /// Apply indentation to the specified range (increase indent level)
    /// - Parameters:
    ///   - attributedText: The mutable attributed string to modify
    ///   - range: The range to apply indentation (should be paragraph range)
    ///   - indentIncrement: The amount to increase indent (default: 20pt, matching Apple Notes)
    static func applyIndent(to attributedText: NSMutableAttributedString, range: NSRange, indentIncrement: CGFloat = 20) {
        guard range.location != NSNotFound && range.length > 0 else { return }

        // Get or create paragraph style
        let existingStyle = attributedText.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
        let paragraphStyle = (existingStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()

        // Increase indentation
        paragraphStyle.firstLineHeadIndent += indentIncrement
        paragraphStyle.headIndent += indentIncrement

        // Apply the updated paragraph style
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    /// Remove indentation from the specified range (decrease indent level)
    /// - Parameters:
    ///   - attributedText: The mutable attributed string to modify
    ///   - range: The range to remove indentation from (should be paragraph range)
    ///   - indentDecrement: The amount to decrease indent (default: 20pt, matching Apple Notes)
    static func applyOutdent(to attributedText: NSMutableAttributedString, range: NSRange, indentDecrement: CGFloat = 20) {
        guard range.location != NSNotFound && range.length > 0 else { return }

        // Get existing paragraph style
        let existingStyle = attributedText.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
        let paragraphStyle = (existingStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()

        // Decrease indentation (but don't go below 0)
        paragraphStyle.firstLineHeadIndent = max(0, paragraphStyle.firstLineHeadIndent - indentDecrement)
        paragraphStyle.headIndent = max(0, paragraphStyle.headIndent - indentDecrement)

        // Apply the updated paragraph style
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    /// Detect which text formats are currently active at the given selection
    /// Returns a set of active formats (bold, italic, underline, etc.)
    static func detectActiveFormats(in attributedText: NSAttributedString, at range: NSRange) -> Set<TextFormat> {
        var activeFormats = Set<TextFormat>()

        // Handle empty text
        guard attributedText.length > 0 else {
            return activeFormats
        }

        // Determine the position to check attributes
        // For a selection, check the start; for a cursor, check the character before
        let checkLocation: Int
        if range.length > 0 {
            // Selection: check attributes at the start of selection
            checkLocation = range.location
        } else if range.location > 0 {
            // Cursor: check attributes of character before cursor
            checkLocation = range.location - 1
        } else {
            // At the very beginning
            checkLocation = 0
        }

        // Ensure valid location
        guard checkLocation >= 0 && checkLocation < attributedText.length else {
            return activeFormats
        }

        // Get attributes at the location
        let attributes = attributedText.attributes(at: checkLocation, effectiveRange: nil)

        // Check for font traits (bold, italic)
        if let font = attributes[.font] as? UIFont {
            let traits = font.fontDescriptor.symbolicTraits

            if traits.contains(.traitBold) {
                activeFormats.insert(.bold)
            }

            if traits.contains(.traitItalic) {
                activeFormats.insert(.italic)
            }
        }

        // Check for underline
        if let underlineStyle = attributes[.underlineStyle] as? Int,
           underlineStyle > 0 {
            activeFormats.insert(.underline)
        }

        // Check for strikethrough
        if let strikethroughStyle = attributes[.strikethroughStyle] as? Int,
           strikethroughStyle > 0 {
            activeFormats.insert(.strikethrough)
        }

        // Check for background color (highlight)
        if let backgroundColor = attributes[.backgroundColor] as? UIColor,
           backgroundColor != .clear && backgroundColor.cgColor.alpha > 0 {
            activeFormats.insert(.highlight(Color(backgroundColor)))
        }

        // Check for text color
        if let foregroundColor = attributes[.foregroundColor] as? UIColor,
           foregroundColor != .label {
            activeFormats.insert(.textColor(Color(foregroundColor)))
        }

        // Check for list formatting by examining the current paragraph
        let paragraphRange = paragraphRange(for: range, in: attributedText)
        if paragraphRange.location != NSNotFound && paragraphRange.length > 0 {
            let paragraphText = (attributedText.string as NSString).substring(with: paragraphRange)

            // Detect bullet list: starts with "• "
            if paragraphText.hasPrefix("• ") {
                activeFormats.insert(.bulletList)
            }
            // Detect numbered list: starts with number pattern like "1. ", "2. ", etc.
            else if paragraphText.range(of: "^\\d+\\.\\s", options: .regularExpression) != nil {
                activeFormats.insert(.numberedList)
            }
            // Detect checklist: starts with "☐ " or "☑ "
            else if paragraphText.hasPrefix("☐ ") || paragraphText.hasPrefix("☑ ") {
                activeFormats.insert(.checklist)
            }
        }

        return activeFormats
    }
}

// MARK: - UIFont Extension

extension UIFont {
    func addingSymbolicTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        var symbolicTraits = fontDescriptor.symbolicTraits
        symbolicTraits.insert(traits)

        guard let descriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) else {
            return nil
        }

        return UIFont(descriptor: descriptor, size: pointSize)
    }

    func removingSymbolicTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        var symbolicTraits = fontDescriptor.symbolicTraits
        symbolicTraits.remove(traits)

        guard let descriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) else {
            return nil
        }

        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

// MARK: - Previews

#Preview {
    struct PreviewWrapper: View {
        @State private var attributedText = NSAttributedString(string: "Sample chapter content")
        @State private var selectedRange = NSRange(location: 0, length: 0)
        @FocusState private var isFocused: Bool

        var body: some View {
            RichTextEditor(
                attributedText: $attributedText,
                selectedRange: $selectedRange,
                isFocused: $isFocused
            )
        }
    }

    return PreviewWrapper()
}

#elseif canImport(AppKit)

/// macOS RichTextEditor stub using NSTextView
///
/// TODO: Implement full macOS rich text editing with NSTextView
struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    var isFocused: FocusState<Bool>.Binding
    var isEditable: Bool = true
    var shouldHideKeyboard: Bool = false
    var onAttributesChanged: ((Set<TextFormat>) -> Void)? = nil
    var textDidChange: ((NSAttributedString) -> Void)?
    var selectionDidChange: ((NSRange) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()

        // Safe unwrap to prevent crash if documentView is not NSTextView
        guard let textView = scrollView.documentView as? NSTextView else {
            print("⚠️ CRITICAL: NSTextView.scrollableTextView() did not return NSTextView as documentView")
            // Return the scroll view anyway, updateNSView will handle it
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.isEditable = isEditable
        textView.isRichText = true

        // Set text container inset for padding (matches iOS version)
        textView.textContainerInset = NSSize(width: 20, height: 12)

        // CRITICAL: Safe attributed text setting with validation
        // Prevents crashes when attributedText is invalid or empty
        if let textStorage = textView.textStorage {
            // Validate attributed text before setting
            if attributedText.length > 0 {
                textStorage.setAttributedString(attributedText)
            } else {
                // CRITICAL: NSColor MUST be accessed on main thread
                // Check if we're on main thread, dispatch sync if not
                let setDefaultText = {
                    let defaultFont = NSFont.systemFont(ofSize: 17)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: defaultFont,
                        .foregroundColor: NSColor.labelColor
                    ]
                    textStorage.setAttributedString(NSAttributedString(string: "", attributes: attributes))
                }

                if Thread.isMainThread {
                    setDefaultText()
                } else {
                    DispatchQueue.main.sync {
                        setDefaultText()
                    }
                }
            }
        } else {
            print("⚠️ WARNING: NSTextView textStorage is nil during initialization")
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // CRITICAL: Update coordinator's parent reference to prevent stale struct references
        // The parent struct is recreated on every SwiftUI update, but coordinator persists
        context.coordinator.parent = self

        // CRITICAL: Safe attributed text update with validation
        // Prevents crashes when attributedText is invalid or when textStorage is nil
        guard let textStorage = textView.textStorage else {
            print("⚠️ WARNING: NSTextView textStorage is nil during update")
            return
        }

        // CRITICAL: Prevent infinite recursion by checking isUpdatingFromUser flag
        // When textDidChange is updating the binding, we must NOT update the textStorage
        // This breaks the circular update cycle that causes stack overflow
        if !context.coordinator.isUpdatingFromUser {
            // Check if this is genuinely new attributed text that we haven't set yet
            // We track lastSetAttributedString because NSTextView can slightly modify
            // attributed strings when they're set (normalizing attributes, etc.)
            let shouldUpdate = context.coordinator.lastSetAttributedString == nil ||
                              !attributedText.isEqual(to: context.coordinator.lastSetAttributedString!)

            if shouldUpdate {
                // Validate attributed text before setting
                if attributedText.length >= 0 {
                    textStorage.setAttributedString(attributedText)
                    // Track what we set to prevent re-setting the same content
                    context.coordinator.lastSetAttributedString = attributedText

                    // Update typing attributes to match current cursor position
                    // This ensures formatting is preserved when user starts typing
                    Task { @MainActor in
                        context.coordinator.updateTypingAttributes(textView)
                    }
                } else {
                    print("⚠️ WARNING: Invalid attributed text length, skipping update")
                }
            }
        }

        textView.isEditable = isEditable
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor

        /// Flag to prevent circular updates between textDidChange and updateNSView
        /// When true, updateNSView will skip text updates to break the recursion cycle
        var isUpdatingFromUser = false

        /// Track the last attributed string we set to prevent unnecessary updates
        /// NSTextView can slightly modify attributed strings, so we track what we actually set
        var lastSetAttributedString: NSAttributedString?

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // CRITICAL: Set flag to prevent infinite recursion
            // This prevents updateNSView from updating textStorage while we're updating the binding
            isUpdatingFromUser = true
            parent.attributedText = textView.attributedString()
            parent.textDidChange?(textView.attributedString())
            isUpdatingFromUser = false
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.selectedRange = textView.selectedRange()
            parent.selectionDidChange?(textView.selectedRange())

            // CRITICAL: Update typingAttributes to match formatting at cursor position
            // This ensures newly typed characters inherit the current formatting
            updateTypingAttributes(textView)
        }

        /// Update NSTextView's typingAttributes to match attributes at cursor position
        /// This ensures that newly typed characters inherit the current formatting
        @MainActor
        func updateTypingAttributes(_ textView: NSTextView) {
            guard let textStorage = textView.textStorage,
                  textStorage.length > 0 else {
                // Empty text - use defaults
                textView.typingAttributes = defaultTypingAttributes()
                return
            }

            // Determine position to sample attributes from
            let sampleLocation: Int
            let selectedRange = textView.selectedRange()
            if selectedRange.length > 0 {
                // Selection exists - sample from start of selection
                sampleLocation = selectedRange.location
            } else if selectedRange.location > 0 {
                // Cursor position - sample from character before cursor
                sampleLocation = selectedRange.location - 1
            } else {
                // At the very beginning - sample from first character
                sampleLocation = 0
            }

            // Ensure valid location
            guard sampleLocation >= 0 && sampleLocation < textStorage.length else {
                textView.typingAttributes = defaultTypingAttributes()
                return
            }

            // Get attributes at the sample location
            let attributes = textStorage.attributes(at: sampleLocation, effectiveRange: nil)

            // Build typing attributes from current attributes
            // Start with defaults and override with current formatting
            var typingAttributes = defaultTypingAttributes()

            // Preserve font (includes bold, italic traits)
            if let font = attributes[.font] as? NSFont {
                typingAttributes[.font] = font
            }

            // Preserve text color
            if let foregroundColor = attributes[.foregroundColor] as? NSColor {
                typingAttributes[.foregroundColor] = foregroundColor
            }

            // Preserve highlight (background color)
            if let backgroundColor = attributes[.backgroundColor] as? NSColor,
               backgroundColor != .clear && backgroundColor.alphaComponent > 0 {
                typingAttributes[.backgroundColor] = backgroundColor
            }

            // Preserve underline
            if let underlineStyle = attributes[.underlineStyle] as? Int,
               underlineStyle > 0 {
                typingAttributes[.underlineStyle] = underlineStyle
            }

            // Preserve strikethrough
            if let strikethroughStyle = attributes[.strikethroughStyle] as? Int,
               strikethroughStyle > 0 {
                typingAttributes[.strikethroughStyle] = strikethroughStyle
            }

            // Preserve paragraph style (critical for quote blocks, lists, indentation)
            if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
                typingAttributes[.paragraphStyle] = paragraphStyle
            }

            // Update the text view's typing attributes
            textView.typingAttributes = typingAttributes
        }

        /// Default typing attributes for body text
        private func defaultTypingAttributes() -> [NSAttributedString.Key: Any] {
            [
                .font: NSFont.systemFont(ofSize: 17),
                .foregroundColor: NSColor.labelColor
            ]
        }
    }

    // Static helper methods (stubs for macOS)
    static func detectActiveFormats(in attributedText: NSAttributedString, at range: NSRange) -> Set<TextFormat> {
        var activeFormats = Set<TextFormat>()

        // Handle empty text
        guard attributedText.length > 0 else {
            return activeFormats
        }

        // Determine the position to check attributes
        // For a selection, check the start; for a cursor, check the character before
        let checkLocation: Int
        if range.length > 0 {
            // Selection: check attributes at the start of selection
            checkLocation = range.location
        } else if range.location > 0 {
            // Cursor: check attributes of character before cursor
            checkLocation = range.location - 1
        } else {
            // At the very beginning
            checkLocation = 0
        }

        // Ensure valid location
        guard checkLocation >= 0 && checkLocation < attributedText.length else {
            return activeFormats
        }

        // Get attributes at the location
        let attributes = attributedText.attributes(at: checkLocation, effectiveRange: nil)

        // Check for font traits (bold, italic)
        if let font = attributes[.font] as? NSFont {
            let traits = font.fontDescriptor.symbolicTraits

            if traits.contains(.bold) {
                activeFormats.insert(.bold)
            }

            if traits.contains(.italic) {
                activeFormats.insert(.italic)
            }
        }

        // Check for underline
        if let underlineStyle = attributes[.underlineStyle] as? Int,
           underlineStyle > 0 {
            activeFormats.insert(.underline)
        }

        // Check for strikethrough
        if let strikethroughStyle = attributes[.strikethroughStyle] as? Int,
           strikethroughStyle > 0 {
            activeFormats.insert(.strikethrough)
        }

        // Check for background color (highlight)
        if let backgroundColor = attributes[.backgroundColor] as? NSColor,
           backgroundColor != .clear && backgroundColor.alphaComponent > 0 {
            activeFormats.insert(.highlight(Color(nsColor: backgroundColor)))
        }

        // Check for text color
        if let foregroundColor = attributes[.foregroundColor] as? NSColor,
           foregroundColor != .labelColor {
            activeFormats.insert(.textColor(Color(nsColor: foregroundColor)))
        }

        // Check for list formatting by examining the current paragraph
        let paragraphRange = paragraphRange(for: range, in: attributedText)
        if paragraphRange.location != NSNotFound && paragraphRange.length > 0 {
            let paragraphText = (attributedText.string as NSString).substring(with: paragraphRange)

            // Detect bullet list: starts with "• "
            if paragraphText.hasPrefix("• ") {
                activeFormats.insert(.bulletList)
            }
            // Detect numbered list: starts with number pattern like "1. ", "2. ", etc.
            else if paragraphText.range(of: "^\\d+\\.\\s", options: .regularExpression) != nil {
                activeFormats.insert(.numberedList)
            }
            // Detect checklist: starts with "☐ " or "☑ "
            else if paragraphText.hasPrefix("☐ ") || paragraphText.hasPrefix("☑ ") {
                activeFormats.insert(.checklist)
            }
        }

        return activeFormats
    }

    static func paragraphRange(for selectedRange: NSRange, in text: NSAttributedString) -> NSRange {
        let string = text.string as NSString
        return string.paragraphRange(for: selectedRange)
    }

    static func applyTextStyle(_ style: TextStyle, to attributedText: NSMutableAttributedString, range: NSRange) {
        let font: NSFont

        switch style {
        case .title:
            font = .systemFont(ofSize: 28, weight: .bold)
        case .heading:
            font = .systemFont(ofSize: 22, weight: .bold)
        case .subheading:
            font = .systemFont(ofSize: 18, weight: .semibold)
        case .body:
            font = .systemFont(ofSize: 17, weight: .regular)
        case .monospaced:
            font = .monospacedSystemFont(ofSize: 17, weight: .regular)
        }

        attributedText.addAttribute(.font, value: font, range: range)
    }

    static func removeCharacterFormat(_ format: TextFormat, from attributedText: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }

        switch format {
        case .bold:
            // Remove bold trait from font
            attributedText.enumerateAttribute(.font, in: range) { value, subrange, _ in
                if let currentFont = value as? NSFont {
                    let regularFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: .boldFontMask)
                    attributedText.addAttribute(.font, value: regularFont, range: subrange)
                }
            }

        case .italic:
            attributedText.enumerateAttribute(.font, in: range) { value, subrange, _ in
                if let currentFont = value as? NSFont {
                    let regularFont = NSFontManager.shared.convert(currentFont, toNotHaveTrait: .italicFontMask)
                    attributedText.addAttribute(.font, value: regularFont, range: subrange)
                }
            }

        case .underline:
            attributedText.removeAttribute(.underlineStyle, range: range)

        case .strikethrough:
            attributedText.removeAttribute(.strikethroughStyle, range: range)

        case .highlight:
            attributedText.removeAttribute(.backgroundColor, range: range)

        case .textColor:
            // Reset to default label color
            attributedText.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)

        default:
            break
        }
    }

    static func applyCharacterFormat(_ format: TextFormat, to attributedText: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }

        switch format {
        case .bold:
            // Get current font and make it bold
            attributedText.enumerateAttribute(.font, in: range) { value, subrange, _ in
                if let currentFont = value as? NSFont {
                    let boldFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .boldFontMask)
                    attributedText.addAttribute(.font, value: boldFont, range: subrange)
                }
            }

        case .italic:
            attributedText.enumerateAttribute(.font, in: range) { value, subrange, _ in
                if let currentFont = value as? NSFont {
                    let italicFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
                    attributedText.addAttribute(.font, value: italicFont, range: subrange)
                }
            }

        case .underline:
            attributedText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)

        case .strikethrough:
            attributedText.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)

        case .highlight(let color):
            attributedText.addAttribute(.backgroundColor, value: NSColor(color), range: range)

        case .textColor(let color):
            attributedText.addAttribute(.foregroundColor, value: NSColor(color), range: range)

        default:
            break
        }
    }

    static func applyIndent(to attributedText: NSMutableAttributedString, range: NSRange, indentIncrement: CGFloat = 20) {
        // Stub implementation for macOS
        // TODO: Implement proper indentation using NSParagraphStyle
    }

    static func applyOutdent(to attributedText: NSMutableAttributedString, range: NSRange, indentDecrement: CGFloat = 20) {
        // Stub implementation for macOS
        // TODO: Implement proper outdentation using NSParagraphStyle
    }
}

#endif // canImport(UIKit) or canImport(AppKit)
