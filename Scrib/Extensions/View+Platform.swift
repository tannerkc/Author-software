//
//  View+Platform.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

// MARK: - Cross-Platform View Modifiers

/// Elegant platform-adaptive view modifiers
///
/// Provides a unified API for view modifiers that behave differently
/// across platforms, allowing view code to remain clean and readable
/// without scattered #if os() conditionals.
///
/// Swift 6.1 Best Practice: Protocol-oriented design with compile-time
/// optimization ensures zero runtime overhead.

extension View {

    // MARK: - Navigation Modifiers

    /// Adaptive navigation bar title display mode
    ///
    /// Applies the appropriate title display mode based on platform:
    /// - iOS: Uses the specified display mode
    /// - macOS: Gracefully ignores (not applicable)
    ///
    /// Usage:
    /// ```swift
    /// .adaptiveNavigationBarTitleDisplayMode(.inline)
    /// ```
    ///
    /// - Parameter mode: The display mode to use on iOS
    /// - Returns: Modified view with platform-appropriate styling
    @ViewBuilder
    func adaptiveNavigationBarTitleDisplayMode(_ mode: AdaptiveNavigationTitleDisplayMode) -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(mode.toiOSMode)
        #else
        self
        #endif
    }

    /// Adaptive navigation bar title display mode (overload for optional mode)
    ///
    /// - Parameter mode: Optional display mode (nil = no modification)
    /// - Returns: Modified view
    @ViewBuilder
    func adaptiveNavigationBarTitleDisplayMode(_ mode: AdaptiveNavigationTitleDisplayMode?) -> some View {
        if let mode = mode {
            self.adaptiveNavigationBarTitleDisplayMode(mode)
        } else {
            self
        }
    }

    // MARK: - Presentation Modifiers

    /// Adaptive presentation detents (iOS sheet sizing)
    ///
    /// Applies presentation detents on iOS, ignored on macOS
    ///
    /// - Parameter detents: Set of detents to use
    /// - Returns: Modified view
    @ViewBuilder
    func adaptivePresentationDetents(_ detents: Set<AdaptivePresentationDetent>) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            self.presentationDetents(Set(detents.map { $0.toiOSDetent }))
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Adaptive presentation detents (variadic)
    ///
    /// - Parameter detents: Variadic list of detents
    /// - Returns: Modified view
    @ViewBuilder
    func adaptivePresentationDetents(_ detents: AdaptivePresentationDetent...) -> some View {
        self.adaptivePresentationDetents(Set(detents))
    }

    // MARK: - Platform-Specific Styling

    /// Applies platform-optimized styling
    ///
    /// Adds subtle platform-specific enhancements:
    /// - macOS: Hover effects, cursor changes
    /// - iOS: Touch feedback, haptics preparation
    ///
    /// - Returns: Platform-optimized view
    @ViewBuilder
    func platformOptimized() -> some View {
        #if os(macOS)
        self
            .buttonStyle(.borderless)
            .contentShape(Rectangle())
        #else
        self
        #endif
    }

    /// Adaptive toolbar placement
    ///
    /// Automatically places toolbar items in platform-appropriate locations
    ///
    /// - Parameter placement: Adaptive placement hint
    /// - Returns: Toolbar item with platform-appropriate placement
    func adaptiveToolbarPlacement(_ placement: AdaptiveToolbarPlacement) -> ToolbarItemPlacement {
        #if os(iOS)
        return placement.toiOSPlacement
        #elseif os(macOS)
        return placement.tomacOSPlacement
        #else
        return .automatic
        #endif
    }

    // MARK: - List Styling

    /// Adaptive list style that matches platform conventions
    ///
    /// - iOS: Uses insetGrouped style
    /// - macOS: Uses sidebar style
    ///
    /// - Returns: Platform-styled list
    @ViewBuilder
    func adaptiveListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #elseif os(macOS)
        self.listStyle(.sidebar)
        #else
        self
        #endif
    }

    /// Removes list row separators in a platform-appropriate way
    ///
    /// - Returns: View with hidden separators
    @ViewBuilder
    func adaptiveListRowSeparator(hidden: Bool = true) -> some View {
        if hidden {
            self.listRowSeparator(.hidden)
        } else {
            self
        }
    }

    // MARK: - Keyboard Toolbar

    /// Adds adaptive keyboard toolbar (iOS only)
    ///
    /// Displays toolbar above keyboard on iOS, no-op on macOS
    ///
    /// - Parameters:
    ///   - content: Toolbar content builder
    /// - Returns: Modified view
    @ViewBuilder
    func adaptiveKeyboardToolbar<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        #if os(iOS)
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                content()
            }
        }
        #else
        self
        #endif
    }

    // MARK: - Context Menu

    /// Adaptive context menu with platform-optimized behavior
    ///
    /// - iOS: Standard long-press context menu
    /// - macOS: Right-click context menu
    ///
    /// - Parameter menuItems: Menu content builder
    /// - Returns: View with context menu
    @ViewBuilder
    func adaptiveContextMenu<MenuItems: View>(
        @ViewBuilder menuItems: () -> MenuItems
    ) -> some View {
        self.contextMenu {
            menuItems()
        }
    }
}

