//
//  AdaptiveKeyboardToolbar.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// iOS 26 adaptive keyboard toolbar with Liquid Glass design
///
/// Replicates Apple Notes' adaptive toolbar that sits above the keyboard,
/// featuring horizontal scrolling for 18+ tools and context-aware visibility.
/// Includes both standard formatting tools and Scrib-specific authoring features.
struct AdaptiveKeyboardToolbar: View {
    /// Current text selection/cursor state
    @Binding var selectedRange: Range<String.Index>?

    /// Content being edited
    @Binding var content: String

    /// Word count to display
    let wordCount: Int

    /// Currently active formats at cursor/selection
    let activeFormats: Set<TextFormat>

    /// Callback for formatting actions
    var onFormatAction: (FormatAction) -> Void

    /// Available formatting and tool actions
    enum FormatAction {
        // Format menu
        case showFormatMenu

        // Text alignment
        case cycleAlignment

        // Text formatting
        case bold, italic, underline, strikethrough
        case highlight(Color)

        // Lists and structure
        case bulletList, numberedList, checklist
        case indent, outdent

        // Content insertion
        case quote, link, table, image

        // Scrib-specific
        case markCharacter
        case addNote
        case setMetadata
        case markScene
        case markPOV

        // Apple Intelligence
        case aiRewrite, aiProofread, aiSummarize
    }

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Scrollable Tool Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Core tools (always visible)
                    ForEach(coreTools, id: \.self) { tool in
                        toolButton(for: tool)
                    }

                    Divider()
                        .frame(height: 24)
                        .padding(.horizontal, 4)

                    // Scrib-specific tools
                    ForEach(scribTools, id: \.self) { tool in
                        toolButton(for: tool)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

            Divider()
                .frame(height: 28)
                .padding(.horizontal, 8)

            // MARK: - Word Count
            VStack(alignment: .leading, spacing: 2) {
                Text("\(wordCount)")
                    .font(.caption.monospacedDigit())
                    .fontWeight(.medium)

                Text("words")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.trailing, 12)
            .frame(minWidth: 60)
        }
        .frame(height: 48)
        .padding(.horizontal, 8)
        .glassEffect(.regular.interactive(), in: .capsule)
        .padding(.bottom, 8)
        .padding(.horizontal, 12)
    }

    // MARK: - Tool Button

    @ViewBuilder
    private func toolButton(for tool: ToolDescriptor) -> some View {
        Button {
            onFormatAction(tool.action)
        } label: {
            Image(systemName: tool.icon)
                .font(.system(size: 18))
                .foregroundStyle(tool.tint)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .help(tool.label)
    }

    // MARK: - Tool Definitions

    /// Core tools (first 6-8, most frequently used)
    private var coreTools: [ToolDescriptor] {
        [
            ToolDescriptor(icon: "textformat", label: "Format", action: .showFormatMenu, tint: .primary),
            ToolDescriptor(icon: currentAlignmentIcon, label: "Text Alignment", action: .cycleAlignment, tint: .primary),
            ToolDescriptor(icon: "text.quote", label: "Quote", action: .quote),
            ToolDescriptor(icon: "link", label: "Insert Link", action: .link),
            ToolDescriptor(icon: "photo", label: "Insert Image", action: .image),
            ToolDescriptor(icon: "tablecells", label: "Insert Table", action: .table),
        ]
    }

    /// Get the icon for the current text alignment
    private var currentAlignmentIcon: String {
        if activeFormats.contains(.alignCenter) {
            return "text.aligncenter"
        } else if activeFormats.contains(.alignRight) {
            return "text.alignright"
        } else if activeFormats.contains(.alignJustified) {
            return "text.justify"
        } else {
            return "text.alignleft"
        }
    }

    /// Extended tools (swipeable, standard features)
    private var extendedTools: [ToolDescriptor] {
        [
            // Extended tools removed - all formatting now in Format menu (Aa button)
            // Content insertion tools moved to core tools
        ]
    }

    /// Scrib-specific authoring tools
    private var scribTools: [ToolDescriptor] {
        [
            ToolDescriptor(
                icon: "person.fill.badge.plus",
                label: "Mark Character",
                action: .markCharacter,
                tint: .purple
            ),
            ToolDescriptor(
                icon: "note.text.badge.plus",
                label: "Add Note",
                action: .addNote,
                tint: .orange
            ),
            ToolDescriptor(
                icon: "mappin.circle",
                label: "Mark Scene",
                action: .markScene,
                tint: .green
            ),
            ToolDescriptor(
                icon: "eye.fill",
                label: "Mark POV",
                action: .markPOV,
                tint: .blue
            ),
            ToolDescriptor(
                icon: "tag.fill",
                label: "Set Metadata",
                action: .setMetadata,
                tint: .indigo
            ),
        ]
    }
}

// MARK: - Tool Descriptor

/// Describes a toolbar button
struct ToolDescriptor: Hashable {
    let icon: String
    let label: String
    let action: AdaptiveKeyboardToolbar.FormatAction
    var tint: Color = .primary

    func hash(into hasher: inout Hasher) {
        hasher.combine(icon)
        hasher.combine(label)
    }

    static func == (lhs: ToolDescriptor, rhs: ToolDescriptor) -> Bool {
        lhs.icon == rhs.icon && lhs.label == rhs.label
    }
}

// MARK: - Previews

#Preview("Keyboard Toolbar") {
    VStack {
        Spacer()

        // Simulated text editor
        RoundedRectangle(cornerRadius: 12)
            .fill(.gray.opacity(0.1))
            .frame(height: 300)
            .overlay(
                Text("Text editor content...")
                    .foregroundStyle(.secondary)
            )
            .padding()

        // Toolbar
        AdaptiveKeyboardToolbar(
            selectedRange: .constant(nil),
            content: .constant("Sample chapter content"),
            wordCount: 1247,
            activeFormats: [.alignLeft],
            onFormatAction: { action in
                print("Format action: \(action)")
            }
        )
    }
    .background(Color.systemGroupedBackground)
}

#Preview("Dark Mode") {
    VStack {
        Spacer()

        Text("Chapter content goes here...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.systemBackground)

        AdaptiveKeyboardToolbar(
            selectedRange: .constant(nil),
            content: .constant(""),
            wordCount: 523,
            activeFormats: [.alignCenter],
            onFormatAction: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
