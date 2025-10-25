//
//  ChapterMetadata.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftData

/// Chapter metadata container (SwiftData model)
///
/// Stores metadata for chapters including POV, scene details, status, and tags.
/// One-to-one relationship with Chapter.
@Model
final class ChapterMetadata {
    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// POV character name
    var povCharacter: String

    /// POV narrative style
    var povStyle: POVStyle

    /// Scene location/setting
    var sceneLocation: String

    /// Time of day for the scene
    var timeOfDay: String

    /// Story date/timeline position
    var storyDate: Date

    /// Chapter type (standard, prologue, epilogue, etc.)
    var chapterType: ChapterType

    /// Completion status
    var isCompleted: Bool

    /// Needs revision flag
    var needsRevision: Bool

    /// Additional notes
    var notes: String

    /// Tags for organization (stored as array)
    var tags: [String]

    /// Timestamp when created
    var dateCreated: Date

    /// Timestamp of most recent edit
    var lastModified: Date

    /// Reference to the parent chapter
    var chapter: Chapter?

    /// Initialize metadata with default values
    init(
        id: UUID = UUID(),
        povCharacter: String = "",
        povStyle: POVStyle = .thirdPerson,
        sceneLocation: String = "",
        timeOfDay: String = "",
        storyDate: Date = Date(),
        chapterType: ChapterType = .standard,
        isCompleted: Bool = false,
        needsRevision: Bool = false,
        notes: String = "",
        tags: [String] = [],
        dateCreated: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.povCharacter = povCharacter
        self.povStyle = povStyle
        self.sceneLocation = sceneLocation
        self.timeOfDay = timeOfDay
        self.storyDate = storyDate
        self.chapterType = chapterType
        self.isCompleted = isCompleted
        self.needsRevision = needsRevision
        self.notes = notes
        self.tags = tags
        self.dateCreated = dateCreated
        self.lastModified = lastModified
    }

    /// Get tags as a comma-separated string (for backward compatibility)
    var tagsString: String {
        tags.joined(separator: ", ")
    }

    /// Set tags from a comma-separated string (for backward compatibility)
    func setTagsFromString(_ string: String) {
        tags = string
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        lastModified = Date()
    }
}

/// Point of view narrative style
enum POVStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case firstPerson = "First Person"
    case secondPerson = "Second Person"
    case thirdPerson = "Third Person Limited"
    case thirdOmniscient = "Third Person Omniscient"

    var id: String { rawValue }
}

/// Chapter type/purpose
enum ChapterType: String, CaseIterable, Identifiable, Sendable, Codable {
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
enum CharacterRole: String, CaseIterable, Identifiable, Sendable, Codable {
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
enum TextFormat: Hashable, Equatable {
    case style(TextStyle)
    case bold, italic, underline, strikethrough
    case highlight(Color)
    case textColor(Color)
    case bulletList, numberedList, checklist
    case indent, outdent

    // Equatable implementation for Color comparison
    static func == (lhs: TextFormat, rhs: TextFormat) -> Bool {
        switch (lhs, rhs) {
        case (.style(let l), .style(let r)):
            return l == r
        case (.bold, .bold), (.italic, .italic), (.underline, .underline), (.strikethrough, .strikethrough):
            return true
        case (.highlight(let l), .highlight(let r)):
            return l == r
        case (.textColor(let l), .textColor(let r)):
            return l == r
        case (.bulletList, .bulletList), (.numberedList, .numberedList), (.checklist, .checklist):
            return true
        case (.indent, .indent), (.outdent, .outdent):
            return true
        default:
            return false
        }
    }

    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        switch self {
        case .style(let style):
            hasher.combine("style")
            hasher.combine(style)
        case .bold:
            hasher.combine("bold")
        case .italic:
            hasher.combine("italic")
        case .underline:
            hasher.combine("underline")
        case .strikethrough:
            hasher.combine("strikethrough")
        case .highlight(let color):
            hasher.combine("highlight")
            hasher.combine(color)
        case .textColor(let color):
            hasher.combine("textColor")
            hasher.combine(color)
        case .bulletList:
            hasher.combine("bulletList")
        case .numberedList:
            hasher.combine("numberedList")
        case .checklist:
            hasher.combine("checklist")
        case .indent:
            hasher.combine("indent")
        case .outdent:
            hasher.combine("outdent")
        }
    }

    /// Simple format types without associated values (for Set membership checking)
    var baseFormat: TextFormat {
        switch self {
        case .highlight:
            return .highlight(.yellow) // Default for comparison
        case .textColor:
            return .textColor(.primary) // Default for comparison
        default:
            return self
        }
    }
}
