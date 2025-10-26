//
//  BookOutlineSection.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

#if os(macOS)
import SwiftUI
import SwiftData

/// Section displaying book outline in the inspector panel
///
/// Provides a hierarchical view of all chapters in the book with quick
/// statistics and navigation. Shows chapter order, word counts, and completion
/// status for overview and planning.
struct BookOutlineSection: View {
    /// The current book
    let book: Book

    /// The currently selected chapter (for highlighting)
    let selectedChapter: Chapter?

    /// View model for inspector operations
    @Bindable var viewModel: InspectorViewModel

    /// Action to navigate to a chapter
    let onChapterSelect: (Chapter) -> Void

    /// Chapters for outline
    private var chapters: [Chapter] {
        viewModel.fetchChaptersForOutline(for: book)
    }

    /// Word count summary
    private var wordCountSummary: (total: Int, chapters: Int, average: Int) {
        viewModel.getWordCountSummary(for: book)
    }

    var body: some View {
        CollapsibleSection(
            "Outline",
            icon: "list.number",
            count: chapters.count,
            isExpanded: $viewModel.isOutlineExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Book statistics
                bookStatistics

                Divider()

                // Chapters list
                if chapters.isEmpty {
                    emptyState
                } else {
                    chaptersList
                }
            }
        }
    }

    // MARK: - Subviews

    private var bookStatistics: some View {
        VStack(spacing: 8) {
            statisticRow(
                icon: "text.word.spacing",
                label: "Total Words",
                value: "\(wordCountSummary.total.formatted())",
                color: .primary
            )

            statisticRow(
                icon: "doc.text",
                label: "Chapters",
                value: "\(wordCountSummary.chapters)",
                color: .secondary
            )

            if wordCountSummary.chapters > 0 {
                statisticRow(
                    icon: "chart.bar",
                    label: "Avg per Chapter",
                    value: "\(wordCountSummary.average.formatted())",
                    color: .secondary
                )
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary.opacity(0.3))
        }
    }

    private func statisticRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private var chaptersList: some View {
        LazyVStack(spacing: 6) {
            ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                ChapterOutlineRow(
                    chapter: chapter,
                    index: index + 1,
                    isSelected: chapter.id == selectedChapter?.id,
                    onTap: {
                        onChapterSelect(chapter)
                    }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.number")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)

            Text("No chapters yet")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Chapter Outline Row

private struct ChapterOutlineRow: View {
    let chapter: Chapter
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void

    /// Chapter completion status from metadata
    private var isCompleted: Bool {
        chapter.metadata?.isCompleted ?? false
    }

    /// Chapter needs revision flag
    private var needsRevision: Bool {
        chapter.metadata?.needsRevision ?? false
    }

    /// Chapter type
    private var chapterType: ChapterType {
        chapter.metadata?.chapterType ?? .standard
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Chapter number or type icon
                if chapterType != .standard {
                    Image(systemName: chapterType.icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                } else {
                    Text("\(index)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                }

                VStack(alignment: .leading, spacing: 3) {
                    // Title
                    Text(chapter.extractedTitle)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .lineLimit(1)

                    // Metadata badges and word count
                    HStack(spacing: 6) {
                        // Status badges
                        if isCompleted {
                            statusBadge(icon: "checkmark", color: .green)
                        }
                        if needsRevision {
                            statusBadge(icon: "exclamationmark.triangle", color: .orange)
                        }

                        Spacer()

                        // Word count
                        Text("\(chapter.wordCount)")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func statusBadge(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(color)
            .padding(3)
            .background {
                Circle()
                    .fill(color.opacity(0.15))
            }
    }
}

// MARK: - Previews

#Preview("Book Outline") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, Chapter.self, ChapterMetadata.self,
        configurations: config
    )

    let book = Book(title: "My Epic Novel", genre: "Fantasy")
    container.mainContext.insert(book)

    // Add chapters
    for i in 1...5 {
        let chapter = Chapter(
            title: "Chapter \(i): The Adventure Continues",
            content: String(repeating: "Word ", count: 500 + i * 100),
            order: i - 1
        )
        chapter.book = book

        if i == 1 {
            let metadata = ChapterMetadata(chapterType: .prologue, isCompleted: true)
            metadata.chapter = chapter
            chapter.metadata = metadata
            container.mainContext.insert(metadata)
        } else if i == 3 {
            let metadata = ChapterMetadata(isCompleted: true)
            metadata.chapter = chapter
            chapter.metadata = metadata
            container.mainContext.insert(metadata)
        } else if i == 4 {
            let metadata = ChapterMetadata(needsRevision: true)
            metadata.chapter = chapter
            chapter.metadata = metadata
            container.mainContext.insert(metadata)
        }

        container.mainContext.insert(chapter)
    }

    let viewModel = InspectorViewModel(modelContext: container.mainContext)

    return ScrollView {
        BookOutlineSection(
            book: book,
            selectedChapter: book.chapters.first,
            viewModel: viewModel,
            onChapterSelect: { _ in }
        )
        .padding()
    }
    .frame(width: 300, height: 600)
    .modelContainer(container)
}

#Preview("Empty Outline") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, Chapter.self,
        configurations: config
    )

    let book = Book(title: "New Book", genre: "Fiction")
    container.mainContext.insert(book)

    let viewModel = InspectorViewModel(modelContext: container.mainContext)

    return ScrollView {
        BookOutlineSection(
            book: book,
            selectedChapter: nil,
            viewModel: viewModel,
            onChapterSelect: { _ in }
        )
        .padding()
    }
    .frame(width: 300, height: 400)
    .modelContainer(container)
}

#endif
