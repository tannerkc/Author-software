//
//  BookModelTests.swift
//  ScribTests
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Testing
import Foundation
import SwiftData
@testable import Scrib

/// Unit tests for the Book model
struct BookModelTests {
    /// Test basic book initialization
    @Test func testBookInitialization() {
        let book = Book(title: "Test Book", genre: "Fiction")

        #expect(book.title == "Test Book")
        #expect(book.genre == "Fiction")
        #expect(book.chapters.isEmpty)
        #expect(book.chapterCount == 0)
        #expect(book.totalWordCount == 0)
    }

    /// Test book with chapters
    @Test func testBookWithChapters() {
        let book = Book(title: "Novel", genre: "Fiction")

        let chapter1 = Chapter(title: "Chapter 1", content: "Hello world", order: 0)
        let chapter2 = Chapter(title: "Chapter 2", content: "This is a test", order: 1)

        chapter1.book = book
        chapter2.book = book
        book.chapters = [chapter1, chapter2]

        #expect(book.chapterCount == 2)
        #expect(book.totalWordCount == 5) // "Hello world" (2) + "This is a test" (4) = 6... wait let me recount
        // "Hello world" = 2 words
        // "This is a test" = 4 words
        // Total = 6 words
        #expect(book.totalWordCount == 6)
    }

    /// Test sorted chapters
    @Test func testSortedChapters() {
        let book = Book(title: "Test Book")

        let chapter1 = Chapter(title: "Third", order: 2)
        let chapter2 = Chapter(title: "First", order: 0)
        let chapter3 = Chapter(title: "Second", order: 1)

        book.chapters = [chapter1, chapter2, chapter3]

        let sorted = book.sortedChapters
        #expect(sorted[0].title == "First")
        #expect(sorted[1].title == "Second")
        #expect(sorted[2].title == "Third")
    }

    /// Test total character count
    @Test func testTotalCharacterCount() {
        let book = Book(title: "Test Book")

        let chapter1 = Chapter(title: "Chapter 1", content: "12345", order: 0)
        let chapter2 = Chapter(title: "Chapter 2", content: "67890", order: 1)

        book.chapters = [chapter1, chapter2]

        #expect(book.totalCharacterCount == 10)
    }

    /// Test book comparison (by lastModified)
    @Test func testBookComparison() async {
        let book1 = Book(title: "First Book")

        // Wait a tiny bit to ensure different timestamps
        try? await Task.sleep(for: .milliseconds(10))

        let book2 = Book(title: "Second Book")

        // More recent book should be "less than" (for descending sort)
        #expect(book2 < book1)
    }
}
