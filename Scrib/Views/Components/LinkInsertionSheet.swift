//
//  LinkInsertionSheet.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Sheet for inserting hyperlinks into chapter text
///
/// Provides fields for URL and optional display text,
/// mimicking Apple Notes link insertion UI.
struct LinkInsertionSheet: View {
    /// Dismiss environment
    @Environment(\.dismiss) private var dismiss

    /// URL for the link
    @State private var linkURL: String = ""

    /// Display text for the link (optional - uses URL if empty)
    @State private var displayText: String = ""

    /// Initial selected text to use as display text
    let selectedText: String

    /// Callback when link is inserted
    var onInsert: (String, String) -> Void

    /// Focus state for auto-focusing URL field
    @FocusState private var isURLFocused: Bool

    init(selectedText: String = "", onInsert: @escaping (String, String) -> Void) {
        self.selectedText = selectedText
        self.onInsert = onInsert
        // Initialize display text with selected text if available
        _displayText = State(initialValue: selectedText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Link Details") {
                    TextField("URL", text: $linkURL)
                        .focused($isURLFocused)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        #endif

                    TextField("Display Text (Optional)", text: $displayText)
                        .disabled(!selectedText.isEmpty) // Disable if we have selected text
                }

                Section {
                    if !linkURL.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Preview:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(displayText.isEmpty ? linkURL : displayText)
                                .foregroundStyle(.blue)
                                .underline()
                        }
                    } else {
                        Text("Enter a URL to see preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Insert Link")
            #if os(iOS)
            .adaptiveNavigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Insert") {
                        let finalDisplayText = displayText.isEmpty ? linkURL : displayText
                        onInsert(linkURL, finalDisplayText)
                        dismiss()
                    }
                    .disabled(linkURL.isEmpty)
                }
            }
            .onAppear {
                // Auto-focus URL field
                isURLFocused = true
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
}

// MARK: - Previews
#Preview("Empty") {
    LinkInsertionSheet(selectedText: "") { url, displayText in
        print("URL: \(url), Display: \(displayText)")
    }
}

#Preview("With Selected Text") {
    LinkInsertionSheet(selectedText: "Click here") { url, displayText in
        print("URL: \(url), Display: \(displayText)")
    }
}
