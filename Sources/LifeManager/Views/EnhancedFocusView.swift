//
// EnhancedFocusView.swift
// LifeManager
//
// Phase 4: Integration, Learning & Optimization - UI Components
// Enhanced Focus View with intelligent automation integration
// Status: ✅ IMPLEMENTED June 22, 2025
//

import SwiftUI

/// Enhanced Focus View with AI-powered task prioritization and automation insights
struct EnhancedFocusView: View {
    @StateObject private var focusService = FocusViewService.shared
    @StateObject private var orchestrator = AutomationOrchestrator.shared
    @StateObject private var aiLearning = AILearningEngine.shared
    @StateObject private var intelligentRescheduling = IntelligentReschedulingService.shared
    
    @State private var selectedFilter: FocusFilter = .aiSuggested
    @State private var showingAutomationPanel = false
    @State private var showingInsights = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with automation status
                FocusHeaderView(
                    orchestrator: orchestrator,
                    showingAutomationPanel: $showingAutomationPanel,
                    showingInsights: $showingInsights
                )
                
                // Filter bar with AI enhancements
                EnhancedFilterBar(
                    selectedFilter: $selectedFilter,
                    aiLearning: aiLearning,
                    focusService: focusService
                )
                
                // Main content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // AI-powered daily focus summary
                        DailyFocusSummaryCard(
                            focusService: focusService,
                            orchestrator: orchestrator
                        )
                        
                        // Automation insights panel
                        if showingInsights {
                            AutomationInsightsPanel(
                                aiLearning: aiLearning,
                                orchestrator: orchestrator
                            )
                        }
                        
                        // Focus items with AI prioritization
                        ForEach(filteredFocusItems, id: \.id) { item in
                            EnhancedFocusItemRow(
                                item: item,
                                focusService: focusService,
                                aiLearning: aiLearning
                            )
                        }
                        
                        // AI recommendations
                        AIRecommendationsSection(
                            aiLearning: aiLearning,
                            focusService: focusService
                        )
                        
                        // Automation controls
                        AutomationControlsSection(
                            orchestrator: orchestrator,
                            intelligentRescheduling: intelligentRescheduling
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Enhanced Focus")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Automation Dashboard") {
                            // Navigate to automation dashboard
                        }
                        
                        Button("Learning Insights") {
                            showingInsights.toggle()
                        }
                        
                        Button("Trigger AI Analysis") {
                            Task {
                                await triggerAIAnalysis()
                            }
                        }
                        
                        Button("Manual Reschedule") {
                            Task {
                                await requestManualReschedule()
                            }
                        }
                    } label: {
                        Image(systemName: "brain.head.profile")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAutomationPanel) {
            AutomationControlPanel(
                orchestrator: orchestrator,
                aiLearning: aiLearning
            )
        }
    }
    
    private var filteredFocusItems: [FocusItem] {
        return focusService.getFocusItems(for: selectedFilter)
    }
    
    private func triggerAIAnalysis() async {
        await aiLearning.aiLearning.startContinuousLearning()
    }
    
    private func requestManualReschedule() async {
        // Trigger manual rescheduling analysis
        intelligentRescheduling.startMonitoring()
    }
}

// MARK: - Focus Header

