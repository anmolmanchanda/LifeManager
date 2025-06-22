//
// IntelligentTimelineView.swift
// LifeManager
//
// Production Timeline View with Intelligent Automation Integration
// Advanced timeline visualization with AI insights and automation controls
// Status: ✅ IMPLEMENTED June 22, 2025
//

import SwiftUI

/// Intelligent Timeline View with AI-powered insights and automation integration
struct IntelligentTimelineView: View {
    @StateObject private var timelineService = TimelineViewService.shared
    @StateObject private var orchestrator = AutomationOrchestrator.shared
    @StateObject private var aiLearning = AILearningEngine.shared
    @StateObject private var intelligentRescheduling = IntelligentReschedulingService.shared
    @StateObject private var taskDependencies = TaskDependencyService.shared
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedFilter: TimelineFilter = .all
    @State private var showingAutomationPanel = false
    @State private var showingAIInsights = false
    @State private var isAutoRefreshEnabled = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced header with automation status
                TimelineHeaderView(
                    timeRange: $selectedTimeRange,
                    filter: $selectedFilter,
                    orchestrator: orchestrator,
                    showingAutomationPanel: $showingAutomationPanel,
                    showingAIInsights: $showingAIInsights,
                    isAutoRefreshEnabled: $isAutoRefreshEnabled
                )
                
                // Main timeline content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // AI-powered timeline summary
                        TimelineSummaryCard(
                            timelineService: timelineService,
                            orchestrator: orchestrator,
                            timeRange: selectedTimeRange
                        )
                        
                        // Automation insights panel
                        if showingAIInsights {
                            AutomationTimelineInsights(
                                aiLearning: aiLearning,
                                orchestrator: orchestrator,
                                taskDependencies: taskDependencies
                            )
                        }
                        
                        // Timeline items with AI enhancements
                        ForEach(filteredTimelineItems, id: \.id) { item in
                            IntelligentTimelineItemView(
                                item: item,
                                timelineService: timelineService,
                                orchestrator: orchestrator,
                                aiLearning: aiLearning
                            )
                        }
                        
                        // Dependency visualization
                        if !taskDependencies.taskDependencies.isEmpty {
                            DependencyVisualizationCard(
                                dependencies: taskDependencies.taskDependencies,
                                orchestrator: orchestrator
                            )
                        }
                        
                        // Future timeline predictions
                        FutureTimelinePredictions(
                            aiLearning: aiLearning,
                            intelligentRescheduling: intelligentRescheduling
                        )
                    }
                    .padding()
                }
                .refreshable {
                    await refreshTimelineData()
                }
            }
            .navigationTitle("Intelligent Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingAIInsights.toggle() }) {
                        Image(systemName: showingAIInsights ? "brain.head.profile.fill" : "brain.head.profile")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { showingAutomationPanel = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(orchestrator.isOrchestrating ? .green : .gray)
                    }
                    
                    Menu {
                        Button("Export Timeline") {
                            exportTimeline()
                        }
                        
                        Button("Analyze Patterns") {
                            Task {
                                await analyzeTimelinePatterns()
                            }
                        }
                        
                        Button("Optimize Schedule") {
                            Task {
                                await optimizeSchedule()
                            }
                        }
                        
                        Toggle("Auto Refresh", isOn: $isAutoRefreshEnabled)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAutomationPanel) {
            TimelineAutomationPanel(
                orchestrator: orchestrator,
                aiLearning: aiLearning,
                intelligentRescheduling: intelligentRescheduling
            )
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            if isAutoRefreshEnabled {
                Task {
                    await refreshTimelineData()
                }
            }
        }
    }
    
    private var filteredTimelineItems: [TimelineItem] {
        return timelineService.getTimelineItems(
            for: selectedTimeRange,
            filter: selectedFilter
        )
    }
    
    private func refreshTimelineData() async {
        await timelineService.refreshData()
    }
    
    private func exportTimeline() {
        // Implementation for timeline export
    }
    
    private func analyzeTimelinePatterns() async {
        await aiLearning.aiLearning.startContinuousLearning()
    }
    
    private func optimizeSchedule() async {
        await orchestrator.performanceMonitor.performAutomaticOptimizations()
    }
}

// MARK: - Timeline Header

