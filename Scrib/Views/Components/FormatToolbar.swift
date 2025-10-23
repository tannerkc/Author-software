//
//  FormatToolbar.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Format toolbar that replaces the keyboard - exact replica of iOS 26 Apple Notes
///
/// Three-row layout:
/// - Row 1: Text styles (Title, Heading, Subheading, Body, Monospaced)
/// - Row 2: Character formatting (Bold, Italic, Underline, Strikethrough)
/// - Row 3: Lists and indentation
struct FormatToolbar: View {
    /// Currently selected text style
    @Binding var selectedStyle: TextStyle

    /// Callback when format is applied
    var onApplyFormat: (TextFormat) -> Void

    /// Dismiss callback (hides toolbar, shows keyboard)
    var onDismiss: () -> Void

    /// Current formatting states
    @State private var isBold = false
    @State private var isItalic = false
    @State private var isUnderline = false
    @State private var isStrikethrough = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Row 1: Text Styles
            HStack(spacing: 8) {
                ForEach(TextStyle.allCases) { style in
                    Button {
                        selectedStyle = style
                        onApplyFormat(.style(style))
                    } label: {
                        Text(style.displayName)
                            .font(.subheadline)
                            .foregroundStyle(selectedStyle == style ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedStyle == style ? Color.blue : Color(.systemGray5))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // MARK: - Row 2: Character Formatting
            HStack(spacing: 12) {
                characterButton(
                    icon: "bold",
                    label: "B",
                    isActive: $isBold,
                    action: .bold
                )

                characterButton(
                    icon: "italic",
                    label: "I",
                    isActive: $isItalic,
                    action: .italic
                )

                characterButton(
                    icon: "underline",
                    label: "U",
                    isActive: $isUnderline,
                    action: .underline
                )

                characterButton(
                    icon: "strikethrough",
                    label: "S",
                    isActive: $isStrikethrough,
                    action: .strikethrough
                )

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // MARK: - Row 3: Lists and Indentation
            HStack(spacing: 12) {
                // Left side: Lists
                Button {
                    onApplyFormat(.bulletList)
                } label: {
                    Image(systemName: "list.bullet")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Button {
                    onApplyFormat(.numberedList)
                } label: {
                    Image(systemName: "list.number")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Button {
                    onApplyFormat(.checklist)
                } label: {
                    Image(systemName: "checklist")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                // Right side: Indentation
                Button {
                    onApplyFormat(.outdent)
                } label: {
                    Image(systemName: "decrease.indent")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Button {
                    onApplyFormat(.indent)
                } label: {
                    Image(systemName: "increase.indent")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(height: 170)
        .background(.regularMaterial)
    }

    // MARK: - Character Button

    @ViewBuilder
    private func characterButton(
        icon: String,
        label: String,
        isActive: Binding<Bool>,
        action: TextFormat
    ) -> some View {
        Button {
            isActive.wrappedValue.toggle()
            onApplyFormat(action)
        } label: {
            Text(label)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isActive.wrappedValue ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive.wrappedValue ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    VStack {
        Spacer()

        FormatToolbar(
            selectedStyle: .constant(.body),
            onApplyFormat: { format in
                print("Applied format: \(format)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}

#Preview("Dark Mode") {
    VStack {
        Spacer()

        FormatToolbar(
            selectedStyle: .constant(.heading),
            onApplyFormat: { _ in },
            onDismiss: { }
        )
    }
    .preferredColorScheme(.dark)
}
