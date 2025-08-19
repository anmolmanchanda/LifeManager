//
// CommonComponents.swift
// LifeManager
//
// Reusable UI components used across multiple views
// Extracted from ContentView for modularity
//

import SwiftUI

// MARK: - Badges

/// Badge showing work/personal classification
struct WorkPersonalBadge: View {
    let type: WorkPersonalType
    
    var body: some View {
        Text(type.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(type == .work ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
            )
            .foregroundColor(type == .work ? .blue : .green)
    }
}

/// Badge showing project status
struct StatusBadge: View {
    let status: ProjectStatus
    
    var body: some View {
        Label(status.displayName, systemImage: status.icon)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status.color.opacity(0.2))
            )
            .foregroundColor(status.color)
    }
}

/// Badge showing priority level
struct PriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<priority.level, id: \.self) { _ in
                Image(systemName: "exclamationmark")
                    .font(.caption2)
            }
        }
        .foregroundColor(priority.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(priority.color.opacity(0.2))
        )
    }
}

// MARK: - Progress Indicators

/// Horizontal progress bar
struct ProgressBar: View {
    let value: Double
    var height: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(value, 1.0))
                    .animation(.easeInOut(duration: 0.3), value: value)
            }
        }
        .frame(height: height)
    }
}

/// Circular progress indicator
struct CircularProgress: View {
    let value: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 4
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: value)
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.bold)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Toast Notifications

/// Toast view for showing temporary messages
struct ToastView: View {
    let message: String
    let type: ToastType
    var onDismiss: (() -> Void)?
    
    @State private var isShowing = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: {
                    withAnimation {
                        isShowing = false
                        onDismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(type.color)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .frame(maxWidth: 400)
        .opacity(isShowing ? 1 : 0)
        .scaleEffect(isShowing ? 1 : 0.8)
        .onAppear {
            if onDismiss != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isShowing = false
                        onDismiss?()
                    }
                }
            }
        }
    }
}

enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// MARK: - Buttons

/// Standard action button with icon and label
struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var style: ActionButtonStyle = .primary
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .buttonStyle(ActionButtonStyleModifier(style: style))
    }
}

enum ActionButtonStyle {
    case primary
    case secondary
    case destructive
}

struct ActionButtonStyleModifier: ButtonStyle {
    let style: ActionButtonStyle
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
    
    private func backgroundColor(isPressed: Bool) -> Color {
        let opacity = isPressed ? 0.8 : 1.0
        switch style {
        case .primary:
            return Color.accentColor.opacity(opacity)
        case .secondary:
            return Color.gray.opacity(0.2 * opacity)
        case .destructive:
            return Color.red.opacity(opacity)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .white
        }
    }
}

// MARK: - Empty States

/// Generic empty state view
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionTitle: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Stats Display

/// View for displaying a single stat
struct StatView: View {
    let label: String
    let value: String
    let icon: String?
    
    var body: some View {
        VStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 80)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Extensions

extension Priority {
    var level: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}