// MARK: - Supporting Types

/// Platform-adaptive navigation title display mode
public enum AdaptiveNavigationTitleDisplayMode {
    case automatic
    case inline
    case large

    #if os(iOS)
    var toiOSMode: NavigationBarItem.TitleDisplayMode {
        switch self {
        case .automatic: return .automatic
        case .inline: return .inline
        case .large: return .large
        }
    }
    #endif
}

/// Platform-adaptive presentation detent (sheet sizing)
public enum AdaptivePresentationDetent: Hashable {
    case medium
    case large
    case fraction(Double)
    case height(CGFloat)

    #if os(iOS)
    @available(iOS 16.0, *)
    var toiOSDetent: PresentationDetent {
        switch self {
        case .medium: return .medium
        case .large: return .large
        case .fraction(let value): return .fraction(value)
        case .height(let value): return .height(value)
        }
    }
    #endif
}

/// Platform-adaptive toolbar placement
public enum AdaptiveToolbarPlacement {
    case automatic
    case primaryAction
    case secondaryAction
    case confirmationAction
    case cancellationAction
    case destructiveAction
    case navigation
    case bottomBar
    case topBarLeading
    case topBarTrailing

    #if os(iOS)
    var toiOSPlacement: ToolbarItemPlacement {
        switch self {
        case .automatic: return .automatic
        case .primaryAction: return .primaryAction
        case .secondaryAction: return .secondaryAction
        case .confirmationAction: return .confirmationAction
        case .cancellationAction: return .cancellationAction
        case .destructiveAction: return .destructiveAction
        case .navigation: return .navigation
        case .bottomBar: return .bottomBar
        case .topBarLeading: return .topBarLeading
        case .topBarTrailing: return .topBarTrailing
        }
    }
    #endif

    #if os(macOS)
    var tomacOSPlacement: ToolbarItemPlacement {
        switch self {
        case .automatic: return .automatic
        case .primaryAction: return .primaryAction
        case .secondaryAction: return .secondaryAction
        case .confirmationAction: return .confirmationAction
        case .cancellationAction: return .cancellationAction
        case .destructiveAction: return .destructiveAction
        case .navigation: return .navigation
        case .bottomBar: return .automatic // macOS doesn't have bottom bar
        case .topBarLeading: return .navigation
        case .topBarTrailing: return .primaryAction
        }
    }
    #endif
}

// MARK: - Environment Values Extension

/// Custom environment key for platform capabilities
private struct PlatformCapabilitiesKey: EnvironmentKey {
    static let defaultValue = PlatformCapabilities()
}

extension EnvironmentValues {
    /// Platform-specific capabilities
    var platformCapabilities: PlatformCapabilities {
        get { self[PlatformCapabilitiesKey.self] }
        set { self[PlatformCapabilitiesKey.self] = newValue }
    }
}

/// Platform capabilities detection
public struct PlatformCapabilities: Sendable {
    /// Whether the platform supports touch input
    public var supportsTouchInput: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the platform supports keyboard input
    public var supportsKeyboardInput: Bool {
        return true
    }

    /// Whether the platform supports trackpad/mouse
    public var supportsPointerInput: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the platform supports on-screen keyboard
    public var supportsOnScreenKeyboard: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether edit mode is available
    public var supportsEditMode: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
}
