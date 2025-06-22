//
// AutomationDashboardView.swift
// LifeManager
//
// Phase 4: Integration, Learning & Optimization - UI Components
// Comprehensive dashboard for intelligent automation monitoring and control
// Status: ✅ IMPLEMENTED June 22, 2025
//

import SwiftUI

/// Main dashboard for monitoring and controlling intelligent automation services
struct AutomationDashboardView: View {
    @StateObject private var orchestrator = AutomationOrchestrator.shared
    @StateObject private var performanceMonitor = PerformanceMonitoringService.shared
    @StateObject private var aiLearning = AILearningEngine.shared
    @State private var selectedTab: DashboardTab = .overview
    @State private var isDetailExpanded = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with status indicators
                DashboardHeaderView(
                    orchestrator: orchestrator,
                    performanceMonitor: performanceMonitor
                )
                
                // Tab navigation
                DashboardTabBar(selectedTab: $selectedTab)
                
                // Main content
                TabView(selection: $selectedTab) {
                    OverviewTabView(
                        orchestrator: orchestrator,
                        performanceMonitor: performanceMonitor,
                        aiLearning: aiLearning
                    )
                    .tag(DashboardTab.overview)
                    
                    ServicesTabView(
                        orchestrator: orchestrator,
                        performanceMonitor: performanceMonitor
                    )
                    .tag(DashboardTab.services)
                    
                    LearningTabView(
                        aiLearning: aiLearning,
                        orchestrator: orchestrator
                    )
                    .tag(DashboardTab.learning)
                    
                    OptimizationTabView(
                        orchestrator: orchestrator,
                        performanceMonitor: performanceMonitor
                    )
                    .tag(DashboardTab.optimization)
                    
                    InsightsTabView(
                        orchestrator: orchestrator,
                        aiLearning: aiLearning
                    )
                    .tag(DashboardTab.insights)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Automation Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Metrics") {
                            exportMetrics()
                        }
                        
                        Button("System Health Check") {
                            Task {
                                await performSystemHealthCheck()
                            }
                        }
                        
                        Button(orchestrator.isOrchestrating ? "Pause Automation" : "Resume Automation") {
                            Task {
                                if orchestrator.isOrchestrating {
                                    orchestrator.stopOrchestration()
                                } else {
                                    await orchestrator.startOrchestration()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func exportMetrics() {
        // Implementation for exporting metrics
    }
    
    private func performSystemHealthCheck() async {
        // Implementation for manual health check
    }
}

// MARK: - Dashboard Header

struct DashboardHeaderView: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var performanceMonitor: PerformanceMonitoringService
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // System status indicator
                SystemStatusIndicator(
                    isOperational: orchestrator.automationStatus.isFullyOperational,
                    systemHealth: orchestrator.systemHealth
                )
                
                Spacer()
                
                // Performance metrics
                HStack(spacing: 16) {
                    MetricBadge(
                        title: "Efficiency",
                        value: "\(Int(orchestrator.unifiedMetrics.systemEfficiency * 100))%",
                        color: orchestrator.unifiedMetrics.systemEfficiency > 0.8 ? .green : .orange
                    )
                    
                    MetricBadge(
                        title: "Response",
                        value: "\(String(format: "%.1f", orchestrator.unifiedMetrics.averageResponseTime))s",
                        color: orchestrator.unifiedMetrics.averageResponseTime < 2.0 ? .green : .red
                    )
                    
                    MetricBadge(
                        title: "Satisfaction",
                        value: "\(Int(orchestrator.unifiedMetrics.userSatisfactionScore * 100))%",
                        color: orchestrator.unifiedMetrics.userSatisfactionScore > 0.8 ? .green : .orange
                    )
                }
            }
            
            // Quick status summary
            Text(getStatusSummary())
                .font(.subheadline)
                .foregroundColor(.secondary)
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
    
    private func getStatusSummary() -> String {
        let activeServices = orchestrator.automationStatus.activeServices
        let pendingDecisions = orchestrator.automationStatus.pendingDecisions
        
        if orchestrator.automationStatus.isFullyOperational {
            return "\(activeServices) services active • \(pendingDecisions) pending decisions"
        } else {
            return "System issues detected • \(activeServices) services • \(pendingDecisions) pending"
        }
    }
}

// MARK: - Tab Bar

struct DashboardTabBar: View {
    @Binding var selectedTab: DashboardTab
    
