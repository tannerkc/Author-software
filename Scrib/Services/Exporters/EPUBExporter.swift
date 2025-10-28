//
//  EPUBExporter.swift
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

/// EPUB export implementation using EPUB 3.0 specification
/// - Swift 6.2 compliant with @MainActor isolation
@MainActor
enum EPUBExporter {

    /// Export chapters to EPUB format
    /// - Parameters:
    ///   - title: Book title
    ///   - chapters: Chapters to include
    ///   - configuration: Export configuration
    /// - Returns: URL of generated EPUB file
    static func export(
        title: String,
        chapters: [Chapter],
        configuration: ExportConfiguration
    ) async throws -> URL {
        guard !chapters.isEmpty else {
            throw ExportError.emptyContent
        }

        let fileURL = ExportManager.temporaryFileURL(for: title, format: .epub)

        // Create temporary directory for EPUB structure
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try? FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Generate EPUB structure
        try await generateEPUBStructure(
            in: tempDir,
            title: title,
            chapters: chapters,
            configuration: configuration
        )

        // Create EPUB archive (special ZIP with mimetype first)
        try createEPUBArchive(from: tempDir, to: fileURL)

        return fileURL
    }

    // MARK: - EPUB Structure Generation

    /// Generate the complete EPUB 3.0 file structure
    private static func generateEPUBStructure(
        in directory: URL,
        title: String,
        chapters: [Chapter],
        configuration: ExportConfiguration
    ) async throws {
        // Create directory structure
        let metaInfDir = directory.appendingPathComponent("META-INF")
        let oebpsDir = directory.appendingPathComponent("OEBPS")
        let chaptersDir = oebpsDir.appendingPathComponent("chapters")
        let cssDir = oebpsDir.appendingPathComponent("css")

        try FileManager.default.createDirectory(at: metaInfDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: oebpsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: chaptersDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: cssDir, withIntermediateDirectories: true)

        // Generate required files
        try generateMimetype(in: directory)
        try generateContainerXML(in: metaInfDir)
        try generateStylesheet(in: cssDir, configuration: configuration)
        try generateContentOPF(
            in: oebpsDir,
            chapters: chapters,
            metadata: configuration.metadata
        )
        try generateTOCNCX(
            in: oebpsDir,
            chapters: chapters,
            metadata: configuration.metadata
        )
        try generateNavigationXHTML(
            in: oebpsDir,
            chapters: chapters,
            metadata: configuration.metadata
        )

        // Generate chapter files
        for (index, chapter) in chapters.enumerated() {
            try generateChapterXHTML(
                chapter: chapter,
                index: index,
                in: chaptersDir,
                configuration: configuration
            )
        }
    }

