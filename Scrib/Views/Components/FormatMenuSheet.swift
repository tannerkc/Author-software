//
//  FormatMenuSheet.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

#if os(iOS)

/// Navigation destinations for the format menu
enum FormatDestination: Hashable {
    case highlightColorPicker
    case textColorPicker
}

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

    /// Currently active formats at the cursor/selection (for button states)
    let activeFormats: Set<TextFormat>

    /// Callback for format actions
    var onFormatAction: (TextFormat) -> Void

    /// Navigation path for push navigation within sheet
    @State private var navigationPath = NavigationPath()

    /// Selected highlight color
    @State private var selectedHighlightColor: Color = .yellow

    /// Selected text color
    @State private var selectedTextColor: Color = .primary

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
    //                        .background(Color.secondarySystemFill)
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
                            .init(
                                icon: "bold",
                                action: { onFormatAction(.bold) },
                                isActive: isFormatActive(.bold)
                            ),
                            .init(
                                icon: "italic",
                                action: { onFormatAction(.italic) },
                                isActive: isFormatActive(.italic)
                            ),
                            .init(
                                icon: "underline",
                                action: { onFormatAction(.underline) },
                                isActive: isFormatActive(.underline)
                            ),
                            .init(
                                icon: "strikethrough",
                                action: { onFormatAction(.strikethrough) },
                                isActive: isFormatActive(.strikethrough)
                            )
                        ])

                        // Standalone highlight button with navigation to color picker
                        NavigationLink(value: FormatDestination.highlightColorPicker) {
                            let isHighlightActive = activeFormats.contains(where: { if case .highlight = $0 { return true }; return false })
                            Image(systemName: "highlighter")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(isHighlightActive ? Color.accentColor : .primary)
                                .frame(width: 44, height: 44)
                        }
                        .background(
                            activeFormats.contains(where: { if case .highlight = $0 { return true }; return false })
                                ? Color.accentColor.opacity(0.15)
                                : Color.secondarySystemFill
                        )
                        .clipShape(Capsule())

                        // Standalone color button with navigation to color picker
                        NavigationLink(value: FormatDestination.textColorPicker) {
                            Circle()
                                .fill(selectedTextColor)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .strokeBorder(activeFormats.contains(where: { if case .textColor = $0 { return true }; return false }) ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                .frame(width: 44, height: 44)
                        }
                        .background(activeFormats.contains(where: { if case .textColor = $0 { return true }; return false }) ? Color.accentColor.opacity(0.15) : Color(.systemGray5))
                        .clipShape(Capsule())
                    }

                    // Row 2: Lists and Indentation
                    HStack(spacing: 8) {
                        // List formatting group
                        FormattingButtonGroup(buttons: [
                            .init(
                                icon: "list.bullet",
                                action: { onFormatAction(.bulletList) },
                                isActive: isFormatActive(.bulletList)
                            ),
                            .init(
                                icon: "list.number",
                                action: { onFormatAction(.numberedList) },
                                isActive: isFormatActive(.numberedList)
                            ),
                            .init(
                                icon: "list.dash",
                                action: { onFormatAction(.checklist) },
                                isActive: isFormatActive(.checklist)
                            )
                        ])

                        // Indentation group
                        FormattingButtonGroup(buttons: [
                            .init(
                                icon: "increase.indent",
                                action: { onFormatAction(.indent) },
                                isActive: false
                            ),
                            .init(
                                icon: "decrease.indent",
                                action: { onFormatAction(.outdent) },
                                isActive: false
                            )
                        ])
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .navigationTitle("Format")
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .navigationDestination(for: FormatDestination.self) { destination in
                switch destination {
                case .highlightColorPicker:
                    ColorPickerView(
                        selectedColor: $selectedHighlightColor,
                        title: "Highlight Color"
                    ) { color in
                        onFormatAction(.highlight(color))
                        navigationPath.removeLast()
                    }
                case .textColorPicker:
                    ColorPickerView(
                        selectedColor: $selectedTextColor,
                        title: "Text Color"
                    ) { color in
                        onFormatAction(.textColor(color))
                        navigationPath.removeLast()
                    }
                }
            }
        }
        .background(Color.systemBackground)
    }

    // MARK: - Helper Methods

    /// Check if a specific format is currently active
    private func isFormatActive(_ format: TextFormat) -> Bool {
        activeFormats.contains(format)
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
        let isActive: Bool
    }

    let buttons: [ButtonItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(buttons.indices, id: \.self) { index in
                Button(action: buttons[index].action) {
                    Image(systemName: buttons[index].icon)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(buttons[index].isActive ? Color.accentColor : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .background(
                    buttons[index].isActive
                        ? Color.accentColor.opacity(0.15)
                        : Color.clear
                )

                if index < buttons.count - 1 {
                    Divider()
                        .frame(height: 24)
                }
            }
        }
        .background(Color.secondarySystemFill)
        .clipShape(Capsule())
    }
}

// MARK: - Color Picker View

/// Full-screen color picker view for push navigation
/// Follows iOS 26 design patterns with instant application
private struct ColorPickerView: View {
    @Binding var selectedColor: Color
    let title: String
    let onColorSelected: (Color) -> Void

    /// Common colors for quick selection (Apple Notes style)
    private let quickColors: [Color] = [
        .yellow, .orange, .red, .pink, .purple,
        .blue, .cyan, .mint, .green,
        .gray, .brown, .black
    ]

    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Quick Color Palette
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
                spacing: 12
            ) {
                ForEach(quickColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    selectedColor == color ? Color.accentColor : Color.clear,
                                    lineWidth: 3
                                )
                        )
                        .onTapGesture {
                            selectedColor = color
                            onColorSelected(color)
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .frame(maxHeight: .infinity)
        .navigationTitle(title)
        .adaptiveNavigationBarTitleDisplayMode(.inline)
        .background(Color.systemBackground)
    }
}

// MARK: - Previews

#Preview("Format Menu") {
    FormatMenuSheet(
        currentTextStyle: .constant(.body),
        activeFormats: [],
        onFormatAction: { format in
            print("Format action: \(format)")
        }
    )
    .presentationDetents([.height(280)])
}

#endif // os(iOS)
