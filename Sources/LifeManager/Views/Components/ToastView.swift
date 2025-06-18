//
// ToastView.swift
// LifeManager
//
// Implements: v1.75 "Enhanced UI", v2.0 "Modular Architecture"
// Roadmap Reference: v1.75 Calendar Revolution → v2.0 Intelligence Expansion
// Status: ⏳ STUB as of June 18, 2025 (needs extraction from ContentView.swift)
// Future: v2.5 Animated Toast Notifications
//

import SwiftUI

/// Toast notification view for success and error messages
/// Clean component extracted from monolithic ContentView
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(type.backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 5)
        .onTapGesture {
            onDismiss()
        }
    }
}

/// Toast type for different notification styles
enum ToastType {
    case success
    case error
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return Color.green.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        }
    }
}

#Preview {
    VStack {
        ToastView(
            message: "Success! Your content has been processed.",
            type: .success,
            onDismiss: {}
        )
        
        ToastView(
            message: "Error: Failed to process content.",
            type: .error,
            onDismiss: {}
        )
    }
    .padding()
}