    /// Generate mimetype file (must be uncompressed, first in ZIP)
    private static func generateMimetype(in directory: URL) throws {
        let content = "application/epub+zip"
        let fileURL = directory.appendingPathComponent("mimetype")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate META-INF/container.xml
    private static func generateContainerXML(in metaInfDir: URL) throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
            <rootfiles>
                <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
            </rootfiles>
        </container>
        """

        let fileURL = metaInfDir.appendingPathComponent("container.xml")
        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate CSS stylesheet
    private static func generateStylesheet(
        in cssDir: URL,
        configuration: ExportConfiguration
    ) throws {
        let fontSize = configuration.fontSize
        let lineHeight = configuration.lineSpacing

        let css = """
        body {
            font-family: Georgia, serif;
            font-size: \(fontSize)pt;
            line-height: \(lineHeight);
            margin: 2em;
            text-align: justify;
        }

        h1 {
            font-size: 2em;
            font-weight: bold;
            margin: 1.5em 0 1em 0;
            text-align: left;
        }

        h2 {
            font-size: 1.5em;
            font-weight: bold;
            margin: 1.2em 0 0.8em 0;
            text-align: left;
        }

        p {
            margin: 0;
            text-indent: 1.5em;
        }

        p.first {
            text-indent: 0;
        }

        .cover {
            text-align: center;
            margin-top: 3em;
        }

        .cover h1 {
            font-size: 3em;
            margin-bottom: 0.5em;
        }

        .cover .author {
            font-size: 1.5em;
            font-style: italic;
            margin-top: 1em;
        }

        .toc {
            margin: 2em 0;
        }

        .toc ul {
            list-style-type: none;
            padding-left: 0;
        }

        .toc li {
            margin: 0.5em 0;
        }

        .toc a {
            text-decoration: none;
            color: #000;
        }

        strong {
            font-weight: bold;
        }

        em {
            font-style: italic;
        }
        """

        let fileURL = cssDir.appendingPathComponent("style.css")
        try css.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate OEBPS/content.opf (package document)
    private static func generateContentOPF(
        in oebpsDir: URL,
        chapters: [Chapter],
        metadata: ExportMetadata
    ) throws {
        let uuid = UUID().uuidString
        let dateFormatter = ISO8601DateFormatter()
        let modifiedDate = dateFormatter.string(from: Date())

        // Build manifest items
        var manifestItems = """
            <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
            <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
            <item id="css" href="css/style.css" media-type="text/css"/>
        """

        for (index, _) in chapters.enumerated() {
            manifestItems += """
            \n    <item id="chapter\(index + 1)" href="chapters/chapter\(index + 1).xhtml" media-type="application/xhtml+xml"/>
            """
        }

        // Build spine itemrefs
        var spineItemrefs = ""
        for (index, _) in chapters.enumerated() {
            spineItemrefs += """
            \n    <itemref idref="chapter\(index + 1)"/>
            """
        }

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uuid_id">
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
                <dc:identifier id="uuid_id">urn:uuid:\(uuid)</dc:identifier>
                <dc:title>\(xmlEscape(metadata.title))</dc:title>
                <dc:creator>\(xmlEscape(metadata.author))</dc:creator>
                <dc:language>\(metadata.language)</dc:language>
                <dc:subject>\(xmlEscape(metadata.genre))</dc:subject>
                <dc:description>\(xmlEscape(metadata.description))</dc:description>
                <dc:publisher>\(xmlEscape(metadata.publisher))</dc:publisher>
                <dc:date>\(dateFormatter.string(from: metadata.publishDate))</dc:date>
                <meta property="dcterms:modified">\(modifiedDate)</meta>
            </metadata>
            <manifest>
        \(manifestItems)
            </manifest>
            <spine toc="ncx">
        \(spineItemrefs)
            </spine>
        </package>
        """

        let fileURL = oebpsDir.appendingPathComponent("content.opf")
        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate OEBPS/toc.ncx (NCX navigation for EPUB 2 compatibility)
    private static func generateTOCNCX(
        in oebpsDir: URL,
        chapters: [Chapter],
        metadata: ExportMetadata
    ) throws {
        let uuid = UUID().uuidString

        var navPoints = ""
        for (index, chapter) in chapters.enumerated() {
            let chapterTitle = chapter.extractedTitle.isEmpty
                ? "Chapter \(index + 1)"
                : chapter.extractedTitle

            navPoints += """
            \n    <navPoint id="chapter\(index + 1)" playOrder="\(index + 1)">
                  <navLabel>
                    <text>\(xmlEscape(chapterTitle))</text>
                  </navLabel>
                  <content src="chapters/chapter\(index + 1).xhtml"/>
                </navPoint>
            """
        }

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
            <head>
                <meta name="dtb:uid" content="urn:uuid:\(uuid)"/>
                <meta name="dtb:depth" content="1"/>
                <meta name="dtb:totalPageCount" content="0"/>
                <meta name="dtb:maxPageNumber" content="0"/>
            </head>
            <docTitle>
                <text>\(xmlEscape(metadata.title))</text>
            </docTitle>
            <navMap>
        \(navPoints)
            </navMap>
        </ncx>
        """

        let fileURL = oebpsDir.appendingPathComponent("toc.ncx")
        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate OEBPS/nav.xhtml (EPUB 3 navigation document)
    private static func generateNavigationXHTML(
        in oebpsDir: URL,
        chapters: [Chapter],
        metadata: ExportMetadata
    ) throws {
        var tocList = ""
        for (index, chapter) in chapters.enumerated() {
            let chapterTitle = chapter.extractedTitle.isEmpty
                ? "Chapter \(index + 1)"
                : chapter.extractedTitle

            tocList += """
            \n        <li><a href="chapters/chapter\(index + 1).xhtml">\(xmlEscape(chapterTitle))</a></li>
            """
        }

        let xhtml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
        <head>
            <title>Table of Contents</title>
            <link rel="stylesheet" type="text/css" href="css/style.css"/>
        </head>
        <body>
            <nav epub:type="toc" id="toc">
                <h1>Table of Contents</h1>
                <ol>
        \(tocList)
                </ol>
            </nav>
        </body>
        </html>
        """

        let fileURL = oebpsDir.appendingPathComponent("nav.xhtml")
        try xhtml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Generate individual chapter XHTML file
    private static func generateChapterXHTML(
        chapter: Chapter,
        index: Int,
        in chaptersDir: URL,
        configuration: ExportConfiguration
    ) throws {
        let chapterTitle = chapter.extractedTitle.isEmpty
            ? "Chapter \(index + 1)"
            : chapter.extractedTitle

        // Convert chapter content to HTML
        let attributedContent = chapter.getAttributedContent()
        let htmlContent = convertAttributedStringToHTML(attributedContent)

        let xhtml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <title>\(xmlEscape(chapterTitle))</title>
            <link rel="stylesheet" type="text/css" href="../css/style.css"/>
        </head>
        <body>
            <h1>\(xmlEscape(chapterTitle))</h1>
            \(htmlContent)
        </body>
        </html>
        """

        let fileURL = chaptersDir.appendingPathComponent("chapter\(index + 1).xhtml")
        try xhtml.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // MARK: - EPUB Archive Creation

    /// Create EPUB archive (special ZIP with mimetype uncompressed first)
    private static func createEPUBArchive(from sourceDir: URL, to destinationURL: URL) throws {
        #if canImport(ZIPFoundation)
        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)

        guard let archive = Archive(url: destinationURL, accessMode: .create) else {
            throw ExportError.fileWriteFailed
        }

        // Add mimetype first (uncompressed, as per EPUB spec)
        let mimetypeURL = sourceDir.appendingPathComponent("mimetype")
        try archive.addEntry(
            with: "mimetype",
            relativeTo: sourceDir,
            compressionMethod: .none // IMPORTANT: mimetype must be uncompressed
        )

        // Add all other files (compressed)
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: sourceDir, includingPropertiesForKeys: nil)

        while let fileURL = enumerator?.nextObject() as? URL {
            guard !fileURL.hasDirectoryPath else { continue }

            // Skip mimetype (already added)
            if fileURL.lastPathComponent == "mimetype" {
                continue
            }

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
        throw ExportError.conversionFailed("EPUB export requires ZIPFoundation package. Please add it via Xcode Package Dependencies.")
        #endif
    }

    // MARK: - Utilities

    /// Convert NSAttributedString to HTML
    private static func convertAttributedStringToHTML(_ attributedString: NSAttributedString) -> String {
        var html = ""
        let fullRange = NSRange(location: 0, length: attributedString.length)
        var isFirstParagraph = true

        attributedString.enumerateAttributes(in: fullRange) { attributes, range, _ in
            let text = (attributedString.string as NSString).substring(with: range)

            // Skip empty text
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

            // Check for paragraph breaks
            if text.contains("\n") {
                let paragraphs = text.components(separatedBy: .newlines)
                for paragraph in paragraphs {
                    guard !paragraph.isEmpty else { continue }

                    let className = isFirstParagraph ? " class=\"first\"" : ""
                    var content = xmlEscape(paragraph)

                    // Apply formatting
                    if let font = attributes[.font] as? PlatformFont {
                        if font.isBold {
                            content = "<strong>\(content)</strong>"
                        }
                        if font.isItalic {
                            content = "<em>\(content)</em>"
                        }
                    }

                    html += "<p\(className)>\(content)</p>\n    "
                    isFirstParagraph = false
                }
            } else {
                // Inline text
                var content = xmlEscape(text)

                // Apply formatting
                if let font = attributes[.font] as? PlatformFont {
                    if font.isBold {
                        content = "<strong>\(content)</strong>"
                    }
                    if font.isItalic {
                        content = "<em>\(content)</em>"
                    }
                }

                let className = isFirstParagraph ? " class=\"first\"" : ""
                html += "<p\(className)>\(content)</p>\n    "
                isFirstParagraph = false
            }
        }

        return html.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Escape XML/HTML special characters
    private static func xmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