struct FocusHeaderView: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    @Binding var showingAutomationPanel: Bool
    @Binding var showingInsights: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Focus session indicator
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI-Enhanced Focus")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(getSessionStatus())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Automation status indicator
                AutomationStatusIndicator(
                    isActive: orchestrator.isOrchestrating,
                    systemHealth: orchestrator.systemHealth.overallScore
                )
                
                // Controls
                HStack(spacing: 8) {
                    Button(action: { showingInsights.toggle() }) {
                        Image(systemName: showingInsights ? "lightbulb.fill" : "lightbulb")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { showingAutomationPanel = true }) {
                        Image(systemName: "gear.circle")
                            .foregroundColor(.purple)
                    }
                }
            }
            
            // Quick metrics
            HStack(spacing: 20) {
                QuickMetric(
                    title: "Efficiency",
                    value: "\(Int(orchestrator.unifiedMetrics.systemEfficiency * 100))%",
                    color: orchestrator.unifiedMetrics.systemEfficiency > 0.8 ? .green : .orange
                )
                
                QuickMetric(
                    title: "Pending",
                    value: "\(orchestrator.automationStatus.pendingDecisions)",
                    color: orchestrator.automationStatus.pendingDecisions == 0 ? .green : .orange
                )
                
                QuickMetric(
                    title: "Learning",
                    value: orchestrator.aiLearning.isLearning ? "Active" : "Paused",
                    color: orchestrator.aiLearning.isLearning ? .green : .gray
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    private func getSessionStatus() -> String {
        if orchestrator.isOrchestrating {
            return "Automation active • AI learning engaged"
        } else {
            return "Manual mode • Automation paused"
        }
    }
}

struct AutomationStatusIndicator: View {
    let isActive: Bool
    let systemHealth: Double
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(isActive ? "Auto" : "Manual")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isActive ? .green : .gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color.green.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct QuickMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Enhanced Filter Bar

struct EnhancedFilterBar: View {
    @Binding var selectedFilter: FocusFilter
    @ObservedObject var aiLearning: AILearningEngine
    @ObservedObject var focusService: FocusViewService
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FocusFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        aiConfidence: getAIConfidence(for: filter),
                        itemCount: focusService.getFocusItems(for: filter).count
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private func getAIConfidence(for filter: FocusFilter) -> Double? {
        if filter == .aiSuggested {
            return aiLearning.modelPerformanceMetrics.overallAccuracy
        }
        return nil
    }
}

struct FilterButton: View {
    let filter: FocusFilter
    let isSelected: Bool
    let aiConfidence: Double?
    let itemCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(filter.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let confidence = aiConfidence {
                        Text("\(Int(confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Text("\(itemCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Daily Focus Summary

struct DailyFocusSummaryCard: View {
    @ObservedObject var focusService: FocusViewService
    @ObservedObject var orchestrator: AutomationOrchestrator
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's AI Focus")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Intelligent prioritization active")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // AI confidence indicator
                    AIConfidenceIndicator(confidence: orchestrator.unifiedMetrics.systemEfficiency)
                }
                
                // Progress indicators
                HStack(spacing: 20) {
                    ProgressMetric(
                        title: "Completed",
                        current: focusService.completedTasksToday,
                        total: focusService.totalTasksToday,
                        color: .green
                    )
                    
                    ProgressMetric(
                        title: "In Progress",
                        current: focusService.inProgressTasks,
                        total: focusService.totalTasksToday,
                        color: .blue
                    )
                    
                    ProgressMetric(
                        title: "Rescheduled",
                        current: orchestrator.intelligentRescheduling.getReschedulingStatistics().totalRescheduled,
                        total: focusService.totalTasksToday,
                        color: .orange
                    )
                }
                
                // AI suggestions summary
                if !orchestrator.aiLearning.learningInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Insights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(orchestrator.aiLearning.learningInsights.prefix(2), id: \.id) { insight in
                            InsightRow(insight: insight)
                        }
                    }
                }
            }
        }
    }
}

struct AIConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(confidence * 100))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("AI Confidence")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct ProgressMetric: View {
    let title: String
    let current: Int
    let total: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(current)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if total > 0 {
                ProgressView(value: Double(current), total: Double(total))
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(width: 40)
            }
        }
    }
}

