//
//  DOCXExporter.swift
//  Scrib
//
//  Created by Claude on 2025-01-23.
//

import Foundation
#if canImport(UIKit)
import UIKit
fileprivate typealias PlatformFont = UIFont
fileprivate typealias PlatformColor = UIColor

fileprivate extension UIColor {
    static var labelColor: UIColor { .label }
    static var secondaryLabelColor: UIColor { .secondaryLabel }
    static var tertiaryLabelColor: UIColor { .tertiaryLabel }
}
#elseif canImport(AppKit)
import AppKit
fileprivate typealias PlatformFont = NSFont
fileprivate typealias PlatformColor = NSColor
#endif

fileprivate extension PlatformFont {
    var isBold: Bool {
        #if canImport(UIKit)
        return fontDescriptor.symbolicTraits.contains(.traitBold)
        #elseif canImport(AppKit)
        return fontDescriptor.symbolicTraits.contains(.bold)
        #else
        return false
        #endif
    }

    var isItalic: Bool {
        #if canImport(UIKit)
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
        #elseif canImport(AppKit)
        return fontDescriptor.symbolicTraits.contains(.italic)
        #else
        return false
        #endif
    }
}
#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

/// DOCX export implementation using Office Open XML format
/// - Swift 6.2 compliant with @MainActor isolation
@MainActor
enum DOCXExporter {

    /// Export chapters to DOCX format
    /// - Parameters:
    ///   - title: Document title
    ///   - chapters: Chapters to include
    ///   - configuration: Export configuration
    /// - Returns: URL of generated DOCX file
    static func export(
        title: String,
        chapters: [Chapter],
        configuration: ExportConfiguration
    ) async throws -> URL {
        guard !chapters.isEmpty else {
            throw ExportError.emptyContent
        }

        let fileURL = ExportManager.temporaryFileURL(for: title, format: .docx)

        // Create temporary directory for DOCX structure
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try? FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Generate DOCX structure
        try await generateDOCXStructure(
            in: tempDir,
            title: title,
            chapters: chapters,
            configuration: configuration
        )

        // Create ZIP archive
        try createDOCXArchive(from: tempDir, to: fileURL)

        return fileURL
    }

    // MARK: - DOCX Structure Generation

    /// Generate the complete DOCX file structure
    private static func generateDOCXStructure(
        in directory: URL,
        title: String,
        chapters: [Chapter],
        configuration: ExportConfiguration
    ) async throws {
        // Create directory structure
        let relsDir = directory.appendingPathComponent("_rels")
        let wordDir = directory.appendingPathComponent("word")
        let wordRelsDir = wordDir.appendingPathComponent("_rels")

        try FileManager.default.createDirectory(at: relsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: wordDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: wordRelsDir, withIntermediateDirectories: true)

        // Generate required files
        try generateContentTypes(in: directory)
        try generateRootRels(in: relsDir)
        try generateDocumentRels(in: wordRelsDir)
        try generateStyles(in: wordDir, configuration: configuration)
        try generateDocument(
            in: wordDir,
            title: title,
            chapters: chapters,
            configuration: configuration
        )
        try generateCoreProperties(
            in: directory,
            metadata: configuration.metadata
        )
    }

    /// Generate [Content_Types].xml
    private static func generateContentTypes(in directory: URL) throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
            <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
            <Default Extension="xml" ContentType="application/xml"/>
            <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
            <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
            <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
        </Types>
        """

        let fileURL = directory.appendingPathComponent("[Content_Types].xml")
        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate _rels/.rels
    private static func generateRootRels(in relsDir: URL) throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
            <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
        </Relationships>
        """

