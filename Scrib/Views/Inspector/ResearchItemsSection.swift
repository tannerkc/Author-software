//
//  ResearchItemsSection.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

#if os(macOS)
import SwiftUI
import SwiftData
import AppKit

/// Section displaying research items in the inspector panel
///
/// Shows all research materials attached to the current book, including
/// PDFs, images, web links, quotes, and other reference materials.
/// Supports filtering by type and quick preview via Quick Look.
struct ResearchItemsSection: View {
    /// The current book
    let book: Book

    /// View model for inspector operations
    @Bindable var viewModel: InspectorViewModel

    /// Environment for Quick Look preview
    @State private var quickLookURL: URL?
    @State private var showingQuickLook = false

    /// Filter by research item type
    @State private var selectedFilter: ResearchItemType?

    /// Fetch research items based on filter
    private var researchItems: [ResearchItem] {
        if let filter = selectedFilter {
            return viewModel.fetchResearchItems(for: book, ofType: filter)
        }
        return viewModel.fetchResearchItems(for: book)
    }

    /// Group items by type for organized display
    private var itemsByType: [ResearchItemType: [ResearchItem]] {
        Dictionary(grouping: researchItems, by: \.itemType)
    }

    var body: some View {
        CollapsibleSection(
            "Research",
            icon: "doc.text.magnifyingglass",
            count: researchItems.count,
            isExpanded: $viewModel.isResearchExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Filter picker
                if !book.researchItems.isEmpty {
                    filterPicker
                }

                // Research items grid
                if researchItems.isEmpty {
                    emptyState
                } else {
                    itemsGrid
                }
            }
        }
    }

    // MARK: - Subviews

    private var filterPicker: some View {
        Menu {
            Button("All Types") {
                selectedFilter = nil
            }

            Divider()

            ForEach(ResearchItemType.allCases) { type in
                let count = viewModel.fetchResearchItems(for: book, ofType: type).count
                if count > 0 {
                    Button {
                        selectedFilter = type
                    } label: {
                        Label {
                            Text("\(type.rawValue) (\(count))")
                        } icon: {
                            Image(systemName: type.icon)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedFilter?.icon ?? "line.3.horizontal.decrease.circle")
                    .font(.system(size: 11))

                Text(selectedFilter?.rawValue ?? "All Types")
                    .font(.system(size: 11))

                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }

    private var itemsGrid: some View {
        LazyVStack(spacing: 12) {
            ForEach(researchItems.sorted(), id: \.id) { item in
                ResearchItemCard(item: item) {
                    handleItemTap(item)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)

            Text(selectedFilter != nil ? "No \(selectedFilter!.rawValue.lowercased()) items" : "No research items")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if selectedFilter != nil {
                Button("Clear Filter") {
                    selectedFilter = nil
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundStyle(.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Actions

    private func handleItemTap(_ item: ResearchItem) {
        // If item has attachment, try to preview it
        if item.hasAttachment, let data = item.attachmentData {
            previewAttachment(data: data, filename: item.attachmentFilename ?? "attachment", mimeType: item.attachmentMimeType)
        } else if item.itemType == .webLink && !item.source.isEmpty {
            // Open web link in default browser
            if let url = URL(string: item.source) {
                NSWorkspace.shared.open(url)
            }
        } else {
            // Show content in a popover or detail view
            // For now, just select the item
            viewModel.selectedResearchItem = item
        }
    }

    private func previewAttachment(data: Data, filename: String, mimeType: String?) {
        // Create temporary file for Quick Look
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: tempFile)
            // Open with Quick Look or default application
            NSWorkspace.shared.open(tempFile)
        } catch {
            print("Failed to create temp file for preview: \(error)")
        }
    }
}

// MARK: - Previews

#Preview("With Research Items") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, Chapter.self, ResearchItem.self,
        configurations: config
    )

    let book = Book(title: "My Novel", genre: "Fiction")
    container.mainContext.insert(book)

    let item1 = ResearchItem(
        title: "Character Photo",
        content: "Visual reference for protagonist",
        itemType: .image,
        tags: ["character", "visual"]
    )
    item1.book = book

    let item2 = ResearchItem(
        title: "Historical Context",
        content: "Victorian era research paper",
        itemType: .pdf,
        source: "academic.edu"
    )
    item2.book = book

    let item3 = ResearchItem(
        title: "Inspiring Quote",
        content: "\"Write what should not be forgotten.\" - Isabel Allende",
        itemType: .quote,
        tags: ["inspiration"]
    )
    item3.book = book

    container.mainContext.insert(item1)
    container.mainContext.insert(item2)
    container.mainContext.insert(item3)

    let viewModel = InspectorViewModel(modelContext: container.mainContext)

    return ScrollView {
        ResearchItemsSection(book: book, viewModel: viewModel)
            .padding()
    }
    .frame(width: 300, height: 600)
    .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, Chapter.self, ResearchItem.self,
        configurations: config
    )

    let book = Book(title: "My Novel", genre: "Fiction")
    container.mainContext.insert(book)

    let viewModel = InspectorViewModel(modelContext: container.mainContext)

    return ScrollView {
        ResearchItemsSection(book: book, viewModel: viewModel)
            .padding()
    }
    .frame(width: 300, height: 400)
    .modelContainer(container)
}

#endif
