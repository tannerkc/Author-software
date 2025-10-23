//
//  FormatMenuSheet.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Format menu sheet replicating Apple Notes' Aa formatting panel
///
/// Provides comprehensive text formatting options in a clean, compact interface.
/// Designed to work with `.presentationBackgroundInteraction(.enabled)` for
/// seamless formatting while interacting with the text editor.
struct FormatMenuSheet: View {
    /// Dismiss environment
    @Environment(\.dismiss) private var dismiss

    /// Current text style selection
    @Binding var currentTextStyle: TextStyle

    /// Callback for format actions
    var onFormatAction: (TextFormat) -> Void

    /// Selected highlight color
    @State private var selectedHighlightColor: Color = .yellow

    /// Selected text color
    @State private var selectedTextColor: Color = .primary

    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - Header
    //            HStack {
    //                Text("Format")
    //                    .font(.headline)
    //                    .foregroundStyle(.primary)
    //
    //                Spacer()
    //
    //                Button {
    //                    dismiss()
    //                } label: {
    //                    Image(systemName: "xmark")
    //                        .font(.system(size: 16, weight: .semibold))
    //                        .foregroundStyle(.secondary)
    //                        .frame(width: 30, height: 30)
    //                        .background(Color(.systemGray5))
    //                        .clipShape(Circle())
    //                }
    //            }
    //            .padding(.horizontal, 20)
    //            .padding(.vertical, 16)
    //
    //            Divider()

                // MARK: - Text Styles (Horizontal Scroll)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(TextStyle.allCases) { style in
                            TextStyleLabel(
                                style: style,
                                isSelected: currentTextStyle == style,
                                action: {
                                    currentTextStyle = style
                                    onFormatAction(.style(style))
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .padding(.top, 20)
                }

//                Divider()

                // MARK: - Formatting Buttons
                VStack(spacing: 12) {
                    // Row 1: Character Formatting
                    HStack(spacing: 8) {
                        // Character formatting group
                        FormattingButtonGroup(buttons: [
                            .init(icon: "bold", action: { onFormatAction(.bold) }),
                            .init(icon: "italic", action: { onFormatAction(.italic) }),
                            .init(icon: "underline", action: { onFormatAction(.underline) }),
                            .init(icon: "strikethrough", action: { onFormatAction(.strikethrough) })
                        ])

                        // Standalone highlight button
                        StandaloneFormatButton(
                            icon: "highlighter",
                            action: { onFormatAction(.highlight(selectedHighlightColor)) }
                        )

                        // Standalone color button
                        StandaloneColorButton(
                            color: selectedTextColor,
                            action: { onFormatAction(.textColor(selectedTextColor)) }
                        )
                    }

                    // Row 2: Lists and Indentation
                    HStack(spacing: 8) {
                        // List formatting group
                        FormattingButtonGroup(buttons: [
                            .init(icon: "list.bullet", action: { onFormatAction(.bulletList) }),
                            .init(icon: "list.number", action: { onFormatAction(.numberedList) }),
                            .init(icon: "list.dash", action: { onFormatAction(.checklist) })
                        ])

                        // Indentation group
                        FormattingButtonGroup(buttons: [
                            .init(icon: "increase.indent", action: { onFormatAction(.indent) }),
                            .init(icon: "decrease.indent", action: { onFormatAction(.outdent) })
                        ])

                        // Standalone divider button
//                        StandaloneFormatButton(
//                            icon: "line.horizontal.3",
//                            action: { /* Separator/Divider action */ }
//                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .navigationTitle("Format")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
//                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Text Style Label

/// Text style button displaying the style it represents
private struct TextStyleLabel: View {
    let style: TextStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(style.displayName)
                .font(style.font)
                .fontWeight(style.weight)
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }
}

// MARK: - Formatting Button Group

/// Capsule-shaped group of formatting buttons
private struct FormattingButtonGroup: View {
    struct ButtonItem {
        let icon: String
        let action: () -> Void
    }

    let buttons: [ButtonItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(buttons.indices, id: \.self) { index in
                Button(action: buttons[index].action) {
                    Image(systemName: buttons[index].icon)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }

                if index < buttons.count - 1 {
                    Divider()
                        .frame(height: 24)
                }
            }
        }
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }
}

// MARK: - Standalone Format Buttons

/// Individual capsule button for formatting actions
private struct StandaloneFormatButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
        }
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }
}

/// Individual capsule button for color picker
private struct StandaloneColorButton: View {
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .frame(width: 44, height: 44)
        }
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview("Format Menu") {
    FormatMenuSheet(
        currentTextStyle: .constant(.body),
        onFormatAction: { format in
            print("Format action: \(format)")
        }
    )
    .presentationDetents([.height(280)])
}