        let fileURL = relsDir.appendingPathComponent(".rels")
        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate word/_rels/document.xml.rels
    private static func generateDocumentRels(in wordRelsDir: URL) throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        </Relationships>
        """

        let fileURL = wordRelsDir.appendingPathComponent("document.xml.rels")
        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate word/styles.xml
    private static func generateStyles(
        in wordDir: URL,
        configuration: ExportConfiguration
    ) throws {
        let fontSize = Int(configuration.fontSize * 2) // Word uses half-points

        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:docDefaults>
                <w:rPrDefault>
                    <w:rPr>
                        <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>
                        <w:sz w:val="\(fontSize)"/>
                    </w:rPr>
                </w:rPrDefault>
            </w:docDefaults>
            <w:style w:type="paragraph" w:styleId="Normal">
                <w:name w:val="Normal"/>
                <w:pPr>
                    <w:spacing w:line="360" w:lineRule="auto"/>
                </w:pPr>
            </w:style>
            <w:style w:type="paragraph" w:styleId="Heading1">
                <w:name w:val="Heading 1"/>
                <w:basedOn w:val="Normal"/>
                <w:pPr>
                    <w:spacing w:before="240" w:after="120"/>
                </w:pPr>
                <w:rPr>
                    <w:b/>
                    <w:sz w:val="32"/>
                </w:rPr>
            </w:style>
            <w:style w:type="character" w:styleId="Bold">
                <w:name w:val="Bold"/>
                <w:rPr>
                    <w:b/>
                </w:rPr>
            </w:style>
            <w:style w:type="character" w:styleId="Italic">
                <w:name w:val="Italic"/>
                <w:rPr>
                    <w:i/>
                </w:rPr>
            </w:style>
        </w:styles>
        """