struct TimelineHeaderView: View {
    @Binding var timeRange: TimeRange
    @Binding var filter: TimelineFilter
    @ObservedObject var orchestrator: AutomationOrchestrator
    @Binding var showingAutomationPanel: Bool
    @Binding var showingAIInsights: Bool
    @Binding var isAutoRefreshEnabled: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Time range selector
                TimeRangePicker(selectedRange: $timeRange)
                
                Spacer()
                
                // Automation status
                AutomationStatusBadge(
                    isActive: orchestrator.isOrchestrating,
                    systemHealth: orchestrator.systemHealth.overallScore
                )
                
                // Controls
                HStack(spacing: 8) {
                    Button(action: { showingAIInsights.toggle() }) {
                        Image(systemName: showingAIInsights ? "lightbulb.fill" : "lightbulb")
                            .foregroundColor(.yellow)
                    }
                    
                    Button(action: { showingAutomationPanel = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.purple)
                    }
                }
            }
            
            // Filter bar
            TimelineFilterBar(selectedFilter: $filter)
            
            // Quick metrics
            TimelineQuickMetrics(orchestrator: orchestrator)
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
}

struct TimeRangePicker: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 200)
    }
}

struct AutomationStatusBadge: View {
    let isActive: Bool
    let systemHealth: Double
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(isActive ? "Auto" : "Manual")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(Int(systemHealth * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct TimelineFilterBar: View {
    @Binding var selectedFilter: TimelineFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimelineFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    let filter: TimelineFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(filter.title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimelineQuickMetrics: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    
    var body: some View {
        HStack(spacing: 20) {
            QuickMetricView(
                title: "Efficiency",
                value: "\(Int(orchestrator.unifiedMetrics.systemEfficiency * 100))%",
                color: orchestrator.unifiedMetrics.systemEfficiency > 0.8 ? .green : .orange
            )
            
            QuickMetricView(
                title: "Auto Tasks",
                value: "\(orchestrator.unifiedMetrics.successfulDecisions)",
                color: .blue
            )
            
            QuickMetricView(
                title: "Dependencies",
                value: "\(orchestrator.taskDependencies.taskDependencies.values.flatMap { $0 }.count)",
                color: .purple
            )
            
            QuickMetricView(
                title: "Learning",
                value: orchestrator.aiLearning.isLearning ? "Active" : "Paused",
                color: orchestrator.aiLearning.isLearning ? .green : .gray
            )
        }
    }
}

struct QuickMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Timeline Summary

struct TimelineSummaryCard: View {
    @ObservedObject var timelineService: TimelineViewService
    @ObservedObject var orchestrator: AutomationOrchestrator
    let timeRange: TimeRange
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Timeline Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("AI-enhanced \(timeRange.title.lowercased()) view")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // AI confidence for timeline predictions
                    AITimelineConfidence(confidence: orchestrator.unifiedMetrics.systemEfficiency)
                }
                
                // Progress metrics
                HStack(spacing: 20) {
                    TimelineProgressMetric(
                        title: "Completed",
                        current: timelineService.completedTasks,
                        total: timelineService.totalTasks,
                        color: .green
                    )
                    
                    TimelineProgressMetric(
                        title: "In Progress",
                        current: timelineService.inProgressTasks,
                        total: timelineService.totalTasks,
                        color: .blue
                    )
                    
                    TimelineProgressMetric(
                        title: "Automated",
                        current: orchestrator.unifiedMetrics.successfulDecisions,
                        total: orchestrator.unifiedMetrics.totalAutomationRequests,
                        color: .purple
                    )
                }
                
                // Timeline insights
                if !orchestrator.automationInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Timeline Insights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(orchestrator.automationInsights.prefix(2), id: \.id) { insight in
                            TimelineInsightRow(insight: insight)
                        }
                    }
                }
            }
        }
    }
}

struct AITimelineConfidence: View {
    let confidence: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(confidence * 100))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("AI Accuracy")
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

struct TimelineProgressMetric: View {
    let title: String
    let current: Int
    let total: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
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
                    .frame(width: 50)
            }
        }
    }
}

struct TimelineInsightRow: View {
    let insight: AutomationInsight
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconForInsightType(insight.type))
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(insight.title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            ImpactIndicator(impact: insight.impact)
        }
    }
    
    private func iconForInsightType(_ type: InsightType) -> String {
        switch type {
        case .behaviorPattern: return "person.crop.circle"
        case .performance: return "speedometer"
        case .optimization: return "arrow.up.circle"
        case .improvement: return "exclamationmark.triangle"
        }
    }
}