    var body: some View {
        HStack {
            ForEach(DashboardTab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct TabBarButton: View {
    let tab: DashboardTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(tab.title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Overview Tab

struct OverviewTabView: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var performanceMonitor: PerformanceMonitoringService
    @ObservedObject var aiLearning: AILearningEngine
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // System health overview
                SystemHealthCard(systemHealth: orchestrator.systemHealth)
                
                // Active workflows
                ActiveWorkflowsCard(automationStatus: orchestrator.automationStatus)
                
                // Recent decisions
                RecentDecisionsCard(decisions: orchestrator.coordinatedDecisions.prefix(5))
                
                // Performance summary
                PerformanceSummaryCard(
                    metrics: orchestrator.unifiedMetrics,
                    systemMetrics: performanceMonitor.systemMetrics
                )
                
                // AI learning summary
                AILearningSummaryCard(
                    insights: aiLearning.learningInsights.prefix(3),
                    patterns: aiLearning.behaviorPatterns.prefix(3)
                )
            }
            .padding()
        }
    }
}

// MARK: - Services Tab

struct ServicesTabView: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var performanceMonitor: PerformanceMonitoringService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(performanceMonitor.serviceMetrics.keys.sorted()), id: \.self) { serviceName in
                    if let metrics = performanceMonitor.serviceMetrics[serviceName] {
                        ServiceStatusCard(
                            serviceName: serviceName,
                            metrics: metrics,
                            isHealthy: orchestrator.systemHealth.serviceHealth[serviceName] ?? false
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Learning Tab

struct LearningTabView: View {
    @ObservedObject var aiLearning: AILearningEngine
    @ObservedObject var orchestrator: AutomationOrchestrator
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Model performance
                ModelPerformanceCard(metrics: aiLearning.modelPerformanceMetrics)
                
                // Learning insights
                LearningInsightsCard(insights: aiLearning.learningInsights)
                
                // Behavior patterns
                BehaviorPatternsCard(patterns: aiLearning.behaviorPatterns)
                
                // Adaptation suggestions
                AdaptationSuggestionsCard(suggestions: aiLearning.adaptationSuggestions)
            }
            .padding()
        }
    }
}

// MARK: - Optimization Tab

struct OptimizationTabView: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var performanceMonitor: PerformanceMonitoringService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Performance alerts
                PerformanceAlertsCard(alerts: performanceMonitor.performanceAlerts)
                
                // Optimization opportunities
                OptimizationOpportunitiesCard(optimizations: orchestrator.crossServiceOptimizations)
                
                // Optimization recommendations
                OptimizationRecommendationsCard(recommendations: performanceMonitor.optimizationRecommendations)
                
                // Automatic optimizations control
                AutomaticOptimizationsCard(performanceMonitor: performanceMonitor)
            }
            .padding()
        }
    }
}

// MARK: - Insights Tab

struct InsightsTabView: View {
    @ObservedObject var orchestrator: AutomationOrchestrator
    @ObservedObject var aiLearning: AILearningEngine
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Automation insights
                AutomationInsightsCard(insights: orchestrator.automationInsights)
                
                // User feedback summary
                UserFeedbackCard(feedback: aiLearning.userFeedbackHistory)
                
                // Optimization impact
                OptimizationImpactCard(optimizations: orchestrator.crossServiceOptimizations)
                
                // Learning progress
                LearningProgressCard(
                    metrics: aiLearning.modelPerformanceMetrics,
                    patterns: aiLearning.behaviorPatterns.count
                )
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct SystemStatusIndicator: View {
    let isOperational: Bool
    let systemHealth: SystemHealth
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isOperational ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isOperational ? "Operational" : "Issues Detected")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Health: \(Int(systemHealth.overallScore * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MetricBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
        )
    }
}

struct SystemHealthCard: View {
    let systemHealth: SystemHealth
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("System Health")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(systemHealth.overallScore * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(systemHealth.overallScore > 0.8 ? .green : .orange)
                }
                
                // Resource health indicators
                VStack(spacing: 8) {
                    HealthIndicatorRow(title: "Memory", isHealthy: systemHealth.resourceHealth.memoryHealthy)
                    HealthIndicatorRow(title: "CPU", isHealthy: systemHealth.resourceHealth.cpuHealthy)
                    HealthIndicatorRow(title: "Disk", isHealthy: systemHealth.resourceHealth.diskHealthy)
                    HealthIndicatorRow(title: "Network", isHealthy: systemHealth.resourceHealth.networkHealthy)
                }
            }
        }
    }
}

struct HealthIndicatorRow: View {
    let title: String
    let isHealthy: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Circle()
                .fill(isHealthy ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isHealthy ? "Healthy" : "Issues")
                .font(.caption)
                .foregroundColor(isHealthy ? .green : .red)
        }
    }
}

