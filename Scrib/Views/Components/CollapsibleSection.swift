//
//  CollapsibleSection.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

#if os(macOS)
import SwiftUI

/// A collapsible section component for the inspector panel
///
/// Provides a disclosure group with customizable header and content,
/// maintaining expansion state via binding. Designed for macOS inspector
/// sidebar with consistent styling.
struct CollapsibleSection<Content: View>: View {
    /// Section title displayed in the header
    let title: String

    /// Optional SF Symbol icon name
    let icon: String?

    /// Optional count badge (e.g., number of items)
    let count: Int?

    /// Binding to control expansion state
    @Binding var isExpanded: Bool

    /// The section content
    @ViewBuilder let content: () -> Content

    /// Initialize a collapsible section
    /// - Parameters:
    ///   - title: The section title
    ///   - icon: Optional SF Symbol icon name
    ///   - count: Optional count badge
    ///   - isExpanded: Binding to control expansion state
    ///   - content: The section content view builder
    init(
        _ title: String,
        icon: String? = nil,
        count: Int? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.count = count
        self._isExpanded = isExpanded
        self.content = content
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(.top, 8)
            .padding(.leading, 4)
        } label: {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                }

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(.quaternary)
                        }
                }
            }
        }
        .disclosureGroupStyle(InspectorDisclosureGroupStyle())
    }
}

// MARK: - Disclosure Group Style

/// Custom disclosure group style for inspector sections
private struct InspectorDisclosureGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                        .animation(.snappy(duration: 0.2), value: configuration.isExpanded)
                        .frame(width: 12)

                    configuration.label
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary.opacity(0.5))
            }

            if configuration.isExpanded {
                configuration.content
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Previews

#Preview("Expanded Section") {
    VStack(alignment: .leading, spacing: 12) {
        CollapsibleSection(
            "Research Items",
            icon: "doc.text",
            count: 5,
            isExpanded: .constant(true)
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Research Item 1")
                Text("Research Item 2")
                Text("Research Item 3")
            }
            .font(.system(size: 12))
        }
    }
    .frame(width: 300)
    .padding()
}

#Preview("Collapsed Section") {
    VStack(alignment: .leading, spacing: 12) {
        CollapsibleSection(
            "Characters",
            icon: "person.2",
            count: 3,
            isExpanded: .constant(false)
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Character 1")
                Text("Character 2")
                Text("Character 3")
            }
            .font(.system(size: 12))
        }
    }
    .frame(width: 300)
    .padding()
}

#Preview("No Icon, No Count") {
    VStack(alignment: .leading, spacing: 12) {
        CollapsibleSection(
            "Notes",
            isExpanded: .constant(true)
        ) {
            Text("Note content goes here")
                .font(.system(size: 12))
        }
    }
    .frame(width: 300)
    .padding()
}

#endif
