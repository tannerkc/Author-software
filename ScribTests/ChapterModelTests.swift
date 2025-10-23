//
//  ChapterModelTests.swift
//  ScribTests
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Testing
import Foundation
@testable import Scrib

/// Unit tests for the Chapter model
struct ChapterModelTests {
    /// Test basic chapter initialization
    @Test func testChapterInitialization() {
        let chapter = Chapter(title: "Test Chapter", content: "Test content")

        #expect(chapter.title == "Test Chapter")
        #expect(chapter.content == "Test content")
        #expect(chapter.order == 0)
        #expect(chapter.book == nil)
    }

    /// Test word count calculation
    @Test func testWordCount() {
        let chapter = Chapter(
            title: "Test",
            content: "The quick brown fox jumps over the lazy dog"
        )

        #expect(chapter.wordCount == 9)
    }

    /// Test word count with multiple spaces
    @Test func testWordCountMultipleSpaces() {
        let chapter = Chapter(
            title: "Test",
            content: "Hello    world   with    multiple     spaces"
        )

        #expect(chapter.wordCount == 5)
    }

    /// Test word count with newlines
    @Test func testWordCountWithNewlines() {
        let chapter = Chapter(
            title: "Test",
            content: """
            First line
            Second line
            Third line
            """
        )

        #expect(chapter.wordCount == 6)
    }

    /// Test character count
    @Test func testCharacterCount() {
        let chapter = Chapter(title: "Test", content: "Hello!")

        #expect(chapter.characterCount == 6)
    }

    /// Test empty chapter detection
    @Test func testIsEmpty() {
        let emptyChapter = Chapter(title: "Empty", content: "")
        let whitespaceChapter = Chapter(title: "Whitespace", content: "   \n  ")
        let contentChapter = Chapter(title: "Content", content: "Hello")

        #expect(emptyChapter.isEmpty)
        #expect(whitespaceChapter.isEmpty)
        #expect(!contentChapter.isEmpty)
    }

    /// Test content preview
    @Test func testContentPreview() {
        let shortContent = "Short content"
        let longContent = String(repeating: "A", count: 150)

        let shortChapter = Chapter(title: "Short", content: shortContent)
        let longChapter = Chapter(title: "Long", content: longContent)

        #expect(shortChapter.contentPreview == shortContent)
        #expect(longChapter.contentPreview.count == 100)
    }

    /// Test update content method
    @Test func testUpdateContent() async {
        let chapter = Chapter(title: "Test", content: "Original content")
        let originalModified = chapter.lastModified

        // Wait to ensure timestamp difference
        try? await Task.sleep(for: .milliseconds(10))

        chapter.updateContent("New content")

        #expect(chapter.content == "New content")
        #expect(chapter.lastModified > originalModified)
    }

    /// Test update title method
    @Test func testUpdateTitle() async {
        let chapter = Chapter(title: "Original Title", content: "Content")
        let originalModified = chapter.lastModified

        // Wait to ensure timestamp difference
        try? await Task.sleep(for: .milliseconds(10))

        chapter.updateTitle("New Title")

        #expect(chapter.title == "New Title")
        #expect(chapter.lastModified > originalModified)
    }

    /// Test chapter comparison (by order)
    @Test func testChapterComparison() {
        let chapter1 = Chapter(title: "First", order: 0)
        let chapter2 = Chapter(title: "Second", order: 1)
        let chapter3 = Chapter(title: "Third", order: 2)

        #expect(chapter1 < chapter2)
        #expect(chapter2 < chapter3)
        #expect(chapter1 < chapter3)
    }
}
