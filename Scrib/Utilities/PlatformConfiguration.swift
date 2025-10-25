//
//  PlatformConfiguration.swift
//  Scrib
//
//  Created by Claude Code
//  Copyright © 2025 Scrib. All rights reserved.
//

import SwiftUI

// MARK: - Platform Configuration

/// Central hub for platform-specific configuration and constants
///
/// Provides compile-time and runtime platform detection, capabilities,
/// and configuration values. Eliminates the need for scattered #if os()
/// checks throughout the codebase.
///
/// Swift 6.1 Best Practice: Sendable conformance, static constants
/// with compile-time optimization for zero runtime overhead.
public struct PlatformConfiguration: Sendable {

    // MARK: - Platform Detection

    /// Current platform identifier
    public static let platform: Platform = {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #elseif os(visionOS)
        return .visionOS
        #else
        return .unknown
        #endif
    }()

    /// Platform enum
    public enum Platform: String, Sendable, CaseIterable {
        case iOS
        case macOS
        case watchOS
        case tvOS
        case visionOS
        case unknown

        /// Human-readable platform name
        public var displayName: String {
            switch self {
            case .iOS: return "iOS"
            case .macOS: return "macOS"
            case .watchOS: return "watchOS"
            case .tvOS: return "tvOS"
            case .visionOS: return "visionOS"
            case .unknown: return "Unknown"
            }
        }

        /// Whether this is a mobile platform
        public var isMobile: Bool {
            switch self {
            case .iOS, .watchOS: return true
            default: return false
            }
        }

        /// Whether this is a desktop platform
        public var isDesktop: Bool {
            switch self {
            case .macOS: return true
            default: return false
            }
        }
    }

    // MARK: - Feature Capabilities

    /// Whether the platform supports touch input
    public static let supportsTouchInput: Bool = {
        #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
        return true
        #else
        return false
        #endif
    }()

    /// Whether the platform supports pointer/mouse input
    public static let supportsPointerInput: Bool = {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }()

    /// Whether the platform supports an on-screen keyboard
    public static let supportsOnScreenKeyboard: Bool = {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }()

