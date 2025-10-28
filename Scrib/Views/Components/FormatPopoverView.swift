//
//  FormatPopoverView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Format popover matching Apple Notes design
///
/// Displays interactive formatting buttons and text style options
/// in a popover, mimicking the exact layout of Apple Notes' format menu.
struct FormatPopoverView: View {
    /// Current text style selection
    @Binding var currentTextStyle: TextStyle

    /// Currently active formats at the cursor/selection
    let activeFormats: Set<TextFormat>

    /// Callback for format actions
    var onFormatAction: (TextFormat) -> Void

    /// State for color picker sheets
    @State private var showingTextColorPicker = false
    @State private var showingHighlightPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Formatting Buttons Row
            HStack(spacing: 12) {
                // Bold
                FormatToggleButton(
                    icon: "bold",
                    isActive: activeFormats.contains(.bold)
                ) {
                    onFormatAction(.bold)
                }

                // Italic
                FormatToggleButton(
                    icon: "italic",
                    isActive: activeFormats.contains(.italic)
                ) {
                    onFormatAction(.italic)
                }

                // Underline
                FormatToggleButton(
                    icon: "underline",
                    isActive: activeFormats.contains(.underline)
                ) {
                    onFormatAction(.underline)
                }

                // Strikethrough
                FormatToggleButton(
                    icon: "strikethrough",
                    isActive: activeFormats.contains(.strikethrough)
                ) {
                    onFormatAction(.strikethrough)
                }

                // Highlighter
                Button {
                    showingHighlightPicker.toggle()
                } label: {
                    Image(systemName: "highlighter")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(isHighlightActive ? Color.accentColor : .primary)
                        .frame(width: 32, height: 32)
                        .background(isHighlightActive ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingHighlightPicker) {
                    ColorPickerPopover(title: "Highlight Color") { color in
                        onFormatAction(.highlight(color))
                    }
                }

                // Text Color
                Button {
                    showingTextColorPicker.toggle()
                } label: {
                    Circle()
                        .fill(getCurrentTextColor())
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingTextColorPicker) {
                    ColorPickerPopover(title: "Text Color") { color in
                        onFormatAction(.textColor(color))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            #if os(macOS)
            // MARK: - Text Alignment Section (macOS only)
            HStack(spacing: 12) {
                // Left Align
                FormatToggleButton(
                    icon: "text.alignleft",
                    isActive: activeFormats.contains(.alignLeft)
                ) {
                    onFormatAction(.alignLeft)
                }

                // Center Align
                FormatToggleButton(
                    icon: "text.aligncenter",
                    isActive: activeFormats.contains(.alignCenter)
                ) {
                    onFormatAction(.alignCenter)
                }

                // Right Align
                FormatToggleButton(
                    icon: "text.alignright",
                    isActive: activeFormats.contains(.alignRight)
                ) {
                    onFormatAction(.alignRight)
                }

                // Justified
                FormatToggleButton(
                    icon: "text.justify",
                    isActive: activeFormats.contains(.alignJustified)
                ) {
                    onFormatAction(.alignJustified)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
            #endif

            // MARK: - Text Styles Section
            VStack(alignment: .leading, spacing: 0) {
                ForEach(TextStyle.allCases) { style in
                    Button {
                        currentTextStyle = style
                        onFormatAction(.style(style))
                    } label: {
                        HStack {
                            Text(style.displayName)
                                .font(previewFont(for: style))
                                .foregroundStyle(.primary)
                            Spacer()
                            if currentTextStyle == style {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // MARK: - List Formatting Section
            VStack(alignment: .leading, spacing: 0) {
                // Bulleted List
                ListFormatButton(
                    icon: "•",
                    title: "Bulleted List",
                    isActive: activeFormats.contains(.bulletList)
                ) {
                    onFormatAction(.bulletList)
                }

                // Dashed List
                ListFormatButton(
                    icon: "–",
                    title: "Dashed List",
                    isActive: false // Not implemented yet
                ) {
                    // TODO: Implement dashed list
                }

                // Numbered List
                ListFormatButton(
                    icon: "1.",
                    title: "Numbered List",
                    isActive: activeFormats.contains(.numberedList)
                ) {
                    onFormatAction(.numberedList)
                }
            }

            Divider()

            // MARK: - Block Quote
            Button {
                // Block quote is handled differently - it's a paragraph style
                // For now, just close the popover
            } label: {
                HStack {
                    Text("|")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.blue)
                    Text("Block Quote")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 280)
        .background(.background)
    }

    // MARK: - Helper Properties

    private var isHighlightActive: Bool {
        activeFormats.contains(where: { if case .highlight = $0 { return true }; return false })
    }

    private func getCurrentTextColor() -> Color {
        if let textColorFormat = activeFormats.first(where: { if case .textColor = $0 { return true }; return false }),
           case .textColor(let color) = textColorFormat {
            return color
        }
        return .primary
    }

    private func previewFont(for style: TextStyle) -> Font {
        switch style {
        case .title: return .title
        case .heading: return .title3
        case .subheading: return .headline
        case .body: return .body
        case .monospaced: return .body.monospaced()
        }
    }
}

// MARK: - Format Toggle Button

struct FormatToggleButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(isActive ? Color.accentColor : .primary)
                .frame(width: 32, height: 32)
                .background(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - List Format Button

struct ListFormatButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: 20, alignment: .leading)
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Picker Popover

struct ColorPickerPopover: View {
    let title: String
    let onSelect: (Color) -> Void

    let colors: [Color] = [
        .black, .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 36))], spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Button {
                        onSelect(color)
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .frame(width: 200)
        .background(.background)
    }
}

// MARK: - Previews
#Preview {
    FormatPopoverView(
        currentTextStyle: .constant(.body),
        activeFormats: [.bold, .italic],
        onFormatAction: { format in
            print("Format action: \(format)")
        }
    )
}
