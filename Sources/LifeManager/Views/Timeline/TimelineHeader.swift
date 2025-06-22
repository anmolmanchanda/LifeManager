//
// TimelineHeader.swift
// LifeManager
//
// Timeline View Header: Navigation, Filtering, and Progress Summary
// Implements: v2.0 Timeline View header with smart controls and AI insights
// Status: ✅ IMPLEMENTED June 22, 2025
//

import SwiftUI

/// Enhanced header for Timeline View with navigation controls and progress tracking
/// Follows Focus View interaction patterns for consistent user experience
struct TimelineHeader: View {
    @Binding var selectedTimeRange: TimelineView.TimeRange
    @Binding var selectedViewMode: TimelineView.ViewMode
    @Binding var selectedFilters: Set<TimelineView.GoalFilter>
    
    let onCreateGoal: () -> Void
    let progressSummary: ProgressSummary?
    
    @State private var showingFilterMenu = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and Create Goal Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Timeline")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Strategic goal management with AI insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onCreateGoal) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                        Text("Create Goal")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // Progress Summary (if available)
            if let summary = progressSummary {
                ProgressSummaryCard(summary: summary)
            }
            
            // Navigation Controls
            HStack(spacing: 16) {
                // Time Range Selection
                timeRangeSelector
                
                Spacer()
                
                // View Mode Selection
                viewModeSelector
                
                Spacer()
                
                // Filter Button
                filterButton
            }
            
            // Active Filters Display
            if !selectedFilters.isEmpty {
                activeFiltersView
            }
        }
        .padding(20)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Time Range")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimelineView.TimeRange.allCases, id: \.self) { timeRange in
                        Button(action: { selectedTimeRange = timeRange }) {
                            HStack(spacing: 4) {
                                Image(systemName: timeRange.icon)
                                    .font(.caption)
                                Text(timeRange.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTimeRange == timeRange ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                            .foregroundColor(selectedTimeRange == timeRange ? .white : .primary)
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: 200)
    }
    
    // MARK: - View Mode Selector
    
    private var viewModeSelector: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("View Mode")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(TimelineView.ViewMode.allCases, id: \.self) { viewMode in
                    Button(action: { selectedViewMode = viewMode }) {
                        VStack(spacing: 2) {
                            Image(systemName: viewMode.icon)
                                .font(.body)
                            Text(viewMode.rawValue)
                                .font(.caption2)
                        }
                        .frame(width: 60, height: 50)
                        .background(selectedViewMode == viewMode ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(selectedViewMode == viewMode ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Filter Button
    
    private var filterButton: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Filters")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: { showingFilterMenu.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.body)
                    
                    if !selectedFilters.isEmpty {
                        Text("\\(selectedFilters.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingFilterMenu) {
                FilterMenuView(selectedFilters: $selectedFilters)
            }
        }
    }
    
    // MARK: - Active Filters View
    
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Active Filters:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(Array(selectedFilters), id: \.self) { filter in
                    HStack(spacing: 4) {
                        Image(systemName: filter.icon)
                            .font(.caption2)
                        Text(filter.rawValue)
                            .font(.caption)
                        
                        Button(action: { selectedFilters.remove(filter) }) {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundColor(.accentColor)
                    .cornerRadius(12)
                }
                
                Button("Clear All") {
                    selectedFilters.removeAll()
                }
                .font(.caption)
                .foregroundColor(.red)
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Progress Summary Card

struct ProgressSummaryCard: View {
    let summary: ProgressSummary
    
    var body: some View {
        HStack(spacing: 20) {
            // Active Goals
            StatItem(
                title: "Active Goals",
                value: "\\(summary.activeGoalsCount)",
                icon: "target",
                color: .blue
            )
            
            // Completion Rate
            StatItem(
                title: "Completion Rate",
                value: "\\(Int(summary.completionRate * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            // At Risk Goals
            if summary.atRiskGoalsCount > 0 {
                StatItem(
                    title: "At Risk",
                    value: "\\(summary.atRiskGoalsCount)",
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
            }
            
            // Upcoming Milestones
            StatItem(
                title: "Upcoming",
                value: "\\(summary.upcomingMilestonesCount)",
                icon: "flag",
                color: .purple
            )
            
            Spacer()
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Filter Menu

struct FilterMenuView: View {
    @Binding var selectedFilters: Set<TimelineView.GoalFilter>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter Goals")
                .font(.headline)
                .padding(.bottom, 8)
            
            ForEach(TimelineView.GoalFilter.allCases, id: \.self) { filter in
                Button(action: {
                    if selectedFilters.contains(filter) {
                        selectedFilters.remove(filter)
                    } else {
                        selectedFilters.insert(filter)
                    }
                }) {
                    HStack {
                        Image(systemName: selectedFilters.contains(filter) ? "checkmark.square.fill" : "square")
                            .foregroundColor(selectedFilters.contains(filter) ? .accentColor : .secondary)
                        
                        Image(systemName: filter.icon)
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(width: 20)
                        
                        Text(filter.rawValue)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                Button("Clear All") {
                    selectedFilters.removeAll()
                }
                .font(.body)
                .foregroundColor(.red)
                
                Spacer()
                
                Button("Select All") {
                    selectedFilters = Set(TimelineView.GoalFilter.allCases)
                }
                .font(.body)
                .foregroundColor(.accentColor)
            }
        }
        .padding(16)
        .frame(width: 220)
    }
}