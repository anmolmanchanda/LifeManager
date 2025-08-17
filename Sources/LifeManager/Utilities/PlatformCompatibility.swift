import SwiftUI

#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor
#else
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformColor = UIColor
#endif

// MARK: - Color System Extensions

public extension Color {
    #if os(macOS)
    static var systemBackground: Color {
        return Color(NSColor.windowBackgroundColor)
    }
    
    static var systemGroupedBackground: Color {
        return Color(NSColor.controlBackgroundColor)
    }
    
    static var systemGray6: Color {
        return Color(NSColor.systemGray)
    }
    
    static var label: Color {
        return Color(NSColor.labelColor)
    }
    
    static var secondaryLabel: Color {
        return Color(NSColor.secondaryLabelColor)
    }
    
    static var tertiaryLabel: Color {
        return Color(NSColor.tertiaryLabelColor)
    }
    #endif
}

// MARK: - CGColor Extensions

public extension CGColor {
    #if os(macOS)
    static var systemBackground: CGColor {
        return NSColor.windowBackgroundColor.cgColor
    }
    
    static var systemGroupedBackground: CGColor {
        return NSColor.controlBackgroundColor.cgColor
    }
    
    static var systemGray6: CGColor {
        return NSColor.systemGray.cgColor
    }
    #endif
}

// MARK: - View Extensions

public extension View {
    #if os(macOS)
    // macOS-specific view modifiers
    func navigationBarTitleDisplayMode(_ mode: Any) -> some View {
        self // No-op on macOS
    }
    
    func navigationBarItems(leading: AnyView? = nil, trailing: AnyView? = nil) -> some View {
        self // No-op on macOS
    }
    #endif
    
    #if !os(macOS)
    // iOS-specific view modifiers that don't exist on macOS
    func windowResizability() -> some View { self }
    func defaultWindowPlacement() -> some View { self }
    #endif
}

// MARK: - Platform-specific Navigation

public struct PlatformNavigationView<Content: View>: View {
    let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        #if os(macOS)
        NavigationView {
            content()
        }
        #else
        NavigationStack {
            content()
        }
        #endif
    }
}

// MARK: - Platform-specific Toolbar Placement

public extension ToolbarItemPlacement {
    #if os(macOS)
    static var navigationBarLeading: ToolbarItemPlacement {
        return .automatic
    }
    
    static var navigationBarTrailing: ToolbarItemPlacement {
        return .automatic
    }
    #endif
}

// MARK: - Platform-specific Appearance

public struct PlatformAppearance {
    #if os(macOS)
    public static func configureAppearance() {
        // macOS-specific appearance configuration
    }
    #else
    public static func configureAppearance() {
        // iOS-specific appearance configuration
    }
    #endif
}