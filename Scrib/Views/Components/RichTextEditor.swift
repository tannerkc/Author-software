//
//  RichTextEditor.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
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

            // Restore selection if valid
            if oldSelectedRange.location != NSNotFound &&
               oldSelectedRange.location <= textView.attributedText.length {
                textView.selectedRange = oldSelectedRange
            }

            // Only manage focus for text content changes (switching chapters)
            // Don't steal focus for formatting changes
            let textContentChanged = textView.attributedText.string != context.coordinator.lastKnownText
            if textContentChanged && isFocused.wrappedValue && !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
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

            // Report current text attributes at selection for format button states
            if let callback = parent.onAttributesChanged {
                let activeFormats = RichTextEditor.detectActiveFormats(
                    in: textView.attributedText,
                    at: textView.selectedRange
                )
                callback(activeFormats)
            }
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