struct ActiveWorkflowsCard: View {
    let automationStatus: AutomationStatus
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Active Workflows")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 24) {
                    WorkflowMetric(title: "Active", count: automationStatus.activeWorkflows, color: .blue)
                    WorkflowMetric(title: "Pending", count: automationStatus.pendingDecisions, color: .orange)
                    WorkflowMetric(title: "Queue", count: automationStatus.optimizationQueue, color: .purple)
                }
            }
        }
    }
}

struct WorkflowMetric: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

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

// Additional card views would continue with similar patterns...
struct RecentDecisionsCard: View {
    let decisions: ArraySlice<CoordinatedDecision>
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Decisions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if decisions.isEmpty {
                    Text("No recent decisions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(decisions), id: \.id) { decision in
                        DecisionRow(decision: decision)
                    }
                }
            }
        }
    }
}

struct DecisionRow: View {
    let decision: CoordinatedDecision
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(decision.originalDecision.decisionType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(decision.executionTime, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            DecisionStatusBadge(result: decision.coordinationResult)
        }
    }
}

struct DecisionStatusBadge: View {
    let result: CoordinationResult
    
    var body: some View {
        Text(result.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorForResult(result).opacity(0.2))
            )
            .foregroundColor(colorForResult(result))
    }
    
    private func colorForResult(_ result: CoordinationResult) -> Color {
        switch result {
        case .approved: return .green
        case .modified: return .orange
        case .deferred: return .blue
        case .rejected: return .red
        }
    }
}

// More card implementations would follow...
struct PerformanceSummaryCard: View {
    let metrics: UnifiedMetrics
    let systemMetrics: SystemMetrics
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Memory")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(systemMetrics.memoryUsage.usedMemory))MB")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CPU")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(systemMetrics.cpuUsage.usage))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reliability")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(metrics.automationReliability * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// Placeholder implementations for other cards...
struct AILearningSummaryCard: View {
    let insights: ArraySlice<LearningInsight>
    let patterns: ArraySlice<BehaviorPattern>
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Learning Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Insights")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(insights.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Patterns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(patterns.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// Additional card implementations would follow the same pattern...

// MARK: - Supporting Types

enum DashboardTab: String, CaseIterable {
    case overview = "Overview"
    case services = "Services"
    case learning = "Learning"
    case optimization = "Optimization"
    case insights = "Insights"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .services: return "gear.circle.fill"
        case .learning: return "brain.head.profile"
        case .optimization: return "speedometer"
        case .insights: return "lightbulb.fill"
        }
    }
}

// Placeholder implementations for the remaining card views
struct ServiceStatusCard: View {
    let serviceName: String
    let metrics: ServiceMetrics
    let isHealthy: Bool
    
    var body: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(serviceName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Response: \(String(format: "%.2f", metrics.responseTime))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(isHealthy ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
            }
        }
    }
}

struct ModelPerformanceCard: View {
    let metrics: ModelPerformanceMetrics
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Model Performance")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Accuracy: \(Int(metrics.overallAccuracy * 100))%")
                    .font(.subheadline)
            }
        }
    }
}

struct LearningInsightsCard: View {
    let insights: [LearningInsight]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Learning Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(insights.count) insights available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BehaviorPatternsCard: View {
    let patterns: [BehaviorPattern]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Behavior Patterns")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(patterns.count) patterns identified")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AdaptationSuggestionsCard: View {
    let suggestions: [AdaptationSuggestion]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Adaptation Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(suggestions.count) suggestions available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PerformanceAlertsCard: View {
    let alerts: [PerformanceAlert]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(alerts.count) active alerts")
                    .font(.subheadline)
                    .foregroundColor(alerts.isEmpty ? .secondary : .red)
            }
        }
    }
}

struct OptimizationOpportunitiesCard: View {
    let optimizations: [CrossServiceOptimization]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Optimization Opportunities")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(optimizations.count) opportunities identified")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct OptimizationRecommendationsCard: View {
    let recommendations: [OptimizationRecommendation]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Optimization Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(recommendations.count) recommendations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AutomaticOptimizationsCard: View {
    @ObservedObject var performanceMonitor: PerformanceMonitoringService
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Automatic Optimizations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Button("Run Optimizations") {
                    Task {
                        await performanceMonitor.performAutomaticOptimizations()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct AutomationInsightsCard: View {
    let insights: [AutomationInsight]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Automation Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(insights.count) insights generated")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct UserFeedbackCard: View {
    let feedback: [UserFeedback]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("User Feedback")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(feedback.count) feedback entries")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct OptimizationImpactCard: View {
    let optimizations: [CrossServiceOptimization]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Optimization Impact")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Tracking optimization effectiveness")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LearningProgressCard: View {
    let metrics: ModelPerformanceMetrics
    let patterns: Int
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Learning Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Patterns")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(patterns)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Velocity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(metrics.learningVelocity * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

#Preview {
    AutomationDashboardView()
}