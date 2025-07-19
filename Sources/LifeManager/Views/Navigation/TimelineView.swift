//
// TimelineView.swift
// LifeManager
//
// Enhanced Timeline View: Strategic Goal Management with AI Insights
// Implements: v2.0 Timeline View with goal-centric visualization and AI recommendations
// Status: ✅ ENHANCED June 22, 2025 (strategic goal timeline with AI insights)
//

import SwiftUI

/// Enhanced Timeline View for strategic goal management and long-term planning
/// Leverages sophisticated TimelineViewService backend for AI-powered insights
struct TimelineView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var timelineService = TimelineViewService.shared
    @State private var selectedTimeRange: TimeRange = .sixMonths
    @State private var selectedViewMode: ViewMode = .timeline
    @State private var selectedFilters: Set<GoalFilter> = []
    @State private var showingCreateGoal = false
    @State private var showingGoalDetail: Goal? = nil
    
    enum TimeRange: String, CaseIterable {
        case oneMonth = "1 Month"
        case threeMonths = "3 Months"
        case sixMonths = "6 Months"
        case oneYear = "1 Year"
        case all = "All Time"
        
        var icon: String {
            switch self {
            case .oneMonth: return "calendar"
            case .threeMonths: return "calendar.badge.clock"
            case .sixMonths: return "calendar.circle"
            case .oneYear: return "calendar.circle.fill"
            case .all: return "timeline.selection"
            }
        }
        
        var dateRange: DateInterval? {
            let now = Date()
            let calendar = Calendar.current
            
            switch self {
            case .oneMonth:
                return DateInterval(start: calendar.date(byAdding: .month, value: -1, to: now) ?? now, end: now)
            case .threeMonths:
                return DateInterval(start: calendar.date(byAdding: .month, value: -3, to: now) ?? now, end: now)
            case .sixMonths:
                return DateInterval(start: calendar.date(byAdding: .month, value: -6, to: now) ?? now, end: now)
            case .oneYear:
                return DateInterval(start: calendar.date(byAdding: .year, value: -1, to: now) ?? now, end: now)
            case .all:
                return nil
            }
        }
    }
    
    enum ViewMode: String, CaseIterable {
        case timeline = "Timeline"
        case gantt = "Gantt"
        case list = "List"
        case calendar = "Calendar"
        
        var icon: String {
            switch self {
            case .timeline: return "timeline.selection"
            case .gantt: return "chart.bar.horizontal"
            case .list: return "list.bullet"
            case .calendar: return "calendar"
            }
        }
    }
    
    enum GoalFilter: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case atRisk = "At Risk"
        case highPriority = "High Priority"
        case work = "Work"
        case personal = "Personal"
        
        var icon: String {
            switch self {
            case .active: return "play.circle"
            case .completed: return "checkmark.circle"
            case .atRisk: return "exclamationmark.triangle"
            case .highPriority: return "flame"
            case .work: return "briefcase"
            case .personal: return "house"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header with Navigation and Stats
            TimelineHeader(
                selectedTimeRange: $selectedTimeRange,
                selectedViewMode: $selectedViewMode,
                selectedFilters: $selectedFilters,
                onCreateGoal: { showingCreateGoal = true },
                progressSummary: timelineService.progressSummary
            )
            
            Divider()
            
            // Main Timeline Content
            if timelineService.isLoading && timelineService.goals.isEmpty {
                LoadingStateView()
            } else if filteredGoals.isEmpty {
                EmptyStateView(
                    title: "No goals in timeline",
                    systemImage: "target",
                    description: "Create your first goal to start tracking long-term progress",
                    actionTitle: "Create Goal",
                    action: { showingCreateGoal = true }
                )
            } else {
                timelineContentView
            }
        }
        .sheet(isPresented: $showingCreateGoal) {
            CreateGoalView()
                .environmentObject(timelineService)
        }
        .sheet(item: $showingGoalDetail) { goal in
            GoalDetailView(goal: goal)
                .environmentObject(timelineService)
        }
        .onAppear {
            Task {
                await timelineService.loadInitialData()
            }
        }
    }
    
    // MARK: - Timeline Content Views
    
    @ViewBuilder
    private var timelineContentView: some View {
        switch selectedViewMode {
        case .timeline:
            timelineView
        case .gantt:
            ganttView
        case .list:
            listView
        case .calendar:
            calendarView
        }
    }
    
    private var timelineView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // AI Insights Panel (if available)
                if !timelineService.timelineInsights.isEmpty {
                    AIInsightsPanel(insights: timelineService.timelineInsights)
                        .padding(.horizontal, 20)
                }
                
                // Goals Timeline
                ForEach(filteredGoals, id: \.id) { goal in
                    GoalTimelineCard(
                        goal: goal,
                        milestones: timelineService.milestones.filter { $0.goalId == goal.id },
                        onTap: { showingGoalDetail = goal },
                        onMilestoneToggle: { milestone in
                            Task {
                                await timelineService.toggleMilestone(milestone)
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    private var ganttView: some View {
        // Placeholder for Gantt chart implementation
        VStack {
            Text("Gantt View")
                .font(.title2)
                .padding()
            
            Text("Coming in v2.1 - Interactive Gantt chart with drag & drop timeline management")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredGoals, id: \.id) { goal in
                    GoalListRow(
                        goal: goal,
                        onTap: { showingGoalDetail = goal }
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    private var calendarView: some View {
        // Placeholder for calendar integration
        VStack {
            Text("Calendar View")
                .font(.title2)
                .padding()
            
            Text("Coming in v2.1 - Integrated calendar view with goal milestones")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredGoals: [Goal] {
        let goals = timelineService.goals
        
        return goals.filter { goal in
            // Time range filter
            if let dateRange = selectedTimeRange.dateRange {
                let goalInRange = (goal.startDate != nil && dateRange.contains(goal.startDate!)) ||
                                 (goal.targetDate != nil && dateRange.contains(goal.targetDate!)) ||
                                 (goal.updatedAt >= dateRange.start && goal.updatedAt <= dateRange.end)
                if !goalInRange { return false }
            }
            
            // Status and priority filters
            for filter in selectedFilters {
                switch filter {
                case .active:
                    if goal.status != .active && goal.status != .inProgress { return false }
                case .completed:
                    if goal.status != .completed { return false }
                case .atRisk:
                    if goal.riskLevel != .high && goal.riskLevel != .critical { return false }
                case .highPriority:
                    if goal.priority != .high && goal.priority != .urgent { return false }
                case .work:
                    if goal.workPersonal != .work { return false }
                case .personal:
                    if goal.workPersonal != .personal { return false }
                }
            }
            
            return true
        }
        .sorted { goal1, goal2 in
            // Sort by priority, then by target date
            if goal1.priority != goal2.priority {
                return goal1.priority.sortOrder < goal2.priority.sortOrder
            }
            
            if let date1 = goal1.targetDate, let date2 = goal2.targetDate {
                return date1 < date2
            }
            
            return goal1.updatedAt > goal2.updatedAt
        }
    }
}

// MARK: - Supporting Views

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading timeline...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Priority Extension

extension GoalPriority {
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

/* #Preview // DISABLED FOR STABILIZATION
TimelineView()
    .environmentObject(MainViewModel())
}*/