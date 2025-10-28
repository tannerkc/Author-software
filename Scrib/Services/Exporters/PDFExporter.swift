//
//  PDFExporter.swift
//  Scrib
//
//  Created by Claude on 2025-01-23.
//

import Foundation
import PDFKit

#if canImport(UIKit)
import UIKit
fileprivate typealias PlatformFont = UIFont
fileprivate typealias PlatformColor = UIColor

// iOS: Add .labelColor extension to match macOS API
fileprivate extension UIColor {
    static var labelColor: UIColor { .label }
    static var secondaryLabelColor: UIColor { .secondaryLabel }
    static var tertiaryLabelColor: UIColor { .tertiaryLabel }
}
#elseif canImport(AppKit)
import AppKit
fileprivate typealias PlatformFont = NSFont
fileprivate typealias PlatformColor = NSColor
// macOS already has labelColor, secondaryLabelColor, tertiaryLabelColor
#endif

/// PDF export implementation using UIGraphicsPDFRenderer
/// - Swift 6.2 compliant with @MainActor isolation
@MainActor
enum PDFExporter {

    /// Export chapters to PDF format
    /// - Parameters:
    ///   - title: Document title
    ///   - chapters: Chapters to include
    ///   - configuration: Export configuration
    /// - Returns: URL of generated PDF file
    static func export(
        title: String,
        chapters: [Chapter],
        configuration: ExportConfiguration
    ) async throws -> URL {
        guard !chapters.isEmpty else {
            throw ExportError.emptyContent
        }

        let fileURL = ExportManager.temporaryFileURL(for: title, format: .pdf)
        let pageSize = configuration.pageSize.size
        let margins = configuration.pageSize.margins

        // Create PDF metadata
        let pdfMetadata: [String: Any] = [
            kCGPDFContextTitle as String: configuration.metadata.title,
            kCGPDFContextAuthor as String: configuration.metadata.author,
            kCGPDFContextSubject as String: configuration.metadata.description,
            kCGPDFContextCreator as String: "Scrib - Book Writing App",
            kCGPDFContextKeywords as String: configuration.metadata.genre
        ]

        // Configure PDF renderer
        #if os(iOS)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize),
            format: format
        )

        // Generate PDF data
        let pdfData = renderer.pdfData { context in
            var currentY: CGFloat = margins.top

            // Render cover page if requested
            if configuration.includeCoverPage {
                context.beginPage()
                currentY = renderCoverPage(
                    in: context,
                    pageSize: pageSize,
                    margins: margins.toUIEdgeInsets(),
                    metadata: configuration.metadata
                )
            }

            // Render table of contents if requested
            if configuration.includeTableOfContents && chapters.count > 1 {
                context.beginPage()
                currentY = renderTableOfContents(
                    in: context,
                    chapters: chapters,
                    pageSize: pageSize,
                    margins: margins.toUIEdgeInsets(),
                    configuration: configuration
                )
            }

            // Render chapters
            for (index, chapter) in chapters.enumerated() {
                // Start new page for each chapter (except first if no TOC/cover)
                if index > 0 || configuration.includeCoverPage || configuration.includeTableOfContents {
                    context.beginPage()
                    currentY = margins.top
                }

                currentY = renderChapter(
                    chapter,
                    in: context,
                    pageSize: pageSize,
                    margins: margins.toUIEdgeInsets(),
                    configuration: configuration,
                    startY: currentY
                )
            }
        }
        #else
        // macOS: Use PDFKit for PDF generation (simplified for now)
        let pdfData = createPDFWithPDFKit(
            chapters: chapters,
            configuration: configuration,
            pageSize: pageSize,
            margins: margins
        )
        #endif

