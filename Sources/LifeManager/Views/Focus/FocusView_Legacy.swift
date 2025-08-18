import SwiftUI

/// Focus View - Main view for daily productivity focus
/// Delivers effortless daily productivity with AI-powered prioritization and contextual awareness
struct FocusView: View {
    @StateObject private var focusService = FocusViewService.shared
    @State private var showingSettings = false
    @State private var showingBatchActions = false
    @State private var showingFilterCustomization = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                FocusViewHeader(
                    showingSettings: $showingSettings,
                    showingFilterCustomization: $showingFilterCustomization
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Energy Status Card
                        if let moodAssessment = focusService.currentMoodAssessment {
                            EnergyStatusCard(moodAssessment: moodAssessment)
                                .padding(.horizontal)
                        }
                        
                        // Smart Filter Bar
                        SmartFilterBar(
                            activeFilters: $focusService.activeFocusFilters,
                            availableFilters: focusService.availableFilters,
                            onFilterTap: { filter in
                                toggleFilter(filter)
                            },
                            onCustomFilterTap: {
                                showingFilterCustomization = true
                            }
                        )
                        .padding(.horizontal)
                        
                        // Today's Focus List
                        if focusService.isLoading {
                            FocusLoadingView()
                                .frame(height: 200)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(focusService.filteredFocusItems) { item in
                                    FocusItemRow(
                                        item: item,
                                        isSelected: focusService.selectedFocusItems.contains(item.id),
                                        onTap: {
                                            Task {
                                                await focusService.completeFocusItem(item.id)
                                            }
                                        },
                                        onLongPress: {
                                            focusService.toggleItemSelection(item.id)
                                            withAnimation(.spring()) {
                                                showingBatchActions = !focusService.selectedFocusItems.isEmpty
                                            }
                                        },
                                        onSwipeRight: {
                                            Task {
                                                await focusService.completeFocusItem(item.id)
                                            }
                                        },
                                        onSwipeLeft: {
                                            Task {
                                                await focusService.deferFocusItem(item.id)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // AI Recommendations & Quick Actions
                        if !focusService.aiRecommendations.isEmpty {
                            HStack(alignment: .top, spacing: 16) {
                                // AI Recommendations
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "brain")
                                            .foregroundColor(.purple)
                                        Text("AI Recommendations")
                                            .font(.headline)
                                    }
                                    
                                    ForEach(focusService.aiRecommendations.prefix(2)) { recommendation in
                                        AIRecommendationCard(
                                            recommendation: recommendation,
                                            onDismiss: {
                                                // Handle dismissal
                                            },
                                            onApply: {
                                                // Handle applying recommendation
                                            }
                                        )
                                    }
                                }
                                
                                // Quick Actions
                                if !focusService.selectedFocusItems.isEmpty {
                                    QuickActionsPanel(
                                        selectedCount: focusService.selectedFocusItems.count,
                                        onAction: { action in
                                            Task {
                                                await focusService.performBatchAction(action)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Achievement Celebration Banner
                        if !focusService.sessionStats.achievementBadges.isEmpty {
                            ForEach(focusService.sessionStats.achievementBadges.suffix(1)) { badge in
                                CelebrationBanner(
                                    badge: badge,
                                    onDismiss: {
                                        // Handle dismissal
                                    }
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Session Stats Summary
                        FocusSessionSummary(stats: focusService.sessionStats)
                            .padding(.horizontal)
                            .padding(.bottom, 100) // Space for tab bar
                    }
                }
                .refreshable {
                    focusService.refreshFocusSession()
                }
            }
            .navigationTitle("Focus")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(isPresented: $showingSettings) {
                FocusSettingsView()
            }
            .sheet(isPresented: $showingFilterCustomization) {
                FilterCustomizationView(
                    availableFilters: $focusService.availableFilters,
                    activeFilters: $focusService.activeFocusFilters
                )
            }
            .overlay(alignment: .bottom) {
                if showingBatchActions {
                    BatchActionBar(
                        selectedItems: $focusService.selectedFocusItems,
                        onAction: { action in
                            Task {
                                await focusService.performBatchAction(action)
                                withAnimation(.spring()) {
                                    showingBatchActions = false
                                }
                            }
                        },
                        onCancel: {
                            focusService.clearSelection()
                            withAnimation(.spring()) {
                                showingBatchActions = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .onAppear {
            focusService.loadTodaysFocus()
        }
    }
    
    private func toggleFilter(_ filter: FocusFilter) {
        var newFilters = focusService.activeFocusFilters
        
        if newFilters.contains(filter) {
            newFilters.remove(filter)
        } else {
            newFilters.insert(filter)
        }
        
        focusService.applyFilters(newFilters)
    }
}

// MARK: - Focus View Header

struct FocusViewHeader: View {
    @Binding var showingSettings: Bool
    @Binding var showingFilterCustomization: Bool
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Focus")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack {
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack {
                            Text(dateString(selectedDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button("Today") {
                            selectedDate = Date()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    showingFilterCustomization = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Select Date")
                #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            showingDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func dateString(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Loading View

struct FocusLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Preparing your focus session...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Session Summary

struct FocusSessionSummary: View {
    let stats: FocusSessionStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(stats.completionRate * 100))% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            ProgressView(value: stats.completionRate)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            // Stats grid
            HStack(spacing: 24) {
                StatItem(
                    title: "Completed",
                    value: "\(stats.completedItems)",
                    color: .green
                )
                
                StatItem(
                    title: "Total",
                    value: "\(stats.totalItems)",
                    color: .blue
                )
                
                StatItem(
                    title: "Focus Score",
                    value: String(format: "%.1f", stats.focusScore * 10),
                    color: .purple
                )
                
                if stats.totalTimeSpent > 0 {
                    StatItem(
                        title: "Time",
                        value: "\(stats.totalTimeSpent / 60)h",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FocusView()
}