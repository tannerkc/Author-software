//
//  ResearchListView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// List view displaying all research items for a book
struct ResearchListView: View {
    let book: Book
    let viewModel: MaterialViewModel

    @State private var searchText = ""
    @State private var selectedItem: ResearchItem?
    @State private var showingEditor = false

    var filteredItems: [ResearchItem] {
        if searchText.isEmpty {
            return book.sortedResearchItems
        } else {
            return book.sortedResearchItems.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        Group {
            if book.researchItems.isEmpty {
                MaterialEmptyStateView(
                    icon: "book",
                    title: "No Research",
                    message: "Research items store reference materials, web links, and supporting documentation. Tap the + button to create your first research item."
                )
            } else {
                List {
                    ForEach(filteredItems) { item in
                        ResearchRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItem = item
                                showingEditor = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.deleteResearchItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteResearchItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .searchable(text: $searchText, prompt: "Search research")
            }
        }
        .sheet(item: $selectedItem) { item in
            ResearchEditorView(item: item, viewModel: viewModel)
        }
    }
}

// MARK: - Research Row

struct ResearchRow: View {
    let item: ResearchItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(item.extractedTitle, systemImage: item.itemType.icon)
                    .font(.headline)

                Spacer()

                if item.hasAttachment {
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !item.contentPreview.isEmpty {
                Text(item.contentPreview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if !item.source.isEmpty {
                HStack {
                    Image(systemName: "link")
                        .font(.caption)
                    Text(item.source)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.blue)
            }

            // Tags
            if !item.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            HStack {
                Text(item.lastModified.smartFormatted)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text("\(item.wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ResearchListView(
            book: {
                let book = Book(title: "Sample Book")
                let item = ResearchItem(
                    title: "Medieval Taverns",
                    content: "Research notes on medieval tavern architecture...",
                    itemType: .historical,
                    source: "https://example.com/medieval-taverns",
                    tags: ["worldbuilding", "setting"]
                )
                item.book = book
                book.researchItems = [item]
                return book
            }(),
            viewModel: MaterialViewModel(modelContext: ModelContext(
                try! ModelContainer(for: Book.self, ResearchItem.self)
            ))
        )
    }
}