        // Write PDF to file
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            throw ExportError.fileWriteFailed
        }
    }

    // MARK: - Rendering Methods

    #if os(iOS)
    /// Render cover page
    private static func renderCoverPage(
        in context: UIGraphicsPDFRendererContext,
        pageSize: CGSize,
        margins: UIEdgeInsets,
        metadata: ExportMetadata
    ) -> CGFloat {
        let contentWidth = pageSize.width - margins.left - margins.right
        let centerY = pageSize.height / 2

        // Title
        let titleFont = PlatformFont.systemFont(ofSize: 36, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: PlatformColor.labelColor
        ]
        let titleString = NSAttributedString(
            string: metadata.title,
            attributes: titleAttributes
        )
        let titleSize = titleString.size()
        let titleRect = CGRect(
            x: margins.left,
            y: centerY - 100,
            width: contentWidth,
            height: titleSize.height
        )
        titleString.draw(in: titleRect)

        // Author
        if !metadata.author.isEmpty {
            let authorFont = PlatformFont.systemFont(ofSize: 24, weight: .regular)
            let authorAttributes: [NSAttributedString.Key: Any] = [
                .font: authorFont,
                .foregroundColor: PlatformColor.secondaryLabelColor
            ]
            let authorString = NSAttributedString(
                string: "by \(metadata.author)",
                attributes: authorAttributes
            )
            let authorRect = CGRect(
                x: margins.left,
                y: centerY - 40,
                width: contentWidth,
                height: 30
            )
            authorString.draw(in: authorRect)
        }

        // Genre
        if !metadata.genre.isEmpty {
            let genreFont = PlatformFont.systemFont(ofSize: 14, weight: .medium)
            let genreAttributes: [NSAttributedString.Key: Any] = [
                .font: genreFont,
                .foregroundColor: PlatformColor.tertiaryLabelColor
            ]
            let genreString = NSAttributedString(
                string: metadata.genre,
                attributes: genreAttributes
            )
            let genreRect = CGRect(
                x: margins.left,
                y: centerY + 20,
                width: contentWidth,
                height: 20
            )
            genreString.draw(in: genreRect)
        }

        return pageSize.height - margins.bottom
    }

    /// Render table of contents
    private static func renderTableOfContents(
        in context: UIGraphicsPDFRendererContext,
        chapters: [Chapter],
        pageSize: CGSize,
        margins: UIEdgeInsets,
        configuration: ExportConfiguration
    ) -> CGFloat {
        let contentWidth = pageSize.width - margins.left - margins.right
        var currentY = margins.top

        // TOC Title
        let titleFont = PlatformFont.systemFont(ofSize: 24, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: PlatformColor.labelColor
        ]
        let titleString = NSAttributedString(
            string: "Table of Contents",
            attributes: titleAttributes
        )
        let titleRect = CGRect(
            x: margins.left,
            y: currentY,
            width: contentWidth,
            height: 30
        )
        titleString.draw(in: titleRect)
        currentY += 50

        // Chapter entries
        let entryFont = PlatformFont.systemFont(ofSize: 14, weight: .regular)
        let entryAttributes: [NSAttributedString.Key: Any] = [
            .font: entryFont,
            .foregroundColor: PlatformColor.labelColor
        ]

        for (index, chapter) in chapters.enumerated() {
            let chapterTitle = chapter.extractedTitle.isEmpty
                ? "Chapter \(index + 1)"
                : chapter.extractedTitle

            let entryString = NSAttributedString(
                string: "\(index + 1). \(chapterTitle)",
                attributes: entryAttributes
            )
            let entryRect = CGRect(
                x: margins.left + 20,
                y: currentY,
                width: contentWidth - 20,
                height: 20
            )
            entryString.draw(in: entryRect)
            currentY += 25
        }

        return currentY
    }

    /// Render a single chapter
    private static func renderChapter(
        _ chapter: Chapter,
        in context: UIGraphicsPDFRendererContext,
        pageSize: CGSize,
        margins: UIEdgeInsets,
        configuration: ExportConfiguration,
        startY: CGFloat
    ) -> CGFloat {
        let contentWidth = pageSize.width - margins.left - margins.right
        let maxHeight = pageSize.height - margins.top - margins.bottom
        var currentY = startY

        // Chapter title
        let titleFont = PlatformFont.systemFont(ofSize: 20, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: PlatformColor.labelColor
        ]
        let chapterTitle = chapter.extractedTitle.isEmpty
            ? "Chapter"
            : chapter.extractedTitle

        let titleString = NSAttributedString(
            string: chapterTitle,
            attributes: titleAttributes
        )
        let titleRect = CGRect(
            x: margins.left,
            y: currentY,
            width: contentWidth,
            height: 30
        )
        titleString.draw(in: titleRect)
        currentY += 50

        // Chapter content
        let content = chapter.getAttributedContent()
        let bodyFont = PlatformFont.systemFont(ofSize: CGFloat(configuration.fontSize))

        // Convert attributed string to use specified font
        let mutableContent = NSMutableAttributedString(attributedString: content)
        mutableContent.addAttribute(
            .font,
            value: bodyFont,
            range: NSRange(location: 0, length: mutableContent.length)
        )

        // Create framesetter for text layout
        let framesetter = CTFramesetterCreateWithAttributedString(mutableContent)

        var textPosition = 0
        let textLength = mutableContent.length

        while textPosition < textLength {
            let remainingRect = CGRect(
                x: margins.left,
                y: currentY,
                width: contentWidth,
                height: maxHeight - (currentY - margins.top)
            )

            let path = CGPath(rect: remainingRect, transform: nil)
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: textPosition, length: 0),
                path,
                nil
            )

            // Draw the frame
            context.cgContext.saveGState()
            context.cgContext.textMatrix = .identity
            context.cgContext.translateBy(x: 0, y: pageSize.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            CTFrameDraw(frame, context.cgContext)
            context.cgContext.restoreGState()

            // Get the visible range
            let visibleRange = CTFrameGetVisibleStringRange(frame)
            textPosition += visibleRange.length

            // Start new page if more content remains
            if textPosition < textLength {
                context.beginPage()
                currentY = margins.top
            } else {
                // Calculate final Y position
                let lines = CTFrameGetLines(frame) as! [CTLine]
                if !lines.isEmpty {
                    var origins = [CGPoint](repeating: .zero, count: 1)
                    CTFrameGetLineOrigins(frame, CFRange(location: lines.count - 1, length: 1), &origins)
                    let lastLineY = pageSize.height - origins[0].y
                    currentY = lastLineY + 20
                }
            }
        }

        return currentY
    }
    #endif

    // MARK: - macOS PDF Generation

    #if os(macOS)
    /// Create PDF using PDFKit (macOS implementation)
    private static func createPDFWithPDFKit(
        chapters: [Chapter],
        configuration: ExportConfiguration,
        pageSize: CGSize,
        margins: PageMargins
    ) -> Data {
        // Create PDF document
        let pdfDocument = PDFDocument()

        // Create a simple text representation for now
        // TODO: Implement full-featured PDFKit rendering matching iOS version
        var fullText = ""

        if configuration.includeCoverPage {
            fullText += "\(configuration.metadata.title)\n"
            fullText += "by \(configuration.metadata.author)\n\n\n"
        }

        for chapter in chapters {
            fullText += "\(chapter.title)\n\n"
            fullText += "\(chapter.content)\n\n"
        }

        // Create PDF page with text
        let pageRect = CGRect(origin: .zero, size: pageSize)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: PlatformFont.systemFont(ofSize: 12),
            .foregroundColor: PlatformColor.labelColor
        ]

        let attributedString = NSAttributedString(string: fullText, attributes: textAttributes)

        // Create PDF data
        let pdfData = NSMutableData()
        var mediaBox = pageRect
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        pdfContext.beginPDFPage(nil)
        pdfContext.textMatrix = CGAffineTransform.identity

        // Draw text (simplified - full implementation would handle pagination)
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)
        let textRect = CGRect(
            x: margins.left,
            y: margins.top,
            width: pageSize.width - margins.left - margins.right,
            height: pageSize.height - margins.top - margins.bottom
        )
        let path = CGPath(rect: textRect, transform: nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attributedString.length), path, nil)
        CTFrameDraw(frame, pdfContext)

        pdfContext.endPDFPage()
        pdfContext.closePDF()

        return pdfData as Data
    }
    #endif
}