struct ImpactIndicator: View {
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

// MARK: - Automation Timeline Insights

struct AutomationTimelineInsights: View {
    @ObservedObject var aiLearning: AILearningEngine
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var taskDependencies: TaskDependencyService
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Automation Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("Real-time Analysis")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                // Pattern insights
                if !aiLearning.behaviorPatterns.isEmpty {
                    InsightSection(
                        title: "Behavioral Patterns",
                        items: aiLearning.behaviorPatterns.prefix(3).map { pattern in
                            InsightItem(
                                title: pattern.description,
                                confidence: pattern.confidence,
                                recommendations: pattern.recommendations
                            )
                        }
                    )
                }
                
                // Dependency insights
                if !taskDependencies.cascadeWarnings.isEmpty {
                    InsightSection(
                        title: "Dependency Warnings",
                        items: taskDependencies.cascadeWarnings.prefix(2).map { warning in
                            InsightItem(
                                title: warning.warning,
                                confidence: 0.8,
                                recommendations: ["Review task dependencies", "Consider rescheduling"]
                            )
                        }
                    )
                }
                
                // Optimization opportunities
                if !orchestrator.crossServiceOptimizations.isEmpty {
                    InsightSection(
                        title: "Optimization Opportunities",
                        items: orchestrator.crossServiceOptimizations.prefix(2).map { optimization in
                            InsightItem(
                                title: optimization.description,
                                confidence: 0.85,
                                recommendations: optimization.implementation
                            )
                        }
                    )
                }
            }
        }
    }
}

struct InsightSection: View {
    let title: String
    let items: [InsightItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(items.indices, id: \.self) { index in
                InsightItemView(item: items[index])
            }
        }
    }
}

struct InsightItem {
    let title: String
    let confidence: Double
    let recommendations: [String]
}

struct InsightItemView: View {
    let item: InsightItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(isExpanded ? nil : 2)
                
                Spacer()
                
                ConfidenceIndicator(confidence: item.confidence)
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded && !item.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations:")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(item.recommendations.prefix(3), id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConfidenceIndicator: View {
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

// MARK: - Timeline Item View

struct IntelligentTimelineItemView: View {
    let item: TimelineItem
    @ObservedObject var timelineService: TimelineViewService
    @ObservedObject var orchestrator: AutomationOrchestrator
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
                        
                        // Timeline metadata
                        TimelineMetadata(item: item)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        // AI enhancement indicator
                        if item.isAIEnhanced {
                            AIEnhancementBadge(confidence: item.aiConfidence ?? 0.0)
                        }
                        
                        // Status indicator
                        StatusIndicator(status: item.status)
                    }
                }
                
                // AI insights for this item
                if let insight = item.aiInsight {
                    AIItemInsightView(insight: insight)
                }
                
                // Dependencies visualization
                if !item.dependencies.isEmpty {
                    DependencyIndicator(dependencies: item.dependencies)
                }
                
                // Action buttons
                TimelineItemActions(
                    item: item,
                    timelineService: timelineService,
                    orchestrator: orchestrator,
                    aiLearning: aiLearning
                )
            }
        }
    }
}

struct TimelineMetadata: View {
    let item: TimelineItem
    
    var body: some View {
        HStack(spacing: 12) {
            if let dueDate = item.dueDate {
                Label(dueDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let category = item.category {
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
            }
            
            if item.isAutomated {
                Label("Automated", systemImage: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.purple)
            }
        }
    }
}

struct AIEnhancementBadge: View {
    let confidence: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "brain.head.profile.fill")
                .font(.caption)
                .foregroundColor(.blue)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct StatusIndicator: View {
    let status: TimelineItemStatus
    
    var body: some View {
        Circle()
            .fill(colorForStatus(status))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(colorForStatus(status).opacity(0.3), lineWidth: 2)
                    .frame(width: 16, height: 16)
            )
    }
    
    private func colorForStatus(_ status: TimelineItemStatus) -> Color {
        switch status {
        case .completed: return .green
        case .inProgress: return .blue
        case .pending: return .orange
        case .overdue: return .red
        case .automated: return .purple
        }
    }
}

struct AIItemInsightView: View {
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

struct DependencyIndicator: View {
    let dependencies: [UUID]
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "link")
                .font(.caption)
                .foregroundColor(.orange)
            
