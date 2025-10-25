//
//  CrossPlatform.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import Foundation

// MARK: - Platform-Specific Imports

/// Cross-platform utilities for UIKit/AppKit compatibility
///
/// This file provides typealiases and utilities to enable seamless cross-platform
/// development between iOS and macOS. Using `canImport()` is the Swift 6.1 best
/// practice as it focuses on functionality rather than operating system.
///
/// Reference: Swift Evolution - Conditional Compilation Best Practices

#if canImport(UIKit)
import UIKit

/// Platform-agnostic font type (UIFont on iOS/tvOS, NSFont on macOS)
public typealias PlatformFont = UIFont

/// Platform-agnostic color type (UIColor on iOS/tvOS, NSColor on macOS)
public typealias PlatformColor = UIColor

/// Platform-agnostic font descriptor type
public typealias PlatformFontDescriptor = UIFontDescriptor

/// Platform-agnostic edge insets type
public typealias PlatformEdgeInsets = UIEdgeInsets

#elseif canImport(AppKit)
import AppKit

/// Platform-agnostic font type (UIFont on iOS/tvOS, NSFont on macOS)
public typealias PlatformFont = NSFont

/// Platform-agnostic color type (UIColor on iOS/tvOS, NSColor on macOS)
public typealias PlatformColor = NSColor

/// Platform-agnostic font descriptor type
public typealias PlatformFontDescriptor = NSFontDescriptor

/// Platform-agnostic edge insets type
public typealias PlatformEdgeInsets = NSEdgeInsets

#else
#error("Unsupported platform: Scrib requires UIKit (iOS/tvOS) or AppKit (macOS)")
#endif

// MARK: - Cross-Platform Edge Insets

/// Cross-platform edge insets structure
/// Works on both iOS (UIKit) and macOS (AppKit)
public struct PlatformEdgeInsets: Sendable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    #if canImport(UIKit)
    /// Convert to UIEdgeInsets
    public var uiEdgeInsets: UIEdgeInsets {
        UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    #endif

    #if canImport(AppKit)
    /// Convert to NSEdgeInsets
    public var nsEdgeInsets: NSEdgeInsets {
        NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    #endif
}

// MARK: - Cross-Platform Extensions

extension PlatformColor {
    /// Cross-platform label color (adapts to light/dark mode)
    static var labelColor: PlatformColor {
        #if canImport(UIKit)
        return UIColor.label
        #elseif canImport(AppKit)
        return NSColor.labelColor
        #endif
    }

    /// Cross-platform secondary label color
    static var secondaryLabelColor: PlatformColor {
        #if canImport(UIKit)
        return UIColor.secondaryLabel
        #elseif canImport(AppKit)
        return NSColor.secondaryLabelColor
        #endif
    }

    /// Cross-platform tertiary label color
    static var tertiaryLabelColor: PlatformColor {
        #if canImport(UIKit)
        return UIColor.tertiaryLabel
        #elseif canImport(AppKit)
        return NSColor.tertiaryLabelColor
        #endif
    }
}

extension PlatformFont {
    /// Check if font descriptor contains bold trait
    public var isBold: Bool {
        #if canImport(UIKit)
        return fontDescriptor.symbolicTraits.contains(.traitBold)
        #elseif canImport(AppKit)
        return fontDescriptor.symbolicTraits.contains(.bold)
        #else
        return false
        #endif
    }

    /// Check if font descriptor contains italic trait
    public var isItalic: Bool {
        #if canImport(UIKit)
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
        #elseif canImport(AppKit)
        return fontDescriptor.symbolicTraits.contains(.italic)
        #else
        return false
        #endif
    }
}
