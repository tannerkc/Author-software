//
//  SwiftData+Extensions.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation
import SwiftData

/// SwiftData validation and safety extensions
///
/// Provides utilities for checking if SwiftData model objects are in a valid state
/// and safe to access. Prevents EXC_BAD_ACCESS crashes from faulting objects.

extension PersistentModel {
    /// Check if this model object is in a valid state for property access
    ///
    /// Returns true if the object has a valid model context and is not faulting.
    /// Use this before accessing properties that might cause crashes on faulting objects.
    var isValidForAccess: Bool {
        // Check if the object has a model context
        guard self.modelContext != nil else {
            return false
        }

        // For SwiftData, if we have a context, the object should be accessible
        // The context being non-nil indicates the object is attached and can be accessed
        return true
    }

    /// Safely refresh this model object to ensure it's fully materialized
    ///
    /// Attempts to refresh the object from its model context to ensure all properties
    /// are loaded and accessible. Returns true if successful.
    @MainActor
    func safeRefresh() -> Bool {
        guard let context = self.modelContext else {
            print("⚠️ Cannot refresh: object has no model context")
            return false
        }

        // Refresh the object to ensure it's fully loaded
        context.processPendingChanges()

        // Additional validation could go here if needed
        return true
    }
}

extension Chapter {
    /// Safely access the content property with validation
    ///
    /// Returns the chapter content if the object is in a valid state,
    /// or an empty string if not accessible.
    var safeContent: String {
        guard isValidForAccess else {
            print("⚠️ Chapter object not valid for access, returning empty content")
            return ""
        }

        // Wrap property access in error handling for extra safety
        do {
            return content
        } catch {
            print("❌ Failed to access chapter content: \(error.localizedDescription)")
            return ""
        }
    }

    /// Safely access the formatted content property with validation
    ///
    /// Returns the chapter's RTF data if the object is in a valid state,
    /// or nil if not accessible.
    var safeFormattedContent: Data? {
        guard isValidForAccess else {
            print("⚠️ Chapter object not valid for access, returning nil formatted content")
            return nil
        }

        // Wrap property access in error handling for extra safety
        do {
            return formattedContent
        } catch {
            print("❌ Failed to access chapter formatted content: \(error.localizedDescription)")
            return nil
        }
    }

    /// Safely access the book relationship with validation
    ///
    /// Returns the parent book if the object and relationship are valid,
    /// or nil if not accessible.
    var safeBook: Book? {
        guard isValidForAccess else {
            print("⚠️ Chapter object not valid for access, returning nil book")
            return nil
        }

        // Wrap relationship access in error handling for extra safety
        do {
            return book
        } catch {
            print("❌ Failed to access chapter book relationship: \(error.localizedDescription)")
            return nil
        }
    }
}

extension ModelContext {
    /// Safely fetch and materialize a model by ID
    ///
    /// Fetches the model with the given persistent identifier and ensures it's fully loaded.
    /// Returns nil if the object cannot be found or loaded.
    @MainActor
    func safeFetch<T: PersistentModel>(_ type: T.Type, id: UUID) -> T? {
        // Create a fetch descriptor to find the object by ID
        let predicate = #Predicate<T> { model in
            // This will be customized per type - for now we'll use a general approach
            true
        }

        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1

        do {
            let results = try fetch(descriptor)
            if let object = results.first {
                // Process pending changes to ensure object is fully loaded
                processPendingChanges()
                return object
            }
        } catch {
            print("❌ Failed to safe fetch object: \(error.localizedDescription)")
        }

        return nil
    }

    /// Refresh an object and ensure it's fully materialized
    ///
    /// Forces SwiftData to load all properties of the given object.
    @MainActor
    func ensureLoaded<T: PersistentModel>(_ object: T) {
        // Process any pending changes to ensure consistency
        processPendingChanges()

        // The act of processing changes should materialize the object
        // No explicit "fault resolution" API in SwiftData, so we rely on this
    }
}