    /// Whether the platform supports EditMode
    public static let supportsEditMode: Bool = {
        #if os(iOS)
        return true
        #elseif os(macOS)
        if #available(macOS 26.0, *) {
            return true // Our custom implementation
        }
        return false
        #else
        return false
        #endif
    }()

    /// Whether the platform supports haptic feedback
    public static let supportsHaptics: Bool = {
        #if os(iOS) || os(watchOS)
        return true
        #else
        return false
        #endif
    }()

    /// Whether the platform supports split view multitasking
    public static let supportsSplitView: Bool = {
        #if os(iOS) || os(macOS)
        return true
        #else
        return false
        #endif
    }()

    // MARK: - UI Constants

    /// Default toolbar placement for the platform
    @MainActor public static let defaultToolbarPlacement: ToolbarItemPlacement = {
        #if os(iOS)
        return .topBarTrailing
        #elseif os(macOS)
        return .primaryAction
        #else
        return .automatic
        #endif
    }()

    /// Default list style name
    public static let defaultListStyleName: String = {
        #if os(iOS)
        return "insetGrouped"
        #elseif os(macOS)
        return "sidebar"
        #else
        return "plain"
        #endif
    }()

    /// Whether the platform uses bottom navigation bars
    public static let usesBottomBars: Bool = {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }()

    /// Default corner radius for cards/panels
    public static let defaultCornerRadius: CGFloat = {
        #if os(iOS)
        return 12.0
        #elseif os(macOS)
        return 8.0
        #else
        return 10.0
        #endif
    }()

    /// Default spacing between elements
    public static let defaultSpacing: CGFloat = {
        #if os(iOS)
        return 16.0
        #elseif os(macOS)
        return 12.0
        #else
        return 14.0
        #endif
    }()

    // MARK: - Scrib-Specific Configuration

    /// Maximum number of chapters to load at once
    public static let maxChaptersPerBatch: Int = {
        #if os(iOS)
        return 50
        #elseif os(macOS)
        return 100 // More powerful hardware
        #else
        return 25
        #endif
    }()

    /// Default word count goal
    public static let defaultWordCountGoal: Int = 2000

    /// Whether to enable advanced text editing features
    public static let supportsAdvancedTextEditing: Bool = {
        #if os(iOS) || os(macOS)
        return true
        #else
        return false
        #endif
    }()

    /// Whether to show keyboard toolbar
    public static let showsKeyboardToolbar: Bool = {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }()

    // MARK: - Performance Thresholds

    /// Target frame rate for animations
    public static let targetFrameRate: Int = {
        #if os(iOS)
        return 120 // ProMotion devices
        #elseif os(macOS)
        return 60
        #else
        return 60
        #endif
    }()

    /// Maximum simultaneous CloudKit operations
    public static let maxConcurrentCloudKitOperations: Int = {
        #if os(iOS)
        return 3
        #elseif os(macOS)
        return 5
        #else
        return 2
        #endif
    }()

    // MARK: - Debug Helpers

    /// Whether running in simulator
    public static let isSimulator: Bool = {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }()

    /// Whether running in debug mode
    public static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    /// Detailed platform description for debugging
    public static var debugDescription: String {
        """
        Platform Configuration:
        - Platform: \(platform.displayName)
        - Mobile: \(platform.isMobile)
        - Desktop: \(platform.isDesktop)
        - Touch Input: \(supportsTouchInput)
        - Pointer Input: \(supportsPointerInput)
        - On-Screen Keyboard: \(supportsOnScreenKeyboard)
        - Edit Mode: \(supportsEditMode)
        - Haptics: \(supportsHaptics)
        - Simulator: \(isSimulator)
        - Debug: \(isDebug)
        """
    }
}

// MARK: - Environment Value

private struct PlatformConfigurationKey: EnvironmentKey {
    static let defaultValue = PlatformConfiguration.self
}

extension EnvironmentValues {
    /// Platform configuration accessible via environment
    ///
    /// Usage:
    /// ```swift
    /// @Environment(\.platformConfiguration) var platform
    ///
    /// if platform.supportsTouchInput {
    ///     // Touch-specific UI
    /// }
    /// ```
    public var platformConfiguration: PlatformConfiguration.Type {
        get { self[PlatformConfigurationKey.self] }
        set { self[PlatformConfigurationKey.self] = newValue }
    }
}

// MARK: - Conditional Compilation Helpers

/// Execute code only on specific platforms
///
/// Usage:
/// ```swift
/// onPlatform(.iOS) {
///     print("Running on iOS")
/// }
/// ```
@inlinable
public func onPlatform(_ platform: PlatformConfiguration.Platform, execute: () -> Void) {
    if PlatformConfiguration.platform == platform {
        execute()
    }
}

/// Execute platform-specific code
///
/// Usage:
/// ```swift
/// platformSwitch(
///     iOS: { /* iOS code */ },
///     macOS: { /* macOS code */ }
/// )
/// ```
@inlinable
public func platformSwitch(
    iOS: (() -> Void)? = nil,
    macOS: (() -> Void)? = nil,
    watchOS: (() -> Void)? = nil,
    tvOS: (() -> Void)? = nil,
    visionOS: (() -> Void)? = nil,
    fallback: (() -> Void)? = nil
) {
    switch PlatformConfiguration.platform {
    case .iOS:
        iOS?() ?? fallback?()
    case .macOS:
        macOS?() ?? fallback?()
    case .watchOS:
        watchOS?() ?? fallback?()
    case .tvOS:
        tvOS?() ?? fallback?()
    case .visionOS:
        visionOS?() ?? fallback?()
    case .unknown:
        fallback?()
    }
}
