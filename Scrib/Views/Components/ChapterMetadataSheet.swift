//
//  ChapterMetadataSheet.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Sheet for managing chapter-level metadata
///
/// Allows authors to set POV character, scene location, timeline,
/// and other manuscript organization metadata for each chapter.
struct ChapterMetadataSheet: View {
    /// Binding to control sheet presentation
    @Environment(\.dismiss) private var dismiss

    /// Chapter metadata being edited
    @Binding var metadata: ChapterMetadata

    /// Callback when metadata is saved
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Point of View") {
                    TextField("POV Character", text: $metadata.povCharacter)
                        .textContentType(.name)

                    Picker("POV Style", selection: $metadata.povStyle) {
                        ForEach(POVStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                }

                Section("Scene Details") {
                    TextField("Location", text: $metadata.sceneLocation)

                    TextField("Time of Day", text: $metadata.timeOfDay)

                    DatePicker(
                        "Story Timeline",
                        selection: $metadata.storyDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Chapter Info") {
                    Picker("Chapter Type", selection: $metadata.chapterType) {
                        ForEach(ChapterType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Toggle("Completed", isOn: $metadata.isCompleted)

                    Toggle("Needs Revision", isOn: $metadata.needsRevision)
                }

                Section("Notes") {
                    TextEditor(text: $metadata.notes)
                        .frame(minHeight: 100)
                }

                Section("Tags") {
                    TextField("Add tags (comma-separated)", text: $metadata.tagsString)
                        .textContentType(.none)

                    if !metadata.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(metadata.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chapter Metadata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// Data models are defined in Models/ChapterMetadata.swift

// MARK: - Previews

#Preview {
    ChapterMetadataSheet(
        metadata: .constant(ChapterMetadata(
            povCharacter: "Sarah",
            sceneLocation: "Detective's Office",
            tagsString: "mystery, investigation, clue"
        )),
        onSave: {
            print("Metadata saved")
        }
    )
}
