//
//  ChapterMetadataSheet.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI
import SwiftData

/// Sheet for managing chapter-level metadata
///
/// Allows authors to set POV character, scene location, timeline,
/// and other manuscript organization metadata for each chapter.
///
/// This view edits the ChapterMetadata SwiftData model in-place.
/// Changes are automatically tracked by SwiftData and persisted when saved.
struct ChapterMetadataSheet: View {
    /// Dismiss action
    @Environment(\.dismiss) private var dismiss

    /// The chapter whose metadata is being edited
    let chapter: Chapter

    /// View model for persistence operations
    let viewModel: ChapterViewModel

    /// Local state for tags input (comma-separated string)
    @State private var tagsInput: String = ""

    /// The metadata being edited (loaded on appear)
    @State private var metadata: ChapterMetadata?

    var body: some View {
        NavigationStack {
            Group {
                if let metadata = metadata {
                    Form {
                        Section("Point of View") {
                            TextField("POV Character", text: Binding(
                                get: { metadata.povCharacter },
                                set: { metadata.povCharacter = $0 }
                            ))
                            .textContentType(.name)
                            .autocorrectionDisabled()

                            Picker("POV Style", selection: Binding(
                                get: { metadata.povStyle },
                                set: { metadata.povStyle = $0 }
                            )) {
                                ForEach(POVStyle.allCases) { style in
                                    Text(style.rawValue).tag(style)
                                }
                            }
                        }

                        Section("Scene Details") {
                            TextField("Location", text: Binding(
                                get: { metadata.sceneLocation },
                                set: { metadata.sceneLocation = $0 }
                            ))
                            .autocorrectionDisabled()

                            TextField("Time of Day", text: Binding(
                                get: { metadata.timeOfDay },
                                set: { metadata.timeOfDay = $0 }
                            ))
                            .autocorrectionDisabled()

                            DatePicker(
                                "Story Timeline",
                                selection: Binding(
                                    get: { metadata.storyDate },
                                    set: { metadata.storyDate = $0 }
                                ),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }

                        Section("Chapter Info") {
                            Picker("Chapter Type", selection: Binding(
                                get: { metadata.chapterType },
                                set: { metadata.chapterType = $0 }
                            )) {
                                ForEach(ChapterType.allCases) { type in
                                    Label(type.rawValue, systemImage: type.icon)
                                        .tag(type)
                                }
                            }

                            Toggle("Completed", isOn: Binding(
                                get: { metadata.isCompleted },
                                set: { metadata.isCompleted = $0 }
                            ))

                            Toggle("Needs Revision", isOn: Binding(
                                get: { metadata.needsRevision },
                                set: { metadata.needsRevision = $0 }
                            ))
                        }

                        Section("Notes") {
                            TextEditor(text: Binding(
                                get: { metadata.notes },
                                set: { metadata.notes = $0 }
                            ))
                            .frame(minHeight: 100)
                        }

                        Section("Tags") {
                            TextField("Add tags (comma-separated)", text: $tagsInput)
                                .textContentType(.none)
                                .autocorrectionDisabled()
                                .onChange(of: tagsInput) { _, newValue in
                                    // Update tags array from comma-separated string
                                    metadata.setTagsFromString(newValue)
                                }

                            if !metadata.tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(metadata.tags, id: \.self) { tag in
                                            HStack(spacing: 4) {
                                                Text(tag)
                                                    .font(.caption)

                                                Button {
                                                    removeTag(tag, from: metadata)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.caption2)
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.blue.opacity(0.15))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                } else {
                    ProgressView("Loading metadata...")
                }
            }
            .navigationTitle("Chapter Metadata")
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        saveMetadata()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMetadata()
            }
        }
    }

    // MARK: - Helper Methods

    /// Load or create metadata for the chapter
    private func loadMetadata() {
        // Get existing metadata or create new
        let meta = viewModel.getOrCreateMetadata(for: chapter)
        self.metadata = meta

        // Initialize tags input string
        self.tagsInput = meta.tagsString
    }

    /// Save metadata changes
    private func saveMetadata() {
        guard let metadata = metadata else { return }

        // Update last modified timestamp
        viewModel.updateMetadata(for: chapter, with: metadata)
    }

    /// Remove a tag from the metadata
    private func removeTag(_ tag: String, from metadata: ChapterMetadata) {
        metadata.tags.removeAll { $0 == tag }
        metadata.lastModified = Date()

        // Update the input field to reflect removal
        tagsInput = metadata.tagsString
    }
}

// Data models are defined in Models/ChapterMetadata.swift

// MARK: - Previews

#Preview {
    let store = DataStore.preview()
    if let book = try? store.fetchBooks().first,
       let chapter = book.chapters.first {
        return ChapterMetadataSheet(
            chapter: chapter,
            viewModel: ChapterViewModel(modelContext: store.modelContext)
        )
        .modelContainer(store.modelContainer)
    }
    return Text("No preview data")
}
