//
//  MaterialViewModel.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData
import Observation

/// ViewModel for managing material items (scenes, notes, research, characters)
///
/// Provides CRUD operations and search functionality for all material types
/// that support the book writing process beyond the main manuscript.
@MainActor
@Observable
final class MaterialViewModel {
    private let modelContext: ModelContext

    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Scene Operations

    /// Create a new scene in the specified book
    func createScene(
        in book: Book,
        title: String = "Untitled Scene",
        content: String = "",
        synopsis: String = "",
        povCharacter: String = "",
        location: String = ""
    ) -> Scene {
        let order = book.scenes.count
        let scene = Scene(
            title: title,
            content: content,
            order: order,
            synopsis: synopsis,
            povCharacter: povCharacter,
            location: location
        )

        scene.book = book
        book.scenes.append(scene)
        book.lastModified = Date()

        modelContext.insert(scene)
        save()

        return scene
    }

    /// Update scene content
    func updateScene(_ scene: Scene, content: String) {
        scene.updateContent(content)
        scene.book?.lastModified = Date()
        save()
    }

    /// Delete a scene
    func deleteScene(_ scene: Scene) {
        if let book = scene.book {
            book.scenes.removeAll { $0.id == scene.id }
            book.lastModified = Date()
        }
        modelContext.delete(scene)
        save()
    }

    /// Reorder scenes
    func reorderScenes(in book: Book, from source: IndexSet, to destination: Int) {
        var scenes = book.sortedScenes
        scenes.move(fromOffsets: source, toOffset: destination)

        // Update order property
        for (index, scene) in scenes.enumerated() {
            scene.order = index
        }

        book.lastModified = Date()
        save()
    }

    // MARK: - Note Operations

    /// Create a new note in the specified book
    func createNote(
        in book: Book,
        title: String = "Untitled Note",
        content: String = "",
        category: NoteCategory = .general,
        tags: [String] = []
    ) -> Note {
        let order = book.notes.count
        let note = Note(
            title: title,
            content: content,
            order: order,
            category: category,
            tags: tags
        )

        note.book = book
        book.notes.append(note)
        book.lastModified = Date()

        modelContext.insert(note)
        save()

        return note
    }

    /// Update note content
    func updateNote(_ note: Note, content: String) {
        note.updateContent(content)
        note.book?.lastModified = Date()
        save()
    }

    /// Toggle note pinned status
    func toggleNotePinned(_ note: Note) {
        note.isPinned.toggle()
        note.lastModified = Date()
        note.book?.lastModified = Date()
        save()
    }

    /// Delete a note
    func deleteNote(_ note: Note) {
        if let book = note.book {
            book.notes.removeAll { $0.id == note.id }
            book.lastModified = Date()
        }
        modelContext.delete(note)
        save()
    }

    // MARK: - Research Operations

    /// Create a new research item in the specified book
    func createResearchItem(
        in book: Book,
        title: String = "Untitled Research",
        content: String = "",
        itemType: ResearchItemType = .general,
        source: String = "",
        tags: [String] = []
    ) -> ResearchItem {
        let order = book.researchItems.count
        let item = ResearchItem(
            title: title,
            content: content,
            order: order,
            itemType: itemType,
            source: source,
            tags: tags
        )

        item.book = book
        book.researchItems.append(item)
        book.lastModified = Date()

        modelContext.insert(item)
        save()

        return item
    }

    /// Update research item content
    func updateResearchItem(_ item: ResearchItem, content: String) {
        item.updateContent(content)
        item.book?.lastModified = Date()
        save()
    }

    /// Delete a research item
    func deleteResearchItem(_ item: ResearchItem) {
        if let book = item.book {
            book.researchItems.removeAll { $0.id == item.id }
            book.lastModified = Date()
        }
        modelContext.delete(item)
        save()
    }

    // MARK: - Character Operations

    /// Create a new character in the specified book
    func createCharacter(
        in book: Book,
        name: String = "Untitled Character",
        role: CharacterRole = .supporting,
        physicalDescription: String = "",
        personality: String = ""
    ) -> Character {
        let order = book.characters.count
        let character = Character(
            name: name,
            role: role,
            physicalDescription: physicalDescription,
            personality: personality,
            order: order
        )

        character.book = book
        book.characters.append(character)
        book.lastModified = Date()

        modelContext.insert(character)
        save()

        return character
    }

    /// Update character
    func updateCharacter(_ character: Character) {
        character.markAsModified()
        character.book?.lastModified = Date()
        save()
    }

    /// Delete a character
    func deleteCharacter(_ character: Character) {
        if let book = character.book {
            book.characters.removeAll { $0.id == character.id }
            book.lastModified = Date()
        }
        modelContext.delete(character)
        save()
    }

    // MARK: - Search Operations

    /// Search scenes by title or content
    func searchScenes(query: String) -> [Scene] {
        let descriptor = FetchDescriptor<Scene>(
            predicate: #Predicate { scene in
                scene.title.localizedStandardContains(query) ||
                scene.content.localizedStandardContains(query)
            }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Search notes by title or content
    func searchNotes(query: String) -> [Note] {
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { note in
                note.title.localizedStandardContains(query) ||
                note.content.localizedStandardContains(query)
            }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Search research items by title or content
    func searchResearchItems(query: String) -> [ResearchItem] {
        let descriptor = FetchDescriptor<ResearchItem>(
            predicate: #Predicate { item in
                item.title.localizedStandardContains(query) ||
                item.content.localizedStandardContains(query)
            }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Search characters by name
    func searchCharacters(query: String) -> [Character] {
        let descriptor = FetchDescriptor<Character>(
            predicate: #Predicate { character in
                character.name.localizedStandardContains(query)
            }
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Fetch Operations

    /// Fetch all scenes for a book
    func fetchScenes(for book: Book) -> [Scene] {
        book.sortedScenes
    }

    /// Fetch all notes for a book
    func fetchNotes(for book: Book) -> [Note] {
        book.sortedNotes
    }

    /// Fetch all research items for a book
    func fetchResearchItems(for book: Book) -> [ResearchItem] {
        book.sortedResearchItems
    }

    /// Fetch all characters for a book
    func fetchCharacters(for book: Book) -> [Character] {
        book.sortedCharacters
    }

    // MARK: - Utility

    /// Save the model context
    private func save() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print("❌ MaterialViewModel save error: \(error)")
        }
    }

    /// Duplicate a scene
    func duplicateScene(_ scene: Scene) -> Scene? {
        guard let book = scene.book else { return nil }

        let duplicate = Scene(
            title: "\(scene.title) Copy",
            content: scene.content,
            order: book.scenes.count,
            synopsis: scene.synopsis,
            status: scene.status,
            povCharacter: scene.povCharacter,
            location: scene.location,
            timeOfDay: scene.timeOfDay,
            storyDate: scene.storyDate,
            colorLabel: scene.colorLabel
        )

        duplicate.book = book
        book.scenes.append(duplicate)
        book.lastModified = Date()

        modelContext.insert(duplicate)
        save()

        return duplicate
    }

    /// Duplicate a note
    func duplicateNote(_ note: Note) -> Note? {
        guard let book = note.book else { return nil }

        let duplicate = Note(
            title: "\(note.title) Copy",
            content: note.content,
            order: book.notes.count,
            category: note.category,
            tags: note.tags,
            colorLabel: note.colorLabel,
            isPinned: false
        )

        duplicate.book = book
        book.notes.append(duplicate)
        book.lastModified = Date()

        modelContext.insert(duplicate)
        save()

        return duplicate
    }
}
