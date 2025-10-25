//
//  ResearchEditorView.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Editor view for research item content
struct ResearchEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let item: ResearchItem
    let viewModel: MaterialViewModel

    @State private var attributedContent: NSAttributedString
    @State private var showFormatMenu = false
    @State private var autoSaveTask: Task<Void, Never>?

    init(item: ResearchItem, viewModel: MaterialViewModel) {
        self.item = item
        self.viewModel = viewModel
        self._attributedContent = State(initialValue: item.getAttributedContent())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Source link strip
                if !item.source.isEmpty {
                    HStack {
                        Image(systemName: "link")
                            .foregroundStyle(.blue)
                        Text(item.source)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.secondary.opacity(0.1))
                }

                RichTextEditor(
                    attributedText: $attributedContent,
                    showFormatMenu: $showFormatMenu,
                    placeholderText: "Add your research notes..."
                )
                .onChange(of: attributedContent) { _, newValue in
                    scheduleAutoSave(newValue)
                }
            }
            .navigationTitle(item.extractedTitle)
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        forceSave()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        if item.hasAttachment {
                            Image(systemName: "paperclip")
                                .foregroundStyle(.secondary)
                        }

                        Text("\(item.wordCount) words")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDisappear {
                forceSave()
            }
        }
    }

    private func scheduleAutoSave(_ content: NSAttributedString) {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                item.setAttributedContent(content)
                viewModel.updateResearchItem(item, content: content.string)
            }
        }
    }

    private func forceSave() {
        autoSaveTask?.cancel()
        item.setAttributedContent(attributedContent)
        viewModel.updateResearchItem(item, content: attributedContent.string)
    }
}
