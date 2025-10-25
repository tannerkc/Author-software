//
//  Character.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData
import SwiftUI

/// Represents a character in the book
///
/// Characters are tracked separately from the manuscript to maintain
/// consistency and provide quick reference. Used in POV selection and
/// character mentions throughout the writing process.
@Model
final class Character {
    /// Unique identifier for the character
    @Attribute(.unique) var id: UUID

    /// Character's name
    var name: String

    /// Character's role in the story
    var role: CharacterRole

    /// Physical description
    var physicalDescription: String

    /// Personality traits
    var personality: String

    /// Character's backstory
    var backstory: String

    /// Character's goals and motivations
    var goals: String

    /// Character arc notes
    var arcNotes: String

    /// Relationships with other characters
    var relationships: String

    /// Additional notes
    var notes: String

    /// Sort order (0-indexed)
    var order: Int

    /// Timestamp when created
    var dateCreated: Date

    /// Timestamp of most recent edit
    var lastModified: Date

    /// Reference to the parent book
    var book: Book?

    /// Color label for visual organization
    var colorLabel: String

    /// Age (optional)
    var age: String

    /// Occupation (optional)
    var occupation: String

    /// Initialize a new character
    init(
        id: UUID = UUID(),
        name: String,
        role: CharacterRole = .supporting,
        physicalDescription: String = "",
        personality: String = "",
        backstory: String = "",
        goals: String = "",
        arcNotes: String = "",
        relationships: String = "",
        notes: String = "",
        order: Int = 0,
        dateCreated: Date = Date(),
        lastModified: Date = Date(),
        colorLabel: String = "",
        age: String = "",
        occupation: String = ""
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.physicalDescription = physicalDescription
        self.personality = personality
        self.backstory = backstory
        self.goals = goals
        self.arcNotes = arcNotes
        self.relationships = relationships
        self.notes = notes
        self.order = order
        self.dateCreated = dateCreated
        self.lastModified = lastModified
        self.colorLabel = colorLabel
        self.age = age
        self.occupation = occupation
    }

    /// Returns true if character has minimal information
    var isEmpty: Bool {
        name.isEmpty && physicalDescription.isEmpty && personality.isEmpty
    }

    /// Summary for quick reference
    var summary: String {
        var parts: [String] = []
        if !age.isEmpty { parts.append(age) }
        if !occupation.isEmpty { parts.append(occupation) }
        if !parts.isEmpty {
            return parts.joined(separator: ", ")
        }
        return role.rawValue
    }
}

// MARK: - Comparable
extension Character: Comparable {
    static func < (lhs: Character, rhs: Character) -> Bool {
        // Sort by role first (protagonist → antagonist → supporting → minor → mentioned)
        if lhs.role != rhs.role {
            return lhs.role.sortOrder < rhs.role.sortOrder
        }
        // Then by custom order
        return lhs.order < rhs.order
    }
}

// MARK: - Helper Methods
extension Character {
    /// Update any field and refresh the lastModified timestamp
    func markAsModified() {
        lastModified = Date()
    }
}

// MARK: - CharacterRole Extension
extension CharacterRole {
    var sortOrder: Int {
        switch self {
        case .protagonist: return 0
        case .antagonist: return 1
        case .supporting: return 2
        case .minor: return 3
        case .mentioned: return 4
        }
    }
}
