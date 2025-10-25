//
//  EditMode+macOS.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

// MARK: - EditMode for macOS

#if os(macOS)

/// SwiftUI EditMode implementation for macOS
///
/// Provides a macOS-compatible EditMode that mirrors the iOS API exactly,
/// allowing views to use identical code across platforms. While macOS
/// doesn't have a native EditMode concept, this implementation provides
/// the same API surface for consistency.
///
/// Swift 6.1 Best Practice: Sendable conformance for thread safety.
///
/// Usage:
/// ```swift
/// @Environment(\.editMode) private var editMode
///
/// Button("Edit") {
///     editMode?.wrappedValue = .active
/// }
/// ```
@available(macOS 26.0, *)
public enum EditMode: Equatable, Sendable {
    /// Inactive edit mode (default, read-only state)
    case inactive

    /// Active edit mode (editing enabled)
    case active

    /// Transient mode (used during transitions)
    case transient

    /// Whether edit mode is currently active
    public var isEditing: Bool {
        self == .active
    }
}

// MARK: - Environment Key

@available(macOS 26.0, *)
private struct EditModeKey: EnvironmentKey {
    static let defaultValue: Binding<EditMode>? = nil
}

@available(macOS 26.0, *)
extension EnvironmentValues {
    /// Edit mode environment value
    ///
    /// Provides access to the current edit mode state via SwiftUI environment.
    /// Returns nil if no edit mode binding is provided in the view hierarchy.
    ///
    /// Usage:
    /// ```swift
    /// @Environment(\.editMode) private var editMode
    ///
    /// var body: some View {
    ///     if editMode?.wrappedValue.isEditing == true {
    ///         Text("Editing...")
    ///     }
    /// }
    /// ```
    public var editMode: Binding<EditMode>? {
        get { self[EditModeKey.self] }
        set { self[EditModeKey.self] = newValue }
    }
}

// MARK: - View Extension

@available(macOS 26.0, *)
extension View {
    /// Provides an edit mode binding to child views
    ///
    /// This modifier makes an edit mode binding available to all
    /// descendant views through the SwiftUI environment.
    ///
    /// - Parameter editMode: Binding to the edit mode state
    /// - Returns: Modified view with edit mode in environment
    ///
    /// Usage:
    /// ```swift
    /// @State private var editMode = EditMode(.inactive)
    ///
    /// var body: some View {
    ///     MyListView()
    ///         .environment(\.editMode, $editMode)
    /// }
    /// ```
    public func environment(editMode: Binding<EditMode>) -> some View {
        self.environment(\.editMode, editMode)
    }
}

// MARK: - Binding Extension

@available(macOS 26.0, *)
extension Binding where Value == EditMode {
    /// Convenience property to check if editing
    public var isEditing: Bool {
        wrappedValue.isEditing
    }

    /// Convenience method to toggle between active and inactive
    public func toggle() {
        wrappedValue = (wrappedValue == .active) ? .inactive : .active
    }
}

#endif

// MARK: - Cross-Platform EditMode Utilities

/// Helper functions for working with EditMode across platforms
public enum EditModeHelpers {

    /// Check if edit mode is available on the current platform
    public static var isAvailable: Bool {
        #if os(iOS)
        return true
        #elseif os(macOS)
        if #available(macOS 26.0, *) {
            return true
        }
        return false
        #else
        return false
        #endif
    }

    /// Create a platform-appropriate edit mode state
    ///
    /// - Returns: State wrapper for EditMode
    #if os(iOS)
    public static func createState() -> State<SwiftUI.EditMode> {
        State(initialValue: .inactive)
    }
    #elseif os(macOS)
    @available(macOS 26.0, *)
    public static func createState() -> State<EditMode> {
        State(initialValue: .inactive)
    }
    #endif
}

// MARK: - Platform-Specific Extensions

#if os(iOS)
extension SwiftUI.EditMode {
    /// Whether edit mode is currently active
    public var isEditing: Bool {
        self == .active
    }
}
#endif