        let fileURL = wordDir.appendingPathComponent("styles.xml")
        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate word/document.xml with chapter content
    private static func generateDocument(
        in wordDir: URL,
        title: String,
        chapters: [Chapter],
        configuration: ExportConfiguration
    ) throws {
        var bodyContent = ""

        // Add cover page if requested
        if configuration.includeCoverPage {
            bodyContent += generateCoverPage(metadata: configuration.metadata)
            bodyContent += "<w:p><w:pPr><w:pageBreakBefore/></w:pPr></w:p>" // Page break
        }

        // Add table of contents if requested
        if configuration.includeTableOfContents && chapters.count > 1 {
            bodyContent += generateTableOfContents(chapters: chapters)
            bodyContent += "<w:p><w:pPr><w:pageBreakBefore/></w:pPr></w:p>" // Page break
        }

        // Add chapters
        for (index, chapter) in chapters.enumerated() {
            if index > 0 || configuration.includeCoverPage || configuration.includeTableOfContents {
                bodyContent += "<w:p><w:pPr><w:pageBreakBefore/></w:pPr></w:p>"
            }

            bodyContent += generateChapterContent(chapter)
        }

        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:body>
                \(bodyContent)
            </w:body>
        </w:document>
        """

        let fileURL = wordDir.appendingPathComponent("document.xml")
        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate cover page WordML
    private static func generateCoverPage(metadata: ExportMetadata) -> String {
        var content = ""

        // Title
        content += """
        <w:p>
            <w:pPr><w:jc w:val="center"/></w:pPr>
            <w:r>
                <w:rPr><w:b/><w:sz w:val="72"/></w:rPr>
                <w:t>\(xmlEscape(metadata.title))</w:t>
            </w:r>
        </w:p>
        """

        // Author
        if !metadata.author.isEmpty {
            content += """
            <w:p>
                <w:pPr><w:jc w:val="center"/></w:pPr>
                <w:r>
                    <w:rPr><w:sz w:val="48"/></w:rPr>
                    <w:t>by \(xmlEscape(metadata.author))</w:t>
                </w:r>
            </w:p>
            """
        }

        return content
    }

    /// Generate table of contents WordML
    private static func generateTableOfContents(chapters: [Chapter]) -> String {
        var content = """
        <w:p>
            <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
            <w:r><w:t>Table of Contents</w:t></w:r>
        </w:p>
        """

        for (index, chapter) in chapters.enumerated() {
            let chapterTitle = chapter.extractedTitle.isEmpty
                ? "Chapter \(index + 1)"
                : chapter.extractedTitle

            content += """
            <w:p>
                <w:pPr><w:ind w:left="360"/></w:pPr>
                <w:r><w:t>\(index + 1). \(xmlEscape(chapterTitle))</w:t></w:r>
            </w:p>
            """
        }

        return content
    }

    /// Generate chapter content as WordML
    private static func generateChapterContent(_ chapter: Chapter) -> String {
        var content = ""

        // Chapter title
        let chapterTitle = chapter.extractedTitle.isEmpty ? "Chapter" : chapter.extractedTitle
        content += """
        <w:p>
            <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
            <w:r><w:t>\(xmlEscape(chapterTitle))</w:t></w:r>
        </w:p>
        """

        // Chapter content
        let attributedContent = chapter.getAttributedContent()
        content += convertAttributedStringToWordML(attributedContent)

        return content
    }

    /// Convert NSAttributedString to WordML
    private static func convertAttributedStringToWordML(_ attributedString: NSAttributedString) -> String {
        var wordML = ""
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.enumerateAttributes(in: fullRange) { attributes, range, _ in
            let text = (attributedString.string as NSString).substring(with: range)

            // Skip empty text
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

            // Check for paragraph breaks
            if text.contains("\n") {
                let paragraphs = text.components(separatedBy: .newlines)
                for paragraph in paragraphs {
                    guard !paragraph.isEmpty else { continue }

                    var rPr = ""
                    if let font = attributes[.font] as? PlatformFont {
                        if font.isBold {
                            rPr += "<w:b/>"
                        }
                        if font.isItalic {
                            rPr += "<w:i/>"
                        }
                    }

                    let rPrTag = rPr.isEmpty ? "" : "<w:rPr>\(rPr)</w:rPr>"

                    wordML += """
                    <w:p>
                        <w:r>\(rPrTag)<w:t xml:space="preserve">\(xmlEscape(paragraph))</w:t></w:r>
                    </w:p>
                    """
                }
            } else {
                // Inline formatting
                var rPr = ""
                if let font = attributes[.font] as? PlatformFont {
                    if font.isBold {
                        rPr += "<w:b/>"
                    }
                    if font.isItalic {
                        rPr += "<w:i/>"
                    }
                }

                let rPrTag = rPr.isEmpty ? "" : "<w:rPr>\(rPr)</w:rPr>"

                wordML += """
                <w:p>
                    <w:r>\(rPrTag)<w:t xml:space="preserve">\(xmlEscape(text))</w:t></w:r>
                </w:p>
                """
            }
        }

        return wordML
    }

    /// Generate docProps/core.xml
    private static func generateCoreProperties(
        in directory: URL,
        metadata: ExportMetadata
    ) throws {
        let propsDir = directory.appendingPathComponent("docProps")
        try FileManager.default.createDirectory(at: propsDir, withIntermediateDirectories: true)

        let dateFormatter = ISO8601DateFormatter()
        let createdDate = dateFormatter.string(from: metadata.publishDate)

        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/">
            <dc:title>\(xmlEscape(metadata.title))</dc:title>
            <dc:creator>\(xmlEscape(metadata.author))</dc:creator>
            <dc:description>\(xmlEscape(metadata.description))</dc:description>
            <dc:subject>\(xmlEscape(metadata.genre))</dc:subject>
            <dcterms:created>\(createdDate)</dcterms:created>
            <cp:revision>1</cp:revision>
        </cp:coreProperties>
        """

        let fileURL = propsDir.appendingPathComponent("core.xml")
        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // MARK: - ZIP Archive Creation

    /// Create DOCX archive (ZIP file) from directory
    private static func createDOCXArchive(from sourceDir: URL, to destinationURL: URL) throws {
        #if canImport(ZIPFoundation)
        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)

        guard let archive = Archive(url: destinationURL, accessMode: .create) else {
            throw ExportError.fileWriteFailed
        }

        // Add all files to archive
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: sourceDir, includingPropertiesForKeys: nil)

        while let fileURL = enumerator?.nextObject() as? URL {
            guard !fileURL.hasDirectoryPath else { continue }

            let relativePath = fileURL.path.replacingOccurrences(
                of: sourceDir.path + "/",
                with: ""
            )

            try archive.addEntry(
                with: relativePath,
                relativeTo: sourceDir,
                compressionMethod: .deflate
            )
        }
        #else
        throw ExportError.conversionFailed("DOCX export requires ZIPFoundation package. Please add it via Xcode Package Dependencies.")
        #endif
    }

    // MARK: - Utilities

    /// Escape XML special characters
    private static func xmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