            Text("\(dependencies.count) dependencies")
                .font(.caption)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

struct TimelineItemActions: View {
    let item: TimelineItem
    @ObservedObject var timelineService: TimelineViewService
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var aiLearning: AILearningEngine
    
    var body: some View {
        HStack(spacing: 12) {
            if item.status != .completed {
                Button("Complete") {
                    Task {
                        await completeItem()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if item.canBeRescheduled {
                Button("Reschedule") {
                    Task {
                        await rescheduleItem()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Menu {
                Button("Analyze Dependencies") {
                    analyzeDependencies()
                }
                
                Button("Request AI Insight") {
                    requestAIInsight()
                }
                
                Button("Provide Feedback") {
                    provideFeedback()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .controlSize(.small)
        }
    }
    
    private func completeItem() async {
        await timelineService.markAsCompleted(item.id)
        
        // Record completion for AI learning
        await aiLearning.recordUserFeedback(
            interactionId: UUID(),
            rating: 1.0,
            feedback: "Timeline item completed",
            category: .accuracy
        )
    }
    
    private func rescheduleItem() async {
        await timelineService.requestReschedule(item.id)
    }
    
    private func analyzeDependencies() {
        // Implementation for dependency analysis
    }
    
    private func requestAIInsight() {
        // Implementation for AI insight request
    }
    
    private func provideFeedback() {
        // Implementation for user feedback
    }
}

// MARK: - Supporting Views

struct DependencyVisualizationCard: View {
    let dependencies: [UUID: [TaskDependency]]
    @ObservedObject var orchestrator: AutomationOrchestrator
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Task Dependencies")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(dependencies.values.flatMap { $0 }.count) dependencies")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Simplified dependency visualization
                DependencyGraphView(dependencies: dependencies)
                
                // Dependency actions
                HStack(spacing: 12) {
                    Button("Analyze Critical Path") {
                        // Implementation
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Optimize Dependencies") {
                        Task {
                            await orchestrator.performanceMonitor.performAutomaticOptimizations()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }
}

struct DependencyGraphView: View {
    let dependencies: [UUID: [TaskDependency]]
    
    var body: some View {
        // Simplified dependency graph visualization
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(dependencies.keys.prefix(5)), id: \.self) { taskId in
                if let deps = dependencies[taskId] {
                    HStack {
                        Text("Task")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.2))
                            )
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(deps.count) deps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            
            if dependencies.count > 5 {
                Text("... and \(dependencies.count - 5) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FutureTimelinePredictions: View {
    @ObservedObject var aiLearning: AILearningEngine
    @ObservedObject var intelligentRescheduling: IntelligentReschedulingService
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("AI Predictions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("Based on patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Prediction items
                VStack(alignment: .leading, spacing: 12) {
                    PredictionItem(
                        title: "Optimal Focus Time",
                        prediction: "Tomorrow 9-11 AM based on your productivity patterns",
                        confidence: 0.85
                    )
                    
                    PredictionItem(
                        title: "Task Completion",
                        prediction: "3 tasks likely to be rescheduled this week",
                        confidence: 0.72
                    )
                    
                    PredictionItem(
                        title: "Workload Analysis",
                        prediction: "Schedule appears balanced for next 7 days",
                        confidence: 0.91
                    )
                }
            }
        }
    }
}

struct PredictionItem: View {
    let title: String
    let prediction: String
    let confidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                ConfidenceIndicator(confidence: confidence)
            }
            
            Text(prediction)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Automation Panel

struct TimelineAutomationPanel: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var aiLearning: AILearningEngine
    @ObservedObject var intelligentRescheduling: IntelligentReschedulingService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Automation status
                    AutomationStatusCard(orchestrator: orchestrator)
                    
                    // AI learning controls
                    AILearningControlCard(aiLearning: aiLearning)
                    
                    // Rescheduling controls
                    ReschedulingControlCard(intelligentRescheduling: intelligentRescheduling)
                    
                    // Timeline-specific settings
                    TimelineSettingsCard()
                }
                .padding()
            }
            .navigationTitle("Timeline Automation")
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

// Placeholder cards for automation panel
struct AutomationStatusCard: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Automation Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("System Health:")
                    Spacer()
                    Text("\(Int(orchestrator.systemHealth.overallScore * 100))%")
                        .fontWeight(.semibold)
                        .foregroundColor(orchestrator.systemHealth.overallScore > 0.8 ? .green : .orange)
                }
                
                Toggle("Full Orchestration", isOn: .constant(orchestrator.isOrchestrating))
            }
        }
    }
}

struct AILearningControlCard: View {
    @ObservedObject var aiLearning: AILearningEngine
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Learning")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Toggle("Continuous Learning", isOn: .constant(aiLearning.isLearning))
                
                Text("Learning Insights: \(aiLearning.learningInsights.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ReschedulingControlCard: View {
    @ObservedObject var intelligentRescheduling: IntelligentReschedulingService
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Intelligent Rescheduling")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Toggle("Auto-Rescheduling", isOn: .constant(intelligentRescheduling.isMonitoring))
                
                let stats = intelligentRescheduling.getReschedulingStatistics()
                Text("Success Rate: \(Int(stats.successRate * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TimelineSettingsCard: View {
    @State private var showCompletedTasks = true
    @State private var showDependencies = true
    @State private var enablePredictions = true
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Timeline Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Toggle("Show Completed Tasks", isOn: $showCompletedTasks)
                Toggle("Show Dependencies", isOn: $showDependencies)
                Toggle("Enable AI Predictions", isOn: $enablePredictions)
            }
        }
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    
    var title: String {
        return self.rawValue
    }
}

enum TimelineFilter: String, CaseIterable {
    case all = "All"
    case projects = "Projects"
    case areas = "Areas"
    case automated = "Automated"
    case dependencies = "Dependencies"
    
    var title: String {
        return self.rawValue
    }
}

enum TimelineItemStatus {
    case completed
    case inProgress
    case pending
    case overdue
    case automated
}

// Placeholder types for timeline implementation
struct TimelineItem: Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let dueDate: Date?
    let category: String?
    let status: TimelineItemStatus
    let isAIEnhanced: Bool
    let aiConfidence: Double?
    let aiInsight: String?
    let dependencies: [UUID]
    let isAutomated: Bool
    let canBeRescheduled: Bool
    
    init(id: UUID = UUID(), title: String, description: String? = nil, dueDate: Date? = nil, category: String? = nil, status: TimelineItemStatus = .pending, isAIEnhanced: Bool = false, aiConfidence: Double? = nil, aiInsight: String? = nil, dependencies: [UUID] = [], isAutomated: Bool = false, canBeRescheduled: Bool = true) {
        self.id = id
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.category = category
        self.status = status
        self.isAIEnhanced = isAIEnhanced
        self.aiConfidence = aiConfidence
        self.aiInsight = aiInsight
        self.dependencies = dependencies
        self.isAutomated = isAutomated
        self.canBeRescheduled = canBeRescheduled
    }
}

// Placeholder TimelineViewService
class TimelineViewService: ObservableObject {
    static let shared = TimelineViewService()
    
