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

    func makeUIView(context: Context) -> UITextView {
        // Return the coordinator's persistent text view instance
        // This ensures the same UITextView is reused across SwiftUI updates
        // makeUIView is only called ONCE when the view is first created
        return context.coordinator.textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // CRITICAL: Update coordinator's parent reference to maintain fresh bindings
        // This ensures the coordinator always has access to the current binding values
        context.coordinator.parent = self

        // Only update text if it changed externally (not from user typing)
        // Compare string content to avoid unnecessary UITextView updates
        let textChanged = textView.attributedText.string != attributedText.string

        if textChanged && !context.coordinator.isUpdatingFromUser {
            let oldSelectedRange = textView.selectedRange
            textView.attributedText = attributedText

            // Restore selection if valid
            if oldSelectedRange.location != NSNotFound &&
               oldSelectedRange.location <= textView.attributedText.length {
                textView.selectedRange = oldSelectedRange
            }
        }

        // Update editability
        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }

        // Update focus state
        if isFocused.wrappedValue && !textView.isFirstResponder {
            textView.becomeFirstResponder()
        } else if !isFocused.wrappedValue && textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isUpdatingFromUser = false

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
        }

        /// Default typing attributes for body text
        private func defaultTypingAttributes() -> [NSAttributedString.Key: Any] {
            [
                .font: UIFont.systemFont(ofSize: 17),
                .foregroundColor: UIColor.label
            ]
        }

        func textViewDidChange(_ textView: UITextView) {
            // Flag to prevent updateUIView from interfering during user typing
            isUpdatingFromUser = true

            // Use asynchronous state updates (Chris Eidhof pattern)
            // This prevents "modifying state during view update" warnings
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Update binding only - parent will handle save via .onChange modifier
                self.parent.attributedText = textView.attributedText

                // Reset flag after update cycle completes
                self.isUpdatingFromUser = false
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Update selected range asynchronously
            DispatchQueue.main.async { [weak self] in
                self?.parent.selectedRange = textView.selectedRange
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.isFocused.wrappedValue = true
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.isFocused.wrappedValue = false
            }
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

    /// Get the range of the current paragraph (line) containing the cursor
    static func paragraphRange(for selectedRange: NSRange, in text: NSAttributedString) -> NSRange {
        let string = text.string as NSString
        return string.paragraphRange(for: selectedRange)
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
