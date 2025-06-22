import SwiftUI

/// Focus Settings View - Configuration options for the Focus View
struct FocusSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var focusService = FocusViewService.shared
    
    @State private var maxDailyItems = 12
    @State private var enableMoodAnalysis = true
    @State private var moodAnalysisInterval = 60 // minutes
    @State private var enableAIRecommendations = true
    @State private var enableAchievementBadges = true
    @State private var enableHapticFeedback = true
    @State private var defaultEnergyLevel: EnergyLevel = .medium
    @State private var showCompletedItems = false
    @State private var autoRefreshInterval = 5 // minutes
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Max Daily Items")
                        Spacer()
                        Stepper(value: $maxDailyItems, in: 5...20) {
                            Text("\(maxDailyItems)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Auto Refresh")
                        Spacer()
                        Picker("", selection: $autoRefreshInterval) {
                            Text("1 min").tag(1)
                            Text("5 min").tag(5)
                            Text("10 min").tag(10)
                            Text("15 min").tag(15)
                            Text("Off").tag(0)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Toggle("Show Completed Items", isOn: $showCompletedItems)
                    
                } header: {
                    Text("Display Settings")
                } footer: {
                    Text("Control how many items are shown and how often the list refreshes.")
                }
                
                Section {
                    Toggle("Enable Mood Analysis", isOn: $enableMoodAnalysis)
                    
                    if enableMoodAnalysis {
                        HStack {
                            Text("Analysis Frequency")
                            Spacer()
                            Picker("", selection: $moodAnalysisInterval) {
                                Text("30 min").tag(30)
                                Text("1 hour").tag(60)
                                Text("2 hours").tag(120)
                                Text("4 hours").tag(240)
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("Default Energy Level")
                            Spacer()
                            Picker("", selection: $defaultEnergyLevel) {
                                ForEach(EnergyLevel.allCases, id: \.self) { level in
                                    Text(level.displayName).tag(level)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                } header: {
                    Text("AI Mood Analysis")
                } footer: {
                    Text("AI analyzes your completion patterns to assess mood and energy levels automatically.")
                }
                
                Section {
                    Toggle("AI Recommendations", isOn: $enableAIRecommendations)
                    
                    if enableAIRecommendations {
                        NavigationLink("Recommendation Types") {
                            RecommendationTypesView()
                        }
                        
                        NavigationLink("AI Feedback History") {
                            AIFeedbackHistoryView()
                        }
                    }
                    
                } header: {
                    Text("AI Assistance")
                } footer: {
                    Text("Get smart suggestions for optimizing your daily focus and productivity.")
                }
                
                Section {
                    Toggle("Achievement Badges", isOn: $enableAchievementBadges)
                    Toggle("Haptic Feedback", isOn: $enableHapticFeedback)
                    
                    NavigationLink("Filter Preferences") {
                        FilterPreferencesView()
                    }
                    
                } header: {
                    Text("Experience")
                } footer: {
                    Text("Customize notifications, feedback, and visual preferences.")
                }
                
                Section {
                    NavigationLink("Data & Privacy") {
                        DataPrivacyView()
                    }
                    
                    NavigationLink("Export Focus Data") {
                        ExportDataView()
                    }
                    
                    Button("Reset All Settings") {
                        resetToDefaults()
                    }
                    .foregroundColor(.red)
                    
                } header: {
                    Text("Data Management")
                }
                
                Section {
                    HStack {
                        Text("Focus Score Algorithm")
                        Spacer()
                        Text("v2.1")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Data Sync")
                        Spacer()
                        Text("Just now")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink("About Focus View") {
                        AboutFocusView()
                    }
                    
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Focus Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveSettings() {
        // TODO: Implement settings persistence
        // This would save the settings to UserDefaults or a settings service
    }
    
    private func resetToDefaults() {
        maxDailyItems = 12
        enableMoodAnalysis = true
        moodAnalysisInterval = 60
        enableAIRecommendations = true
        enableAchievementBadges = true
        enableHapticFeedback = true
        defaultEnergyLevel = .medium
        showCompletedItems = false
        autoRefreshInterval = 5
    }
}

// MARK: - Supporting Settings Views

struct RecommendationTypesView: View {
    @State private var enabledTypes: Set<RecommendationType> = Set(RecommendationType.allCases)
    
    var body: some View {
        Form {
            Section {
                ForEach(RecommendationType.allCases, id: \.self) { type in
                    Toggle(isOn: .init(
                        get: { enabledTypes.contains(type) },
                        set: { isOn in
                            if isOn {
                                enabledTypes.insert(type)
                            } else {
                                enabledTypes.remove(type)
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                Text(type.displayName)
                                    .font(.subheadline)
                            }
                            
                            Text(typeDescription(type))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Recommendation Types")
            } footer: {
                Text("Choose which types of AI recommendations you'd like to receive.")
            }
        }
        .navigationTitle("Recommendations")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func typeDescription(_ type: RecommendationType) -> String {
        switch type {
        case .timeOptimization:
            return "Suggestions for better time management"
        case .energyMatching:
            return "Match tasks to your current energy level"
        case .priorityAdjustment:
            return "Recommendations for priority changes"
        case .taskGrouping:
            return "Suggestions for batching similar tasks"
        case .contextSwitching:
            return "Minimize context switching overhead"
        case .deferSuggestion:
            return "Smart suggestions for deferring tasks"
        case .habitReminder:
            return "Reminders for habit-building tasks"
        case .achievementCelebration:
            return "Celebrate accomplishments and milestones"
        }
    }
}

struct AIFeedbackHistoryView: View {
    var body: some View {
        List {
            Section {
                Text("AI feedback history coming soon...")
                    .foregroundColor(.secondary)
            } header: {
                Text("Recent Feedback")
            }
        }
        .navigationTitle("AI Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FilterPreferencesView: View {
    var body: some View {
        Form {
            Section {
                Text("Filter preferences coming soon...")
                    .foregroundColor(.secondary)
            } header: {
                Text("Default Filters")
            }
        }
        .navigationTitle("Filter Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Data & Privacy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("How Your Data is Used")
                        .font(.headline)
                    
                    Text("Focus View analyzes your task completion patterns and behavior to provide personalized insights and recommendations. All analysis is performed locally on your device.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Storage")
                        .font(.headline)
                    
                    Text("Your focus sessions, mood assessments, and preferences are stored locally and synced securely through your iCloud account. No data is shared with third parties.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Processing")
                        .font(.headline)
                    
                    Text("Mood analysis and recommendations are generated using on-device machine learning. Task content may be processed by OpenAI's API for enhanced insights when explicitly enabled.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExportDataView: View {
    @State private var showingExportOptions = false
    
    var body: some View {
        Form {
            Section {
                Button("Export Focus Sessions") {
                    // TODO: Implement export
                }
                
                Button("Export Mood Assessments") {
                    // TODO: Implement export
                }
                
                Button("Export Achievement History") {
                    // TODO: Implement export
                }
                
                Button("Export All Focus Data") {
                    showingExportOptions = true
                }
                .foregroundColor(.blue)
                
            } header: {
                Text("Export Options")
            } footer: {
                Text("Export your data in JSON or CSV format for analysis or backup.")
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Export Format", isPresented: $showingExportOptions) {
            Button("JSON Format") {
                // TODO: Export as JSON
            }
            Button("CSV Format") {
                // TODO: Export as CSV
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

struct AboutFocusView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("About Focus View")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Purpose")
                        .font(.headline)
                    
                    Text("Focus View delivers effortless daily productivity by intelligently curating your most important tasks using AI-powered prioritization and contextual awareness.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Features")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "brain", title: "AI Prioritization", description: "Smart task ranking based on urgency, importance, and patterns")
                        FeatureRow(icon: "heart", title: "Mood Analysis", description: "Passive mood and energy tracking through activity patterns")
                        FeatureRow(icon: "line.3.horizontal.decrease", title: "Smart Filters", description: "Contextual filtering for different work modes")
                        FeatureRow(icon: "bolt", title: "Batch Actions", description: "Efficient multi-task operations")
                        FeatureRow(icon: "star", title: "Achievements", description: "Celebration of productivity milestones")
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Version Information")
                        .font(.headline)
                    
                    Text("Focus View v1.0\nPart of LifeManager v1.9\nBuilt with SwiftUI and AI integration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    FocusSettingsView()
}