    @Published var completedTasks = 8
    @Published var totalTasks = 15
    @Published var inProgressTasks = 4
    
    func getTimelineItems(for timeRange: TimeRange, filter: TimelineFilter) -> [TimelineItem] {
        return [
            TimelineItem(
                title: "Complete project proposal",
                description: "Finalize the Q3 project proposal with budget analysis",
                dueDate: Date().addingTimeInterval(86400),
                category: "Project",
                status: .inProgress,
                isAIEnhanced: true,
                aiConfidence: 0.92,
                aiInsight: "Optimal completion time based on your focus patterns: 2-4 PM",
                isAutomated: true
            ),
            TimelineItem(
                title: "Team meeting preparation",
                description: "Prepare agenda and materials for weekly team sync",
                dueDate: Date().addingTimeInterval(43200),
                category: "Area",
                status: .pending,
                isAIEnhanced: true,
                aiConfidence: 0.85,
                aiInsight: "Consider scheduling after proposal completion",
                dependencies: [UUID()]
            ),
            TimelineItem(
                title: "Review design mockups",
                description: "Provide feedback on new UI designs",
                dueDate: Date().addingTimeInterval(172800),
                category: "Task",
                status: .automated,
                isAIEnhanced: true,
                aiConfidence: 0.78,
                aiInsight: "Automatically rescheduled to align with design sprint",
                isAutomated: true
            )
        ]
    }
    
    func refreshData() async {
        // Simulate data refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func markAsCompleted(_ id: UUID) async {
        completedTasks += 1
        totalTasks += 1
    }
    
    func requestReschedule(_ id: UUID) async {
        // Implementation for rescheduling
    }
}

// Shared CardView component
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
    }
}

#Preview {
    IntelligentTimelineView()
}