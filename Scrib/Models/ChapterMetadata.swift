//
//  ChapterMetadata.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftUI

/// Chapter metadata container
struct ChapterMetadata: Sendable {
    var povCharacter: String = ""
    var povStyle: POVStyle = .thirdPerson
    var sceneLocation: String = ""
    var timeOfDay: String = ""
    var storyDate: Date = Date()
    var chapterType: ChapterType = .standard
    var isCompleted: Bool = false
    var needsRevision: Bool = false
    var notes: String = ""
    var tagsString: String = ""

    var tags: [String] {
        tagsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

/// Point of view narrative style
enum POVStyle: String, CaseIterable, Identifiable, Sendable {
    case firstPerson = "First Person"
    case secondPerson = "Second Person"
    case thirdPerson = "Third Person Limited"
    case thirdOmniscient = "Third Person Omniscient"

    var id: String { rawValue }
}

/// Chapter type/purpose
enum ChapterType: String, CaseIterable, Identifiable, Sendable {
    case standard = "Standard"
    case prologue = "Prologue"
    case epilogue = "Epilogue"
    case interlude = "Interlude"
    case flashback = "Flashback"
    case note = "Author's Note"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .standard: return "doc.text"
        case .prologue: return "text.book.closed"
        case .epilogue: return "book.closed"
        case .interlude: return "music.note"
        case .flashback: return "arrow.uturn.backward"
        case .note: return "pencil.circle"
        }
    }
}

// MARK: - Character Marker Models

/// Represents a character marker in the manuscript
struct CharacterMarker: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let role: CharacterRole
    let markedText: String
    let notes: String
    let isNew: Bool
    let timestamp = Date()
}

/// Character role/type classifications
enum CharacterRole: String, CaseIterable, Identifiable, Sendable {
    case protagonist = "Protagonist"
    case antagonist = "Antagonist"
    case supporting = "Supporting"
    case minor = "Minor"
    case mentioned = "Mentioned"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .protagonist: return "star.fill"
        case .antagonist: return "bolt.fill"
        case .supporting: return "person.2.fill"
        case .minor: return "person.fill"
        case .mentioned: return "bubble.left"
        }
    }

    var color: Color {
        switch self {
        case .protagonist: return .blue
        case .antagonist: return .red
        case .supporting: return .green
        case .minor: return .orange
        case .mentioned: return .gray
        }
    }
}

// MARK: - Inline Note Models

/// Represents an inline note/annotation
struct InlineNote: Identifiable, Sendable {
    let id = UUID()
    let content: String
    let type: NoteType
    let priority: NotePriority
    let annotatedText: String
    let timestamp = Date()
}

/// Note type/category
enum NoteType: String, CaseIterable, Identifiable, Sendable {
    case general = "General"
    case research = "Research"
    case plotHole = "Plot Hole"
    case factCheck = "Fact Check"
    case revision = "Needs Revision"
    case idea = "Story Idea"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "note.text"
        case .research: return "book"
        case .plotHole: return "exclamationmark.triangle"
        case .factCheck: return "checkmark.circle"
        case .revision: return "pencil.circle"
        case .idea: return "lightbulb"
        }
    }

    var color: Color {
        switch self {
        case .general: return .gray
        case .research: return .blue
        case .plotHole: return .red
        case .factCheck: return .orange
        case .revision: return .purple
        case .idea: return .yellow
        }
    }
}

/// Note priority level
enum NotePriority: String, CaseIterable, Identifiable, Sendable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case urgent = "Urgent"

    var id: String { rawValue }
}

// MARK: - Text Formatting Models

/// Text style options matching iOS 26 Apple Notes
enum TextStyle: String, CaseIterable, Identifiable, Sendable {
    case title = "Title"
    case heading = "Heading"
    case subheading = "Subheading"
    case body = "Body"
    case monospaced = "Monospaced"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var font: Font {
        switch self {
        case .title: return .largeTitle
        case .heading: return .title
        case .subheading: return .title3
        case .body: return .body
        case .monospaced: return .body.monospaced()
        }
    }

    var weight: Font.Weight {
        switch self {
        case .title, .heading, .subheading: return .bold
        case .body, .monospaced: return .regular
        }
    }
}

/// Text formatting actions
enum TextFormat {
    case style(TextStyle)
    case bold, italic, underline, strikethrough
    case highlight(Color)
    case textColor(Color)
    case bulletList, numberedList, checklist
    case indent, outdent
}
