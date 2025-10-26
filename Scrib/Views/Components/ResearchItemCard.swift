//
//  ResearchItemCard.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

#if os(macOS)
import SwiftUI
import AppKit

/// A card component for displaying research item previews in the inspector
///
/// Shows research item title, type, preview, and optional image/PDF thumbnail.
/// Supports click interaction for full-screen preview or Quick Look.
struct ResearchItemCard: View {
    /// The research item to display
    let item: ResearchItem

    /// Action when card is clicked
    let onTap: () -> Void

    /// Derived image from attachment data (if image type)
    private var attachmentImage: NSImage? {
        guard item.itemType == .image,
              let data = item.attachmentData else {
            return nil
        }
        return NSImage(data: data)
    }

    /// Derived PDF thumbnail (if PDF type)
    private var pdfThumbnail: NSImage? {
        guard item.itemType == .pdf,
              let _ = item.attachmentData else {
            return nil
        }
        // Basic PDF thumbnail generation would go here
        // For now, return nil and show PDF icon instead
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header with icon and type
                HStack(spacing: 6) {
                    Image(systemName: item.itemType.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(item.itemType.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    if item.hasAttachment {
                        Image(systemName: "paperclip")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                // Thumbnail or placeholder
                if let image = attachmentImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.quaternary, lineWidth: 1)
                        }
                } else if item.itemType == .pdf {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary.opacity(0.5))
                            .frame(height: 80)

                        VStack(spacing: 4) {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)

                            if let filename = item.attachmentFilename {
                                Text(filename)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }
                    }
                } else if item.itemType == .image && !item.hasAttachment {
                    // Image type but no attachment data
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary.opacity(0.5))
                            .frame(height: 80)

                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }

                // Title
                Text(item.extractedTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Content preview (if no image)
                if attachmentImage == nil && !item.content.isEmpty {
                    Text(item.contentPreview)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                // Tags
                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(item.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 9, weight: .medium))
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
                }

                // Footer with source or metadata
                if !item.source.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)

                        Text(item.source)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.quaternary, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .help(item.extractedTitle)
    }
}

// MARK: - Previews

#Preview("Image Research Item") {
    ResearchItemCard(
        item: ResearchItem(
            title: "Character Reference Photo",
            content: "A photo of the main character's inspiration",
            itemType: .image,
            source: "pinterest.com",
            tags: ["character", "visual", "reference"]
        ),
        onTap: { print("Tapped") }
    )
    .frame(width: 260)
    .padding()
}

#Preview("PDF Research Item") {
    ResearchItemCard(
        item: ResearchItem(
            title: "Historical Context",
            content: "Research paper about the Victorian era",
            itemType: .pdf,
            source: "academic-journal.com",
            tags: ["history", "research"],
            attachmentFilename: "victorian-era.pdf"
        ),
        onTap: { print("Tapped") }
    )
    .frame(width: 260)
    .padding()
}

#Preview("Web Link Research Item") {
    ResearchItemCard(
        item: ResearchItem(
            title: "Article About Medieval Castles",
            content: "This article provides detailed information about castle architecture in the 12th century, including defensive structures and living quarters.",
            itemType: .webLink,
            source: "https://medievalarchitecture.org/castles",
            tags: ["architecture", "medieval"]
        ),
        onTap: { print("Tapped") }
    )
    .frame(width: 260)
    .padding()
}

#Preview("Quote Research Item") {
    ResearchItemCard(
        item: ResearchItem(
            title: "",
            content: "\"The only way to do great work is to love what you do.\" - Steve Jobs",
            itemType: .quote,
            source: "Stanford Commencement Speech, 2005",
            tags: ["inspiration"]
        ),
        onTap: { print("Tapped") }
    )
    .frame(width: 260)
    .padding()
}

#endif
