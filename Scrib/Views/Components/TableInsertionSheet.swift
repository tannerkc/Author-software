//
//  TableInsertionSheet.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

/// Sheet for inserting tables into chapter text
///
/// Provides controls for selecting table dimensions (rows × columns),
/// with a visual preview mimicking Apple Notes table insertion.
struct TableInsertionSheet: View {
    /// Dismiss environment
    @Environment(\.dismiss) private var dismiss

    /// Number of rows
    @State private var rows: Int = 3

    /// Number of columns
    @State private var columns: Int = 3

    /// Callback when table is inserted
    var onInsert: (Int, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Table Dimensions") {
                    Picker("Rows", selection: $rows) {
                        ForEach(1...10, id: \.self) { row in
                            Text("\(row)").tag(row)
                        }
                    }

                    Picker("Columns", selection: $columns) {
                        ForEach(1...5, id: \.self) { col in
                            Text("\(col)").tag(col)
                        }
                    }
                }

                Section("Preview") {
                    VStack(spacing: 8) {
                        Text("\(rows) × \(columns) Table")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // Visual preview of table grid
                        VStack(spacing: 2) {
                            ForEach(0..<rows, id: \.self) { _ in
                                HStack(spacing: 2) {
                                    ForEach(0..<columns, id: \.self) { _ in
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.2))
                                            .frame(height: 30)
                                            .overlay(
                                                Rectangle()
                                                    .strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Insert Table")
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
                        onInsert(rows, columns)
                        dismiss()
                    }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium])
        #endif
    }
}

// MARK: - Previews
#Preview("Default") {
    TableInsertionSheet { rows, columns in
        print("Table: \(rows) × \(columns)")
    }
}

#Preview("Large Table") {
    TableInsertionSheet { rows, columns in
        print("Table: \(rows) × \(columns)")
    }
}
