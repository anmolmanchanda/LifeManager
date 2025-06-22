import SwiftUI

/// AI Recommendation Card - Shows AI-generated suggestions with actions
struct AIRecommendationCard: View {
    let recommendation: AIRecommendation
    let onDismiss: () -> Void
    let onApply: () -> Void
    
    @State private var isDismissed = false
    @State private var showingDetails = false
    
    var body: some View {
        if !isDismissed {
            VStack(alignment: .leading, spacing: 12) {
                // Header with type and confidence
                HStack {
                    // Icon and type
                    HStack(spacing: 6) {
                        Image(systemName: recommendation.type.icon)
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Text(recommendation.type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Confidence indicator
                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(recommendation.confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Dismiss button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isDismissed = true
                        }
                        onDismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Main content
                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Show reasoning if details are expanded
                    if showingDetails {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "lightbulb")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            
                            Text(recommendation.reasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Action buttons
                if recommendation.actionable {
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.spring()) {
                                onApply()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                Text("Apply")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showingDetails.toggle()
                            }
                        }) {
                            Text(showingDetails ? "Less" : "Details")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        // Feedback buttons
                        FeedbackButtons(
                            onThumbsUp: {
                                // Handle positive feedback
                            },
                            onThumbsDown: {
                                // Handle negative feedback
                            }
                        )
                    }
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var backgroundColor: Color {
        switch recommendation.type {
        case .achievementCelebration:
            return Color.green.opacity(0.05)
        case .energyMatching:
            return Color.orange.opacity(0.05)
        case .timeOptimization:
            return Color.blue.opacity(0.05)
        default:
            return Color.purple.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        switch recommendation.type {
        case .achievementCelebration:
            return Color.green.opacity(0.2)
        case .energyMatching:
            return Color.orange.opacity(0.2)
        case .timeOptimization:
            return Color.blue.opacity(0.2)
        default:
            return Color.purple.opacity(0.2)
        }
    }
}

// MARK: - Feedback Buttons

struct FeedbackButtons: View {
    let onThumbsUp: () -> Void
    let onThumbsDown: () -> Void
    
    @State private var feedbackGiven: FeedbackType? = nil
    
    enum FeedbackType {
        case positive, negative
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                feedbackGiven = .positive
                onThumbsUp()
            }) {
                Image(systemName: feedbackGiven == .positive ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.caption)
                    .foregroundColor(feedbackGiven == .positive ? .green : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                feedbackGiven = .negative
                onThumbsDown()
            }) {
                Image(systemName: feedbackGiven == .negative ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.caption)
                    .foregroundColor(feedbackGiven == .negative ? .red : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Quick Actions Panel

struct QuickActionsPanel: View {
    let selectedCount: Int
    let onAction: (BatchActionType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt")
                    .foregroundColor(.blue)
                Text("Quick Actions")
                    .font(.headline)
            }
            
            Text("\(selectedCount) item\(selectedCount == 1 ? "" : "s") selected")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                QuickActionButton(
                    icon: "checkmark.circle.fill",
                    title: "Complete",
                    color: .green,
                    action: {
                        onAction(.complete)
                    }
                )
                
                QuickActionButton(
                    icon: "clock.arrow.circlepath",
                    title: "Defer",
                    color: .orange,
                    action: {
                        onAction(.defer)
                    }
                )
                
                QuickActionButton(
                    icon: "arrow.up.circle",
                    title: "Priority ↑",
                    color: .red,
                    action: {
                        onAction(.increasePriority)
                    }
                )
                
                QuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "Reschedule",
                    color: .blue,
                    action: {
                        onAction(.reschedule)
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Batch Action Bar

struct BatchActionBar: View {
    @Binding var selectedItems: Set<UUID>
    let onAction: (BatchActionType) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            // Selection info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedItems.count) Selected")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Tap action or swipe to cancel")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                ActionBarButton(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    action: {
                        onAction(.complete)
                    }
                )
                
                ActionBarButton(
                    icon: "clock.arrow.circlepath",
                    color: .orange,
                    action: {
                        onAction(.defer)
                    }
                )
                
                ActionBarButton(
                    icon: "arrow.up.circle",
                    color: .red,
                    action: {
                        onAction(.increasePriority)
                    }
                )
                
                ActionBarButton(
                    icon: "trash",
                    color: .red,
                    action: {
                        onAction(.delete)
                    }
                )
            }
            
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct ActionBarButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Celebration Banner

struct CelebrationBanner: View {
    let badge: AchievementBadge
    let onDismiss: () -> Void
    
    @State private var isVisible = true
    @State private var bounceEffect = false
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                // Achievement icon with animation
                Image(systemName: badge.icon)
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .scaleEffect(bounceEffect ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).repeatCount(3), value: bounceEffect)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(badge.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(badge.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Dismiss") {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isVisible = false
                    }
                    onDismiss()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    bounceEffect = true
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AIRecommendationCard(
            recommendation: AIRecommendation(
                type: .timeOptimization,
                title: "Consider reducing today's workload",
                description: "You have 8 hours of estimated work",
                confidence: 0.8,
                reasoning: "Overloaded schedule may lead to incomplete tasks",
                actionable: true
            ),
            onDismiss: { },
            onApply: { }
        )
        
        QuickActionsPanel(
            selectedCount: 3,
            onAction: { _ in }
        )
        
        CelebrationBanner(
            badge: AchievementBadge(
                type: .streak,
                title: "Focus Master",
                description: "Completed 5 tasks today!",
                icon: "star.circle.fill"
            ),
            onDismiss: { }
        )
    }
    .padding()
}