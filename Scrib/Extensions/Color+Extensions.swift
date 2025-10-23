//
//  Color+Extensions.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

extension Color {
    // MARK: - Scrib Brand Colors

    /// Primary brand color (blue, similar to Apple Notes)
    static let scribPrimary = Color.blue

    /// Accent color for interactive elements
    static let scribAccent = Color.blue

    // MARK: - Semantic Colors

    /// Background color for the editor
    static let editorBackground = Color(nsColor: .textBackgroundColor)

    /// Background color for the sidebar
    static let sidebarBackground = Color(nsColor: .controlBackgroundColor)

    /// Color for empty state text
    static let emptyStateText = Color.secondary

    /// Color for success indicators
    static let success = Color.green

    /// Color for warning indicators
    static let warning = Color.orange

    /// Color for error indicators
    static let error = Color.red

    // MARK: - Typography Colors

    /// Primary text color
    static let primaryText = Color.primary

    /// Secondary text color (for metadata, captions)
    static let secondaryText = Color.secondary

    /// Tertiary text color (for timestamps, subtle info)
    static let tertiaryText = Color(nsColor: .tertiaryLabelColor)

    // MARK: - UI Element Colors

    /// Divider color
    static let divider = Color(nsColor: .separatorColor)

    /// Selection color
    static let selection = Color.accentColor.opacity(0.2)
}

// MARK: - iOS Color Support
#if os(iOS)
extension Color {
    /// Background color for the editor
    static let editorBackground = Color(uiColor: .systemBackground)

    /// Background color for the sidebar
    static let sidebarBackground = Color(uiColor: .secondarySystemBackground)

    /// Tertiary text color (for timestamps, subtle info)
    static let tertiaryText = Color(uiColor: .tertiaryLabel)

    /// Divider color
    static let divider = Color(uiColor: .separator)
}
#endif
