//
//  Color+Platform.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Cross-Platform System Colors

/// Elegant cross-platform color extensions
///
/// Provides unified access to system colors across iOS and macOS,
/// abstracting away platform differences. All colors automatically
/// adapt to light/dark mode and respect system accessibility settings.
///
/// Swift 6.1 Best Practice: Single source of truth for platform colors
/// eliminates scattered #if os() conditionals throughout the codebase.
extension Color {

    // MARK: - Background Colors

    /// Primary system background color
    ///
    /// - iOS: UIColor.systemBackground (pure white/black based on mode)
    /// - macOS: NSColor.windowBackgroundColor (system window background)
    static var systemBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.white
        #endif
    }

    /// Secondary background color (for grouped content)
    ///
    /// - iOS: UIColor.systemGroupedBackground (slightly off-white/black)
    /// - macOS: NSColor.controlBackgroundColor (control background)
    static var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(white: 0.95)
        #endif
    }

    /// Secondary system background (for layered content)
    ///
    /// - iOS: UIColor.secondarySystemBackground
    /// - macOS: NSColor.controlBackgroundColor with slight opacity variation
    static var secondarySystemBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(white: 0.9)
        #endif
    }

    /// Tertiary system background (for deeply nested content)
    ///
    /// - iOS: UIColor.tertiarySystemBackground
    /// - macOS: NSColor.textBackgroundColor
    static var tertiarySystemBackground: Color {
        #if os(iOS)
        return Color(uiColor: .tertiarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(white: 0.85)
        #endif
    }

    // MARK: - Fill Colors

    /// Primary system fill color (for buttons, controls)
    ///
    /// - iOS: UIColor.systemFill
    /// - macOS: NSColor.controlColor
    static var systemFill: Color {
        #if os(iOS)
        return Color(uiColor: .systemFill)
        #elseif os(macOS)
        return Color(nsColor: .controlColor)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }

    /// Secondary system fill color
    ///
    /// - iOS: UIColor.secondarySystemFill
    /// - macOS: NSColor.secondaryControlColor
    static var secondarySystemFill: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemFill)
        #elseif os(macOS)
        return Color(nsColor: .controlColor).opacity(0.5)
        #else
        return Color.gray.opacity(0.16)
        #endif
    }

    // MARK: - Label Colors

    /// Primary label color (standard text)
    ///
    /// - iOS: UIColor.label
    /// - macOS: NSColor.labelColor
    static var label: Color {
        #if os(iOS)
        return Color(uiColor: .label)
        #elseif os(macOS)
        return Color(nsColor: .labelColor)
        #else
        return Color.black
        #endif
    }

    /// Secondary label color (less prominent text)
    ///
    /// - iOS: UIColor.secondaryLabel
    /// - macOS: NSColor.secondaryLabelColor
    static var secondaryLabel: Color {
        #if os(iOS)
        return Color(uiColor: .secondaryLabel)
        #elseif os(macOS)
        return Color(nsColor: .secondaryLabelColor)
        #else
        return Color.gray
        #endif
    }

    /// Tertiary label color (even less prominent text)
    ///
    /// - iOS: UIColor.tertiaryLabel
    /// - macOS: NSColor.tertiaryLabelColor
    static var tertiaryLabel: Color {
        #if os(iOS)
        return Color(uiColor: .tertiaryLabel)
        #elseif os(macOS)
        return Color(nsColor: .tertiaryLabelColor)
        #else
        return Color.gray.opacity(0.6)
        #endif
    }

    // MARK: - Separator Colors

    /// Standard separator color for dividers
    ///
    /// - iOS: UIColor.separator
    /// - macOS: NSColor.separatorColor
    static var separator: Color {
        #if os(iOS)
        return Color(uiColor: .separator)
        #elseif os(macOS)
        return Color(nsColor: .separatorColor)
        #else
        return Color.gray.opacity(0.3)
        #endif
    }

    // MARK: - Adaptive Colors

    /// Creates a color that adapts to the current platform
    ///
    /// - Parameters:
    ///   - light: Color for light appearance
    ///   - dark: Color for dark appearance
    /// - Returns: Adaptive color that responds to system appearance
    static func adaptive(light: Color, dark: Color) -> Color {
        #if os(iOS)
        return Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif os(macOS)
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #else
        return light
        #endif
    }
}

// MARK: - Platform-Specific Color Utilities

extension Color {

    /// Convert SwiftUI Color to platform-native color
    ///
    /// Swift 6.1: Sendable-compliant, thread-safe conversion
    #if os(iOS)
    var platformColor: UIColor {
        UIColor(self)
    }
    #elseif os(macOS)
    var platformColor: NSColor {
        NSColor(self)
    }
    #endif
}
