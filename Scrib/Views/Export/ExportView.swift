//
//  ExportView.swift
//  Scrib
//
//  Created by Claude on 2025-01-23.
//

import SwiftUI

/// Export configuration and execution view
struct ExportView: View {
    @Environment(\.dismiss) private var dismiss

    let book: Book
    let chapter: Chapter?

    @State private var selectedFormat: ExportFormat = .pdf
    @State private var metadata: ExportMetadata
    @State private var includeCoverPage = true
    @State private var includeTableOfContents = true
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(book: Book, chapter: Chapter? = nil) {
        self.book = book
        self.chapter = chapter
        _metadata = State(initialValue: ExportMetadata.from(book: book))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Format Selection
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Label(format.rawValue, systemImage: format.icon)
                                .tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Metadata Section
                Section("Book Information") {
                    TextField("Title", text: $metadata.title)
                    TextField("Author", text: $metadata.author)
                    TextField("Genre", text: $metadata.genre)
                    TextField("Publisher", text: $metadata.publisher)
                }

                Section("Description") {
                    TextEditor(text: $metadata.description)
                        .frame(minHeight: 100)
                }

                // Options Section
                Section("Export Options") {
                    if chapter == nil {
                        Toggle("Include Cover Page", isOn: $includeCoverPage)
                        Toggle("Include Table of Contents", isOn: $includeTableOfContents)
                    }

                    if selectedFormat == .epub {
                        TextField("ISBN (Optional)", text: $metadata.isbn)
                        TextField("Copyright", text: $metadata.copyright)
                    }
                }

                // Export Info
                Section {
                    if let chapter = chapter {
                        LabeledContent("Exporting", value: "Single Chapter")
                        LabeledContent("Title", value: chapter.extractedTitle)
                        LabeledContent("Word Count", value: "\(chapter.wordCount)")
                    } else {
                        LabeledContent("Exporting", value: "Entire Book")
                        LabeledContent("Chapters", value: "\(book.chapterCount)")
                        LabeledContent("Total Words", value: "\(book.totalWordCount)")
                    }
                }
            }
            .navigationTitle("Export \(selectedFormat.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isExporting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        Task {
                            await performExport()
                        }
                    }
                    .disabled(isExporting || metadata.title.isEmpty)
                }
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Exporting \(selectedFormat.rawValue)...")
                                .font(.headline)
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.background)
                                .shadow(radius: 10)
                        )
                    }
                }
            }
            .sheet(item: $exportedFileURL) { url in
                ShareSheet(items: [url])
                    .onDisappear {
                        dismiss()
                    }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }

    // MARK: - Export Logic

    @MainActor
    private func performExport() async {
        isExporting = true
        errorMessage = nil

        do {
            let configuration = ExportConfiguration(
                format: selectedFormat,
                metadata: metadata,
                includeCoverPage: includeCoverPage,
                includeTableOfContents: includeTableOfContents
            )

            let fileURL: URL
            if let chapter = chapter {
                fileURL = try await ExportManager.shared.exportChapter(
                    chapter,
                    configuration: configuration
                )
            } else {
                fileURL = try await ExportManager.shared.exportBook(
                    book,
                    configuration: configuration
                )
            }

            exportedFileURL = fileURL
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }

        isExporting = false
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - URL Identifiable Extension

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Preview

#Preview {
    @Previewable @State var sampleBook = Book(
        title: "The Great Novel",
        genre: "Fiction"
    )

    ExportView(book: sampleBook)
}
