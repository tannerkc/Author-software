//
//  ChapterMetadataSection.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

#if os(macOS)
import SwiftUI
import SwiftData

/// Section displaying chapter metadata in the inspector panel
///
/// Shows chapter-specific information including POV, scene details, status,
/// word count, and other manuscript metadata. Provides quick reference without
/// needing to open the full metadata sheet.
struct ChapterMetadataSection: View {
    /// The current chapter
    let chapter: Chapter?

    /// View model for inspector operations
    @Bindable var viewModel: InspectorViewModel

    /// Chapter metadata (if exists)
    private var metadata: ChapterMetadata? {
        chapter?.metadata
    }

    var body: some View {
        CollapsibleSection(
            "Metadata",
            icon: "info.circle",
            count: nil,
            isExpanded: $viewModel.isMetadataExpanded
        ) {
            if let chapter = chapter {
                VStack(alignment: .leading, spacing: 16) {
                    // Statistics section
                    statisticsSection(for: chapter)

                    Divider()

                    // Chapter details
                    if let metadata = metadata {
                        metadataDetailsSection(for: metadata)
                    } else {
                        noMetadataState
                    }
                }
            } else {
                noChapterSelectedState
            }
        }
    }

    // MARK: - Subviews

    private func statisticsSection(for chapter: Chapter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Statistics")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            } icon: {
                Image(systemName: "chart.bar")
                    .font(.system(size: 10))
            }

            // Word count
            metadataRow(
                icon: "text.word.spacing",
                label: "Words",
                value: "\(chapter.wordCount)"
            )

            // Character count
            metadataRow(
                icon: "character.textbox",
                label: "Characters",
                value: "\(chapter.characterCount)"
            )

            // Last modified
            metadataRow(
                icon: "clock",
                label: "Modified",
                value: formatDate(chapter.lastModified)
            )
        }
    }

    private func metadataDetailsSection(for metadata: ChapterMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status indicators
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("Status")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                } icon: {
                    Image(systemName: "flag")
                        .font(.system(size: 10))
                }

                HStack(spacing: 6) {
                    statusBadge(
                        icon: metadata.isCompleted ? "checkmark.circle.fill" : "circle",
                        label: "Complete",
                        color: metadata.isCompleted ? .green : .secondary
                    )

                    if metadata.needsRevision {
                        statusBadge(
                            icon: "exclamationmark.triangle.fill",
                            label: "Needs Revision",
                            color: .orange
                        )
                    }
                }
            }

            // Chapter type
            if metadata.chapterType != .standard {
                metadataRow(
                    icon: metadata.chapterType.icon,
                    label: "Type",
                    value: metadata.chapterType.rawValue
                )
            }

            // POV information
            if !metadata.povCharacter.isEmpty || metadata.povStyle != .thirdPerson {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("Point of View")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    } icon: {
                        Image(systemName: "eye")
                            .font(.system(size: 10))
                    }

                    if !metadata.povCharacter.isEmpty {
                        metadataRow(
                            icon: "person.circle",
                            label: "Character",
                            value: metadata.povCharacter
                        )
                    }

                    metadataRow(
                        icon: "text.alignleft",
                        label: "Style",
                        value: metadata.povStyle.rawValue
                    )
                }
            }

            // Scene details
            if !metadata.sceneLocation.isEmpty || !metadata.timeOfDay.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("Scene")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    } icon: {
                        Image(systemName: "location")
                            .font(.system(size: 10))
                    }

                    if !metadata.sceneLocation.isEmpty {
                        metadataRow(
                            icon: "mappin",
                            label: "Location",
                            value: metadata.sceneLocation
                        )
                    }

                    if !metadata.timeOfDay.isEmpty {
                        metadataRow(
                            icon: "sun.max",
                            label: "Time",
                            value: metadata.timeOfDay
                        )
                    }
                }
            }

            // Tags
            if !metadata.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("Tags")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    } icon: {
                        Image(systemName: "tag")
                            .font(.system(size: 10))
                    }

                    FlowLayout(spacing: 6) {
                        ForEach(metadata.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(.quaternary)
                                }
                        }
                    }
                }
            }

            // Notes
            if !metadata.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("Notes")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    } icon: {
                        Image(systemName: "note.text")
                            .font(.system(size: 10))
                    }

                    Text(metadata.notes)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary)
                        .lineLimit(5)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary.opacity(0.5))
                        }
                }
            }
        }
    }

    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }

    private func statusBadge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))

            Text(label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(color.opacity(0.15))
        }
    }

    private var noMetadataState: some View {
        VStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)

            Text("No metadata available")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var noChapterSelectedState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)

            Text("No chapter selected")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Flow Layout

/// Simple flow layout for tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Previews

#Preview("With Metadata") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, Chapter.self, ChapterMetadata.self,
        configurations: config
    )

    let book = Book(title: "My Novel", genre: "Fiction")
    let chapter = Chapter(title: "Chapter 1: The Beginning", content: "Once upon a time...", order: 0)
    chapter.book = book

    let metadata = ChapterMetadata(
        povCharacter: "Sarah",
        povStyle: .firstPerson,
        sceneLocation: "Coffee Shop, Downtown",
        timeOfDay: "Morning",
        chapterType: .standard,
        isCompleted: true,
        needsRevision: false,
        notes: "This is the opening scene. Need to establish the setting and introduce the protagonist.",
        tags: ["opening", "character-intro", "urban"]
    )
    metadata.chapter = chapter
    chapter.metadata = metadata

    container.mainContext.insert(book)
    container.mainContext.insert(chapter)
    container.mainContext.insert(metadata)

    let viewModel = InspectorViewModel(modelContext: container.mainContext)

    return ScrollView {
        ChapterMetadataSection(chapter: chapter, viewModel: viewModel)
            .padding()
    }
    .frame(width: 300, height: 600)
    .modelContainer(container)
}

#Preview("No Metadata") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, Chapter.self,
        configurations: config
    )

    let book = Book(title: "My Novel", genre: "Fiction")
    let chapter = Chapter(title: "Chapter 1", content: "Content", order: 0)
    chapter.book = book

    container.mainContext.insert(book)
    container.mainContext.insert(chapter)

    let viewModel = InspectorViewModel(modelContext: container.mainContext)

    return ScrollView {
        ChapterMetadataSection(chapter: chapter, viewModel: viewModel)
            .padding()
    }
    .frame(width: 300, height: 400)
    .modelContainer(container)
}

#endif