struct InsightRow: View {
    let insight: LearningInsight
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconForInsight(insight.type))
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(insight.title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(Int(insight.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func iconForInsight(_ type: InsightType) -> String {
        switch type {
        case .behaviorPattern: return "person.crop.circle"
        case .performance: return "speedometer"
        case .optimization: return "arrow.up.circle"
        case .improvement: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Automation Insights Panel

struct AutomationInsightsPanel: View {
    @ObservedObject var aiLearning: AILearningEngine
    @ObservedObject var orchestrator: AutomationOrchestrator
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Automation Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("Real-time")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                // Learning insights
                if !aiLearning.learningInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Learning Insights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(aiLearning.learningInsights.prefix(3), id: \.id) { insight in
                            DetailedInsightRow(insight: insight)
                        }
                    }
                }
                
                // Automation status
                if !orchestrator.automationInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Insights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(orchestrator.automationInsights.prefix(2), id: \.id) { insight in
                            SystemInsightRow(insight: insight)
                        }
                    }
                }
                
                // Quick actions
                HStack(spacing: 12) {
                    Button("Optimize Now") {
                        Task {
                            await orchestrator.performanceMonitor.performAutomaticOptimizations()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Learn More") {
                        // Navigate to detailed insights
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
}

struct DetailedInsightRow: View {
    let insight: LearningInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                ConfidenceBadge(confidence: insight.confidence)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

struct SystemInsightRow: View {
    let insight: AutomationInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                ImpactBadge(impact: insight.impact)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

struct ConfidenceBadge: View {
    let confidence: Double
    
    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorForConfidence(confidence).opacity(0.2))
            )
            .foregroundColor(colorForConfidence(confidence))
    }
    
    private func colorForConfidence(_ confidence: Double) -> Color {
        if confidence > 0.8 { return .green }
        if confidence > 0.6 { return .orange }
        return .red
    }
}

struct ImpactBadge: View {
    let impact: InsightImpact
    
    var body: some View {
        Text(impact.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorForImpact(impact).opacity(0.2))
            )
            .foregroundColor(colorForImpact(impact))
    }
    
    private func colorForImpact(_ impact: InsightImpact) -> Color {
        switch impact {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .blue
        }
    }
}

// MARK: - Enhanced Focus Item Row

struct EnhancedFocusItemRow: View {
    let item: FocusItem
    @ObservedObject var focusService: FocusViewService
    @ObservedObject var aiLearning: AILearningEngine
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        if let description = item.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    // AI-powered priority indicator
                    AIPriorityIndicator(
                        priority: item.priority,
                        aiConfidence: item.aiConfidence ?? 0.5
                    )
                }
                
                // AI insights for this item
                if let aiInsight = getAIInsight(for: item) {
                    AIItemInsight(insight: aiInsight)
                }
                
                // Action buttons with AI suggestions
                HStack(spacing: 12) {
                    Button("Complete") {
                        Task {
                            await completeItem(item)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    if shouldShowRescheduleOption(for: item) {
                        Button("Reschedule") {
                            Task {
                                await rescheduleItem(item)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Menu {
                        Button("Provide Feedback") {
                            provideFeedback(for: item)
                        }
                        
                        Button("Request AI Analysis") {
                            requestAIAnalysis(for: item)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func getAIInsight(for item: FocusItem) -> String? {
        // Get AI insight specific to this item
        return item.aiRecommendation
    }
    
    private func shouldShowRescheduleOption(for item: FocusItem) -> Bool {
        return item.canBeRescheduled && aiLearning.modelPerformanceMetrics.overallAccuracy > 0.7
    }
    
    private func completeItem(_ item: FocusItem) async {
        await focusService.markAsCompleted(item.id)
        
        // Record user feedback for AI learning
        await aiLearning.recordUserFeedback(
            interactionId: UUID(),
            rating: 1.0,
            feedback: "Task completed as suggested",
            category: .accuracy
        )
    }
    
    private func rescheduleItem(_ item: FocusItem) async {
        // Trigger intelligent rescheduling
        await focusService.requestReschedule(item.id)
    }
    
    private func provideFeedback(for item: FocusItem) {
        // Show feedback interface
    }
    
    private func requestAIAnalysis(for item: FocusItem) {
        // Request detailed AI analysis for this item
    }
}

struct AIPriorityIndicator: View {
    let priority: TaskPriority
    let aiConfidence: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(priority.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(colorForPriority(priority))
            
            HStack(spacing: 2) {
                Image(systemName: "brain.head.profile")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Text("\(Int(aiConfidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorForPriority(priority).opacity(0.1))
        )
    }
    
    private func colorForPriority(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

struct AIItemInsight: View {
    let insight: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            
            Text(insight)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

// MARK: - AI Recommendations Section

struct AIRecommendationsSection: View {
    @ObservedObject var aiLearning: AILearningEngine
    @ObservedObject var focusService: FocusViewService
    
    var body: some View {
        if !aiLearning.adaptationSuggestions.isEmpty {
            CardView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("AI Recommendations")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("Based on your patterns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(aiLearning.adaptationSuggestions.prefix(3), id: \.id) { suggestion in
                        AIRecommendationRow(suggestion: suggestion)
                    }
                }
            }
        }
    }
}

struct AIRecommendationRow: View {
    let suggestion: AdaptationSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                ConfidenceBadge(confidence: suggestion.confidence)
            }
            
            Text(suggestion.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if suggestion.reversible {
                HStack(spacing: 8) {
                    Button("Apply") {
                        // Apply suggestion
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    
                    Button("Dismiss") {
                        // Dismiss suggestion
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Automation Controls Section

struct AutomationControlsSection: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var intelligentRescheduling: IntelligentReschedulingService
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Automation Controls")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 12) {
                    AutomationToggle(
                        title: "Intelligent Rescheduling",
                        description: "AI-powered task rescheduling",
                        isOn: intelligentRescheduling.isMonitoring
                    ) {
                        if intelligentRescheduling.isMonitoring {
                            intelligentRescheduling.stopMonitoring()
                        } else {
                            intelligentRescheduling.startMonitoring()
                        }
                    }
                    
                    AutomationToggle(
                        title: "Full Orchestration",
                        description: "Complete automation system",
                        isOn: orchestrator.isOrchestrating
                    ) {
                        if orchestrator.isOrchestrating {
                            orchestrator.stopOrchestration()
                        } else {
                            Task {
                                await orchestrator.startOrchestration()
                            }
                        }
                    }
                }
                
                Button("Run System Optimization") {
                    Task {
                        await orchestrator.performanceMonitor.performAutomaticOptimizations()
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct AutomationToggle: View {
    let title: String
    let description: String
    let isOn: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isOn))
                .onChange(of: isOn) { _ in
                    action()
                }
        }
    }
}

// MARK: - Automation Control Panel

struct AutomationControlPanel: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var aiLearning: AILearningEngine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // System status
                    SystemStatusSection(orchestrator: orchestrator)
                    
                    // AI learning controls
                    AILearningControlsSection(aiLearning: aiLearning)
                    
                    // Service controls
                    ServiceControlsSection(orchestrator: orchestrator)
                    
                    // Advanced settings
                    AdvancedSettingsSection()
                }
                .padding()
            }
            .navigationTitle("Automation Control")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Placeholder implementations for control panel sections
struct SystemStatusSection: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("System Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("System health: \(Int(orchestrator.systemHealth.overallScore * 100))%")
                    .font(.subheadline)
            }
        }
    }
}

struct AILearningControlsSection: View {
    @ObservedObject var aiLearning: AILearningEngine
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Learning")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Toggle("Continuous Learning", isOn: .constant(aiLearning.isLearning))
            }
        }
    }
}

struct ServiceControlsSection: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Service Controls")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Active services: \(orchestrator.automationStatus.activeServices)")
                    .font(.subheadline)
            }
        }
    }
}

struct AdvancedSettingsSection: View {
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Advanced Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Configuration options")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Types

enum FocusFilter: String, CaseIterable {
    case aiSuggested = "AI Suggested"
    case urgentImportant = "Urgent & Important"
    case quickWins = "Quick Wins"
    case deepWork = "Deep Work"
    case lowEnergy = "Low Energy"
    
    var title: String {
        return self.rawValue
    }
}

// Note: FocusItem is defined in Models/FocusViewModels.swift

// TaskPriority is defined in CoreModels.swift

// Note: FocusViewService is implemented in Services/FocusViewService.swift

#Preview {
    EnhancedFocusView()
}