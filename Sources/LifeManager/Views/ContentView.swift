import SwiftUI
import Foundation
import AppKit

//
// ContentView.swift
// LifeManager
//
// Implements: v1.0 "PARA Framework", v1.25 "Enhanced UI", v1.5 "Complete PARA Views", v1.75 "Modular Architecture"
// Roadmap Reference: v1.0 Foundation, v1.25 Intelligence & UI, v1.5 Advanced Features, v1.75 Calendar Revolution
// Status: ✅ COMPLETE as of June 14, 2025 (modularized from 6117 lines to organized components)
// Future: v2.0 Dashboard View, Advanced Analytics
//

/// Main content view for LifeManager
/// Provides PARA-based navigation and content management
/// Central UI coordinator for the entire LifeManager application
struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                MainAppView()
                    .environmentObject(viewModel)
            } else {
                AuthenticationView()
                    .environmentObject(viewModel)
            }
        }
        .overlay(alignment: .bottom) {
            // Success toast
            if let successMessage = viewModel.successMessage {
                ToastView(message: successMessage, type: .success) {
                    viewModel.successMessage = nil
                }
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .overlay(alignment: .bottom) {
            // Error toast (only for critical errors)
            if let errorMessage = viewModel.errorMessage, shouldShowError(errorMessage) {
                ToastView(message: errorMessage, type: .error) {
                viewModel.errorMessage = nil
            }
                .padding(.bottom, viewModel.successMessage != nil ? 80 : 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .onAppear {
            // Ensure window comes to front when content appears
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.makeKeyAndOrderFront(nil)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    /// Determine if error should be shown to user (only critical errors)
    private func shouldShowError(_ errorMessage: String) -> Bool {
        // Only show errors that the user can act upon or are truly critical
        let criticalErrors = [
            "Authentication failed",
            "Network connection",
            "Permission denied",
            "Account"
        ]
        
        // Don't show serialization or processing errors - these are handled internally
        let internalErrors = [
            "Failed to save note",
            "couldn't be read",
            "correct format",
            "Processing failed",
            "LLM"
        ]
        
        // If it's an internal error, don't show it
        for internalError in internalErrors {
            if errorMessage.contains(internalError) {
                return false
            }
        }
        
        // Only show if it's a critical error
        return criticalErrors.contains { errorMessage.contains($0) }
    }
}

/// Main authenticated app interface with PARA navigation
struct MainAppView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                PARANavigation()
                    .environmentObject(viewModel)
                    .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
            },
            detail: {
                PARADetailView()
                    .environmentObject(viewModel)
            }
        )
        .searchable(text: $viewModel.searchText, prompt: "Search across all content")
        .onSubmit(of: .search) {
            Task {
                await viewModel.search(query: viewModel.searchText)
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    Task {
                        await viewModel.refreshData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        })
    }
}

/// PARA navigation sidebar
struct PARANavigation: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        List(selection: $viewModel.selectedView) {
            // Inbox
            NavigationLink(destination: InboxView().environmentObject(viewModel)) {
                Label("Inbox", systemImage: "tray")
            }
            .tag(PARAView.inbox)
            
            Section("PARA") {
                NavigationLink(destination: ProjectsView().environmentObject(viewModel)) {
                    Label("Projects", systemImage: "folder")
                }
                .tag(PARAView.projects)
                
                NavigationLink(destination: AreasView().environmentObject(viewModel)) {
                    Label("Areas", systemImage: "circles.hexagongrid")
                }
                .tag(PARAView.areas)
                
                NavigationLink(destination: ResourcesView().environmentObject(viewModel)) {
                    Label("Resources", systemImage: "books.vertical")
                }
                .tag(PARAView.resources)
                
                NavigationLink(destination: ArchivesView().environmentObject(viewModel)) {
                    Label("Archives", systemImage: "archivebox")
                }
                .tag(PARAView.archives)
            }
            
            Section("Views") {
                NavigationLink(destination: FocusView().environmentObject(viewModel)) {
                    Label("Focus", systemImage: "scope")
                }
                .tag(PARAView.focus)
                
                NavigationLink(destination: CalendarView().environmentObject(viewModel)) {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(PARAView.calendar)
                
                NavigationLink(destination: TimelineView().environmentObject(viewModel)) {
                    Label("Timeline", systemImage: "timeline.selection")
                }
                .tag(PARAView.timeline)
                
                NavigationLink(destination: MindmapView().environmentObject(viewModel)) {
                    Label("Mind Map", systemImage: "brain.head.profile")
                }
                .tag(PARAView.mindmap)
                
                NavigationLink(destination: TagsView().environmentObject(viewModel)) {
                    Label("Tags", systemImage: "tag")
                }
                .tag(PARAView.tags)
            }
            
            Section("Search & History") {
                                NavigationLink(destination: SearchView().environmentObject(viewModel)) {
                    Label("Advanced Search", systemImage: "magnifyingglass")
                }
                .tag(PARAView.search)
                
                NavigationLink(destination: HistoryView().environmentObject(viewModel)) {
                    Label("History", systemImage: "clock")
                }
                .tag(PARAView.history)
            }
        }
        .navigationTitle("LifeManager")
    }
}

/// Detail view for PARA content
struct PARADetailView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        Group {
            switch viewModel.selectedView {
            case .inbox:
                InboxView()
            case .projects:
                ProjectsView()
            case .areas:
                AreasView()
            case .resources:
                ResourcesView()
            case .archives:
                ArchivesView()
            case .focus:
                FocusView()
            case .search:
                SearchView()
            case .history:
                HistoryView()
            case .tags:
                TagsView()
            case .mindmap:
                MindmapView()
            case .calendar:
                CalendarView()
                    .environmentObject(viewModel)
            case .timeline:
                TimelineView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// Inbox view for unprocessed content
struct InboxView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Natural Language Input Area - Takes up significant space
            VStack(spacing: 20) {
                NaturalLanguageInputView()
                    .environmentObject(viewModel)
                    .frame(maxHeight: .infinity) // Let input take up as much space as possible
                
                // No bulk actions toolbar - removed notes from inbox
            }
            .frame(minHeight: 300) // Minimum height for input area
            .padding()
            
            Divider()
            
            // Empty space - no notes list, just history in input area
            Spacer()
                .frame(maxHeight: .infinity)
            
            // Show loading state
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing notes with AI...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $viewModel.showingConfirmationDialog) {
            ProcessingConfirmationView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showingProcessingSummary) {
            ProcessingSummaryView()
                .environmentObject(viewModel)
        }
    }
}

/// Natural language input view
struct NaturalLanguageInputView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var inputText = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 16) {
                // Centered greeting
                HStack {
                    Spacer()
                    Text("Good to see you, Anmol.")
                        .font(.title)
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            
            // Large text editor taking up significant vertical space
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .font(.body)
                    .padding(12)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .frame(minHeight: 200, maxHeight: .infinity)
                    .disabled(isProcessing)
                
                // Placeholder text
                if inputText.isEmpty {
                    Text("What's on your mind?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            
            // Button area below input with centered thinking text
            HStack {
                // Show thinking text in center when processing
                if viewModel.isProcessingInbox || isProcessing {
                    HStack {
                        Spacer()
                        if !viewModel.brainDumpProgressMessage.isEmpty {
                            Text(viewModel.brainDumpProgressMessage)
                                .font(.title)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        } else {
                            Text("Thinking")
                                .font(.title)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                } else {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("ChatGPT 4.1")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            submitInput()
                        }) {
                            Image(systemName: "arrow.up")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .disabled(inputText.isEmpty || isProcessing)
                        .buttonStyle(.plain)
                        .frame(width: 28, height: 28)
                        .background(inputText.isEmpty || isProcessing ? Color.gray : Color.blue)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.top, 8)
            
            // Show elapsed time if available (separate row)
            if viewModel.brainDumpElapsedTime > 0 {
                let minutes = viewModel.brainDumpElapsedTime / 60
                let seconds = viewModel.brainDumpElapsedTime % 60
                let timeString = minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
                
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Processing time: \(timeString)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
            
            // History section
            if !viewModel.inboxHistory.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Processing History")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(viewModel.inboxHistory.enumerated()), id: \.offset) { index, item in
                        InboxHistoryRow(item: item)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .sheet(isPresented: $viewModel.showingBrainDumpReview) {
            if let result = viewModel.brainDumpResult {
                BrainDumpReviewView(
                    result: result,
                    onComplete: { summary in
                        viewModel.completeBrainDump(summary)
                    },
                    onCancel: {
                        viewModel.cancelBrainDump()
                    }
                )
            }
        }
    }
    
    private func submitInput() {
        guard !inputText.isEmpty else { return }
        
        isProcessing = true
        
        // Set the input in the view model and trigger brain dump processing
        viewModel.inboxInput = inputText
        
        // Clear input immediately for better UX
        inputText = ""
        
        // Process using brain dump processor
        viewModel.processInboxInput()
        
        // Reset local processing state quickly, but keep viewModel.isProcessingInbox for persistent updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
        }
    }
}

/// History row for inbox processing
struct InboxHistoryRow: View {
    let item: InboxHistoryItem
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(item.input.prefix(40)) + (item.input.count > 40 ? "..." : ""))
                    .font(.caption)
                    .lineLimit(1)
                
                Text(RelativeDateTimeFormatter().localizedString(for: item.timestamp, relativeTo: Date()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.itemsCreated) items")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                if !item.categories.isEmpty {
                    Text(item.categories.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

/// Row view for displaying blobs
struct BlobRowView: View {
    let blob: Blob
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingProcessingDetails = false
    
    private var processingState: BlobProcessingState {
        viewModel.getProcessingState(for: blob.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: sourceTypeIcon(blob.sourceType))
                    .foregroundColor(.blue)
                
                Text(blob.sourceType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Individual process button (only show if not processed)
                if !processingState.isProcessed && !blob.processed {
                    Button(action: {
                        Task {
                            await viewModel.processBlobIndividually(blob)
                        }
                    }) {
                        Image(systemName: "brain")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Process with AI")
                }
                
                // Delete button
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete this note")
                
                Text(RelativeDateTimeFormatter().localizedString(for: ISO8601DateFormatter().date(from: blob.createdAt) ?? Date(), relativeTo: Date()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(blob.content)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Label(blob.workPersonal.rawValue.capitalized, systemImage: blob.workPersonal == .work ? "briefcase" : "house")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Show only ONE processing status (consolidated)
                if let result = viewModel.processingResults[blob.id] {
                    ProcessingResultSummary(result: result)
                        .onTapGesture {
                            showingProcessingDetails = true
                        }
                } else {
                    // Show processing state based on database field and runtime state
                    let isProcessed = blob.processed || processingState.isProcessed
                    if isProcessed {
                        Label("Processed", systemImage: "checkmark.circle")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Label("Unprocessed", systemImage: "exclamationmark.circle")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .alert("Delete Note", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteBlob(blob)
                }
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
        .sheet(isPresented: $showingProcessingDetails) {
            if let result = viewModel.processingResults[blob.id] {
                ProcessingDetailsView(blob: blob, result: result)
                    .environmentObject(viewModel)
            }
        }
    }
    
    private func sourceTypeIcon(_ type: SourceType) -> String {
        switch type {
        case .note: return "note.text"
        case .journal: return "book"
        case .email: return "envelope"
        case .meeting: return "person.2"
        case .idea: return "lightbulb"
        case .research: return "magnifyingglass"
        case .recipe: return "fork.knife"
        case .financial: return "dollarsign.circle"
        case .inventory: return "list.clipboard"
        case .knowledge: return "brain"
        case .therapy: return "heart"
        case .media: return "play.rectangle"
        case .grocery: return "cart"
        default: return "doc.text"
        }
    }
}

/// Processing state indicator
struct ProcessingStateView: View {
    let state: BlobProcessingState
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)
            
            Text(state.displayName)
                .font(.caption2)
                .foregroundColor(state.color)
        }
    }
}

/// Processing result summary
struct ProcessingResultSummary: View {
    let result: ProcessingResult
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: result.paraCategory.icon)
                .foregroundColor(.blue)
                .font(.caption)
            
            Text(result.paraCategory.displayName)
                .font(.caption2)
                .foregroundColor(.blue)
            
            if !result.extractedTasks.isEmpty {
                Text("• \(result.extractedTasks.count) task\(result.extractedTasks.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            if !result.autoTags.isEmpty {
                Text("• \(result.autoTags.count) tag\(result.autoTags.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(4)
    }
}

/// Processing details view
struct ProcessingDetailsView: View {
    let blob: Blob
    let result: ProcessingResult
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Original content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original Note")
                            .font(.headline)
                        
                        Text(blob.content)
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    
                    // AI Analysis
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Analysis")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: result.paraCategory.icon)
                                .foregroundColor(.blue)
                            Text("Category: \(result.paraCategory.displayName)")
                            Spacer()
                            ConfidenceIndicator(confidence: result.confidence)
                        }
                        
                        if let area = result.suggestedArea {
                            HStack {
                                Image(systemName: "square.stack.3d.up")
                                    .foregroundColor(.green)
                                Text("Area: \(area)")
                                Spacer()
                            }
                        }
                        
                        if let project = result.suggestedProject {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.orange)
                                Text("Project: \(project)")
                                Spacer()
                            }
                        }
                        
                        if !result.extractedTasks.isEmpty {
                            Text("Extracted Tasks (\(result.extractedTasks.count))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(result.extractedTasks) { task in
                                HStack {
                                    Circle()
                                        .fill(priorityColor(task.priority))
                                        .frame(width: 8, height: 8)
                                    Text(task.title)
                                    Spacer()
                                    Text(task.priority.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if !result.autoTags.isEmpty {
                            Text("Auto Tags")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(result.autoTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        if let summary = result.summary {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Summary")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(summary)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Actions taken
                    if !result.actions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Actions Taken")
                                .font(.headline)
                            
                            ForEach(result.actions) { action in
                                HStack {
                                    Image(systemName: action.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(action.success ? .green : .red)
                                    
                                    Text(action.description)
                                        .font(.body)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Processing Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if result.requiresConfirmation {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Approve Processing") {
                            Task {
                                await viewModel.confirmProcessing(for: result, approved: true)
                                dismiss()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
}

/// Areas overview
struct AreasView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var workPersonalFilter: WorkPersonalType? = nil
    
    private var filteredAreas: [Area] {
        guard let filter = workPersonalFilter else { return viewModel.areas }
        return viewModel.areas.filter { $0.workPersonal == filter }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Work/Personal toggle
            HStack {
                Text("Areas")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Work/Personal filter toggle
                HStack(spacing: 4) {
                    FilterToggleButton(
                        title: "Personal",
                        isSelected: workPersonalFilter == .personal,
                        action: {
                            workPersonalFilter = workPersonalFilter == .personal ? nil : .personal
                        }
                    )
                    
                    FilterToggleButton(
                        title: "Work",
                        isSelected: workPersonalFilter == .work,
                        action: {
                            workPersonalFilter = workPersonalFilter == .work ? nil : .work
                        }
                    )
                }
            }
            .padding()
            
            // Areas list with expandable sections (consistent with Projects/Resources)
            if filteredAreas.isEmpty {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No areas yet",
                        systemImage: "square.grid.2x2",
                        description: Text("AI will create areas from your notes automatically")
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No areas yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("AI will create areas from your notes automatically")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                List {
                    ForEach(filteredAreas) { area in
                        AreaSectionView(area: area)
                            .environmentObject(viewModel)
                    }
                }
            }
        }
    }
}

struct AreaCardView: View {
    let area: Area
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDeleteConfirmation = false
    @State private var isExpanded = false
    
    private var areaBlobs: [Blob] {
        return viewModel.areaBlobs[area.id] ?? []
    }
    
    private var areaTasks: [LifeTask] {
        return viewModel.areaTasks[area.id] ?? []
    }
    
    private var totalItemCount: Int {
        return areaBlobs.count + areaTasks.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if let iconName = area.icon {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(Color(hex: area.color))
                }
                
                Spacer()
                
                // Content count
                if totalItemCount > 0 {
                    Text("\(totalItemCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: area.color))
                        .cornerRadius(8)
                }
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                
                // Delete button
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Delete this area")
                
                Circle()
                    .fill(Color(hex: area.color))
                    .frame(width: 12, height: 12)
            }
            
            Text(area.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            if let description = area.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
            }
            
            // Content section (expandable) - showing both tasks and blobs
            if isExpanded && totalItemCount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    // Tasks section
                    if !areaTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tasks (\(areaTasks.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            
                            ForEach(areaTasks.prefix(3)) { task in
                                HStack(spacing: 8) {
                                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.status == .completed ? .green : .blue)
                                        .font(.caption)
                                    
                                    Text(task.title)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    // Priority indicator
                                    if task.priority == .urgent {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 6, height: 6)
                                    } else if task.priority == .high {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .padding(.vertical, 1)
                            }
                            
                            if areaTasks.count > 3 {
                                Text("... and \(areaTasks.count - 3) more tasks")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                    
                    // Content/blobs section
                    if !areaBlobs.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes (\(areaBlobs.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            
                            ForEach(areaBlobs.prefix(3)) { blob in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.purple.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                    
                                    Text(String(blob.content.prefix(50)) + (blob.content.count > 50 ? "..." : ""))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 1)
                            }
                            
                            if areaBlobs.count > 3 {
                                Text("... and \(areaBlobs.count - 3) more notes")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                }
            } else if !isExpanded {
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .frame(minHeight: isExpanded ? 200 : 120)
        .alert("Delete Area", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteArea(area)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(area.name)'? This action cannot be undone.")
        }
    }
}

/// Expandable area section showing area info, tasks, and blobs (consistent with Projects)
struct AreaSectionView: View {
    let area: Area
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDeleteConfirmation = false
    @State private var isExpanded = false
    
    private var areaBlobs: [Blob] {
        return viewModel.areaBlobs[area.id] ?? []
    }
    
    private var areaTasks: [LifeTask] {
        return viewModel.areaTasks[area.id] ?? []
    }
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                // Area content - both tasks and blobs
                if areaTasks.isEmpty && areaBlobs.isEmpty {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(.secondary)
                        Text("No content yet - AI will organize relevant tasks and notes here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else {
                    LazyVStack(spacing: 12) {
                        // Tasks section
                        if !areaTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.blue)
                                    Text("Tasks (\(areaTasks.count))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                ForEach(areaTasks) { task in
                                    AreaTaskRowView(task: task, area: area)
                                        .environmentObject(viewModel)
                                }
                            }
                        }
                        
                        // Notes section
                        if !areaBlobs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.purple)
                                    Text("Notes (\(areaBlobs.count))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                ForEach(areaBlobs) { blob in
                                    AreaBlobRowView(blob: blob, area: area)
                                        .environmentObject(viewModel)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            },
            label: {
                HStack {
                    // Area icon and info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if let iconName = area.icon {
                                Image(systemName: iconName)
                                    .foregroundColor(Color(hex: area.color))
                            } else {
                                Image(systemName: "square.grid.2x2")
                                    .foregroundColor(Color(hex: area.color))
                            }
                            
                            Text(area.name)
                                .font(.headline)
                            
                            // Work/Personal badge
                            Text(area.workPersonal.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(area.workPersonal == .work ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                                .foregroundColor(area.workPersonal == .work ? .blue : .green)
                                .cornerRadius(8)
                        }
                        
                        if let description = area.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        // AI insights
                        let totalItems = areaTasks.count + areaBlobs.count
                        if totalItems > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("\(areaTasks.count) tasks, \(areaBlobs.count) notes")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete this area")
                }
            }
        )
        .alert("Delete Area", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteArea(area)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(area.name)'? This action cannot be undone.")
        }
    }
}

/// Individual task row within an area
struct AreaTaskRowView: View {
    let task: LifeTask
    let area: Area
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Task status
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.status == .completed ? .green : .blue)
                .font(.body)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    // Priority
                    if task.priority != .medium {
                        Label(task.priority.rawValue.capitalized, systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundColor(task.priority == .urgent ? .red : .orange)
                    }
                    
                    // Due date
                    if let dueDate = task.dueDate {
                        Label(formatRelativeDate(dueDate), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Created date
                    Text(formatRelativeDate(task.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

/// Individual blob row within an area
struct AreaBlobRowView: View {
    let blob: Blob
    let area: Area
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingAIDetails = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                Text(blob.content)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    // Source type
                    Label(blob.sourceType.rawValue.capitalized, systemImage: sourceTypeIcon(blob.sourceType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Work/Personal
                    Text(blob.workPersonal.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(blob.workPersonal == .work ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        .foregroundColor(blob.workPersonal == .work ? .blue : .green)
                        .cornerRadius(4)
                    
                    // AI assignment indicator
                    Button(action: {
                        showingAIDetails = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "brain")
                            Text("AI assigned")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("See why AI assigned this to \(area.name)")
                    
                    Spacer()
                    
                    // Timestamp
                    Text(formatRelativeDate(blob.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .sheet(isPresented: $showingAIDetails) {
            AITransparencyView(blob: blob, area: area)
                .environmentObject(viewModel)
        }
    }
    
    private func sourceTypeIcon(_ sourceType: SourceType) -> String {
        switch sourceType {
        case .note: return "note.text"
        case .journal: return "book"
        case .email: return "envelope"
        case .meeting: return "person.2"
        case .idea: return "lightbulb"
        case .research: return "magnifyingglass"
        case .recipe: return "fork.knife"
        case .financial: return "dollarsign.circle"
        case .inventory: return "list.clipboard"
        case .knowledge: return "brain"
        case .therapy: return "heart"
        case .media: return "play.rectangle"
        case .grocery: return "cart"
        default: return "doc.text"
        }
    }
}

/// Projects view
struct ProjectsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var workPersonalFilter: WorkPersonalType? = nil
    
    private var filteredProjects: [Project] {
        guard let filter = workPersonalFilter else { return viewModel.projects }
        return viewModel.projects.filter { $0.workPersonal == filter }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI processing info and Work/Personal toggle
            VStack(spacing: 16) {
                HStack {
                    Text("Projects")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Work/Personal filter toggle
                    HStack(spacing: 4) {
                        FilterToggleButton(
                            title: "Personal",
                            isSelected: workPersonalFilter == .personal,
                            action: {
                                workPersonalFilter = workPersonalFilter == .personal ? nil : .personal
                            }
                        )
                        
                        FilterToggleButton(
                            title: "Work",
                            isSelected: workPersonalFilter == .work,
                            action: {
                                workPersonalFilter = workPersonalFilter == .work ? nil : .work
                            }
                        )
                    }
                    
                    // AI processing status
                    if !viewModel.projectBlobs.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "brain")
                                .foregroundColor(.blue)
                            
                            let totalProjectBlobs = viewModel.projectBlobs.values.flatMap { $0 }.count
                            Text("AI organized \(totalProjectBlobs) notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Quick stats
                if !filteredProjects.isEmpty {
                    HStack(spacing: 20) {
                        StatView(
                            title: "Active Projects", 
                            value: "\(filteredProjects.filter { $0.status == .active }.count)",
                            color: .green
                        )
                        StatView(
                            title: "Total Notes", 
                            value: "\(viewModel.projectBlobs.values.flatMap { $0 }.count)",
                            color: .blue
                        )
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Projects list with expandable sections
            if filteredProjects.isEmpty {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No projects yet",
                        systemImage: "target",
                        description: Text("AI will create projects from your notes automatically")
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No projects yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("AI will create projects from your notes automatically")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                List {
                    ForEach(filteredProjects) { project in
                        ProjectSectionView(project: project)
                            .environmentObject(viewModel)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
    }
}

/// Expandable project section showing project info and its blobs
struct ProjectSectionView: View {
    let project: Project
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDeleteConfirmation = false
    @State private var isExpanded = false
    
    private var projectBlobs: [Blob] {
        return viewModel.projectBlobs[project.id] ?? []
    }
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                // Project content - blobs assigned to this project
                if projectBlobs.isEmpty {
                    HStack {
                        Image(systemName: "tray")
                            .foregroundColor(.secondary)
                        Text("No content yet - AI will organize relevant notes here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(projectBlobs) { blob in
                            ProjectBlobRowView(blob: blob, project: project)
                                .environmentObject(viewModel)
                        }
                    }
                    .padding(.top, 8)
                }
            },
            label: {
                HStack {
                    // Project icon and info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.blue)
                            
                            Text(project.name)
                                .font(.headline)
                            
                            // Status badge
                            Text(project.status.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(project.status == .active ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                                .foregroundColor(project.status == .active ? .green : .gray)
                                .cornerRadius(8)
                        }
                        
                        if let description = project.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        // AI insights
                        if !projectBlobs.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("\(projectBlobs.count) AI-organized notes")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete this project")
                }
            }
        )
        .alert("Delete Project", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteProject(project)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(project.name)'? This action cannot be undone.")
        }
    }
}

/// Individual blob row within a project with AI transparency
struct ProjectBlobRowView: View {
    let blob: Blob
    let project: Project
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingAIDetails = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                Text(blob.content)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    // Source type
                    Label(blob.sourceType.rawValue.capitalized, systemImage: sourceTypeIcon(blob.sourceType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Work/Personal
                    Text(blob.workPersonal.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(blob.workPersonal == .work ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        .foregroundColor(blob.workPersonal == .work ? .blue : .green)
                        .cornerRadius(4)
                    
                    // AI assignment indicator
                    Button(action: {
                        showingAIDetails = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "brain")
                            Text("AI assigned")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("See why AI assigned this to \(project.name)")
                    
                    Spacer()
                    
                    // Timestamp
                    Text(formatRelativeDate(blob.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .sheet(isPresented: $showingAIDetails) {
            AITransparencyView(blob: blob, project: project)
                .environmentObject(viewModel)
        }
    }
    
    private func sourceTypeIcon(_ sourceType: SourceType) -> String {
        switch sourceType {
        case .note: return "note.text"
        case .journal: return "book"
        case .email: return "envelope"
        case .meeting: return "person.2"
        case .idea: return "lightbulb"
        case .research: return "magnifyingglass"
        case .recipe: return "fork.knife"
        case .financial: return "dollarsign.circle"
        case .inventory: return "list.clipboard"
        case .knowledge: return "brain"
        case .therapy: return "heart"
        case .media: return "play.rectangle"
        case .grocery: return "cart"
        default: return "doc.text"
        }
    }
}

/// Resources view
struct ResourcesView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var workPersonalFilter: WorkPersonalType? = nil
    
    private let resourceCategories = [
        "Research Papers", "Articles", "Videos", "Books", 
        "Guides", "Recipes", "Insights", "References"
    ]
    
    private var filteredResources: [Resource] {
        guard let filter = workPersonalFilter else { return viewModel.resources }
        return viewModel.resources.filter { $0.workPersonal == filter }
    }
    
    private var filteredResourceBlobs: [Blob] {
        guard let filter = workPersonalFilter else { return viewModel.resourceBlobs }
        return viewModel.resourceBlobs.filter { $0.workPersonal == filter }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI transparency and Work/Personal toggle
            VStack(spacing: 16) {
                HStack {
                    Text("Resources")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Work/Personal filter toggle
                    HStack(spacing: 4) {
                        FilterToggleButton(
                            title: "Personal",
                            isSelected: workPersonalFilter == .personal,
                            action: {
                                workPersonalFilter = workPersonalFilter == .personal ? nil : .personal
                            }
                        )
                        
                        FilterToggleButton(
                            title: "Work",
                            isSelected: workPersonalFilter == .work,
                            action: {
                                workPersonalFilter = workPersonalFilter == .work ? nil : .work
                            }
                        )
                    }
                    
                    // AI processing status
                    if !filteredResourceBlobs.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            
                            Text("AI organized \(filteredResourceBlobs.count) references")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Quick stats
                HStack(spacing: 20) {
                    StatView(
                        title: "Resource Types", 
                        value: "\(filteredResources.count)",
                        color: .purple
                    )
                    StatView(
                        title: "AI References", 
                        value: "\(filteredResourceBlobs.count)",
                        color: .blue
                    )
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor))
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Formal Resources (created by user/system)
                    if !filteredResources.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "books.vertical")
                                    .foregroundColor(.purple)
                                Text("Curated Resources")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(filteredResources) { resource in
                                ResourceRowView(resource: resource)
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    
                    // AI-Organized References by Category
                    if !filteredResourceBlobs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "brain")
                                    .foregroundColor(.blue)
                                Text("AI-Organized References")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Group resource blobs by inferred category
                            ForEach(resourceCategories, id: \.self) { category in
                                let categoryBlobs = getCategoryBlobs(category: category)
                                if !categoryBlobs.isEmpty {
                                    ResourceCategorySection(
                                        category: category,
                                        blobs: categoryBlobs
                                    )
                                    .environmentObject(viewModel)
                                }
                            }
                            
                            // Uncategorized resources
                            let uncategorizedBlobs = filteredResourceBlobs.filter { blob in
                                !resourceCategories.contains { category in
                                    blobMatchesCategory(blob: blob, category: category)
                                }
                            }
                            
                            if !uncategorizedBlobs.isEmpty {
                                ResourceCategorySection(
                                    category: "General References",
                                    blobs: uncategorizedBlobs
                                )
                                .environmentObject(viewModel)
                            }
                        }
                    }
                    
                    // Empty state
                    if filteredResources.isEmpty && filteredResourceBlobs.isEmpty {
                        if #available(macOS 14.0, *) {
                            ContentUnavailableView(
                                "No resources yet",
                                systemImage: "books.vertical",
                                description: Text("AI will organize reference materials and knowledge items here")
                            )
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No resources yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("AI will organize reference materials and knowledge items here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
    }
    
    private func getCategoryBlobs(category: String) -> [Blob] {
        return filteredResourceBlobs.filter { blob in
            blobMatchesCategory(blob: blob, category: category)
        }
    }
    
    private func blobMatchesCategory(blob: Blob, category: String) -> Bool {
        let content = blob.content.lowercased()
        switch category {
        case "Research Papers":
            return content.contains("research") || content.contains("paper") || content.contains("study")
        case "Articles":
            return content.contains("article") || content.contains("blog") || content.contains("post")
        case "Videos":
            return content.contains("video") || content.contains("youtube") || content.contains("watch")
        case "Books":
            return content.contains("book") || content.contains("read") || content.contains("chapter")
        case "Guides":
            return content.contains("guide") || content.contains("tutorial") || content.contains("how to")
        case "Recipes":
            return content.contains("recipe") || content.contains("cook") || content.contains("ingredient")
        case "Insights":
            return content.contains("insight") || content.contains("learning") || content.contains("takeaway")
        case "References":
            return content.contains("reference") || content.contains("link") || content.contains("source")
        default:
            return false
        }
    }
}

struct ResourceRowView: View {
    let resource: Resource
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.purple)
            
            VStack(alignment: .leading) {
                Text(resource.title)
                    .font(.headline)
                
                if let summary = resource.summary {
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Delete button
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Delete this resource")
            
            // Type badge
            Text(resource.type.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.2))
                .foregroundColor(.purple)
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
        .alert("Delete Resource", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteResource(resource)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(resource.title)'? This action cannot be undone.")
        }
    }
}

/// Archives view
struct ArchivesView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var completedTasks: [LifeTask] = []
    @State private var recentlyDeletedTasks: [LifeTask] = []
    @State private var workPersonalFilter: WorkPersonalType? = nil
    
    private let archiveCategories = [
        "Recently Deleted", "Completed Tasks", "Completed Projects", "Inactive Areas", "Old Resources", 
        "Past Notes", "Outdated References", "Historical Data"
    ]
    
    private var filteredArchives: [Archive] {
        guard let filter = workPersonalFilter else { return viewModel.archives }
        return viewModel.archives.filter { $0.workPersonal == filter }
    }
    
    private var filteredArchivedBlobs: [Blob] {
        guard let filter = workPersonalFilter else { return viewModel.archivedBlobs }
        return viewModel.archivedBlobs.filter { $0.workPersonal == filter }
    }
    
    private var filteredCompletedTasks: [LifeTask] {
        guard let filter = workPersonalFilter else { return completedTasks }
        return completedTasks.filter { $0.workPersonal == filter }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI transparency and Work/Personal toggle
            VStack(spacing: 16) {
                HStack {
                    Text("Archives")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Work/Personal filter toggle
                    HStack(spacing: 4) {
                        FilterToggleButton(
                            title: "Personal",
                            isSelected: workPersonalFilter == .personal,
                            action: {
                                workPersonalFilter = workPersonalFilter == .personal ? nil : .personal
                            }
                        )
                        
                        FilterToggleButton(
                            title: "Work",
                            isSelected: workPersonalFilter == .work,
                            action: {
                                workPersonalFilter = workPersonalFilter == .work ? nil : .work
                            }
                        )
                    }
                    
                    // Archive stats
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("\(filteredCompletedTasks.count) completed • \(filteredArchivedBlobs.count) archived")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Description
                Text("Completed tasks and archived items from Projects, Areas, and Resources")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor))
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Formal Archives (created by user/system)
                    if !filteredArchives.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "archivebox")
                                    .foregroundColor(.gray)
                                Text("Formal Archives")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(filteredArchives) { archive in
                                ArchiveRowView(archive: archive)
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    
                    // AI-Archived Content by Category
                    if !filteredArchivedBlobs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "brain")
                                    .foregroundColor(.blue)
                                Text("AI-Archived Content")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Group content by inferred category (tasks and blobs)
                            ForEach(archiveCategories, id: \.self) { category in
                                let categoryBlobs = getArchiveCategoryBlobs(category: category)
                                let categoryTasks = getArchiveCategoryTasks(category: category)
                                if !categoryBlobs.isEmpty || !categoryTasks.isEmpty {
                                    ArchiveCategorySection(
                                        category: category,
                                        blobs: categoryBlobs,
                                        tasks: categoryTasks
                                    )
                                    .environmentObject(viewModel)
                                }
                            }
                            
                            // Uncategorized archived items
                            let uncategorizedBlobs = filteredArchivedBlobs.filter { blob in
                                !archiveCategories.contains { category in
                                    archiveBlobMatchesCategory(blob: blob, category: category)
                                }
                            }
                            
                            if !uncategorizedBlobs.isEmpty {
                                ArchiveCategorySection(
                                    category: "General Archives",
                                    blobs: uncategorizedBlobs,
                                    tasks: []
                                )
                                .environmentObject(viewModel)
                            }
                        }
                    }
                    
                    // Empty state
                    if filteredArchives.isEmpty && filteredArchivedBlobs.isEmpty {
                        if #available(macOS 14.0, *) {
                            ContentUnavailableView(
                                "No archived items",
                                systemImage: "archivebox",
                                description: Text("Completed projects and inactive items will appear here")
                            )
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "archivebox")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No archived items")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Completed projects and inactive items will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
                await loadCompletedTasks()
                await loadRecentlyDeletedTasks()
            }
        }
    }
    
    private func loadCompletedTasks() async {
        do {
            let taskRepository = TaskRepository()
            let completed = try await taskRepository.fetchTasks(status: .completed)
            await MainActor.run {
                self.completedTasks = completed
            }
        } catch {
            Logger.shared.debug("Failed to load completed tasks: \(error.localizedDescription)")
        }
    }
    
    private func loadRecentlyDeletedTasks() async {
        do {
            let taskRepository = TaskRepository()
            let deleted = try await taskRepository.fetchRecentlyDeletedTasks()
            await MainActor.run {
                self.recentlyDeletedTasks = deleted
            }
        } catch {
            Logger.shared.debug("Failed to load recently deleted tasks: \(error.localizedDescription)")
        }
    }
    
    private func getArchiveCategoryBlobs(category: String) -> [Blob] {
        return filteredArchivedBlobs.filter { blob in
            archiveBlobMatchesCategory(blob: blob, category: category)
        }
    }
    
    private func getArchiveCategoryTasks(category: String) -> [LifeTask] {
        if category == "Completed Tasks" {
            return filteredCompletedTasks
        }
        return []
    }
    
    private func archiveBlobMatchesCategory(blob: Blob, category: String) -> Bool {
        let content = blob.content.lowercased()
        let createdDateString = blob.createdAt
        
        // Parse the date string to Date object
        let formatter = ISO8601DateFormatter()
        let createdDate = formatter.date(from: createdDateString) ?? Date()
        
        let isOld = Calendar.current.dateInterval(of: .month, for: createdDate)?.start ?? Date() < Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        
        switch category {
        case "Recently Deleted":
            return false // Tasks are handled separately
        case "Completed Tasks":
            return false // Tasks are handled separately
        case "Completed Projects":
            return content.contains("completed") || content.contains("finished") || content.contains("done")
        case "Inactive Areas":
            return content.contains("stopped") || content.contains("paused") || content.contains("inactive")
        case "Old Resources":
            return isOld && (content.contains("reference") || content.contains("resource"))
        case "Past Notes":
            return isOld && blob.sourceType == .note
        case "Outdated References":
            return isOld && (content.contains("link") || content.contains("url") || content.contains("http"))
        case "Historical Data":
            return isOld
        default:
            return false
        }
    }
}

struct ArchiveRowView: View {
    let archive: Archive
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack {
            Image(systemName: archiveTypeIcon(archive.contentType))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text(archive.title)
                    .font(.headline)
                
                HStack {
                    Text("Archived from: \(archive.contentType.capitalized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let archivedDate = archive.archivedAt {
                        Text("• \(RelativeDateTimeFormatter().localizedString(for: ISO8601DateFormatter().date(from: archivedDate) ?? Date(), relativeTo: Date()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Restore button
            Button(action: {
                Task {
                    await viewModel.restoreFromArchive(archive)
                }
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .help("Restore from archive")
            
            // Delete button
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Delete permanently")
        }
        .padding(.vertical, 4)
        .alert("Delete Archive", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteArchive(archive)
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete '\(archive.title)'? This action cannot be undone.")
        }
    }
    
    private func archiveTypeIcon(_ contentType: String) -> String {
        switch contentType.lowercased() {
        case "project": return "target"
        case "area": return "square.stack.3d.up"  
        case "resource": return "books.vertical"
        default: return "archivebox"
        }
    }
}

/// Focus view for focus tasks
struct FocusView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            if viewModel.focusTasks.isEmpty {
                if #available(macOS 14.0, *) {
                ContentUnavailableView(
                    "No focus tasks",
                    systemImage: "target",
                    description: Text("Mark tasks as focus to see them here")
                )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No focus tasks")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Mark tasks as focus to see them here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            } else {
                List(viewModel.focusTasks) { task in
                    TaskRowView(task: task)
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: LifeTask
    @EnvironmentObject var viewModel: MainViewModel
    @State private var isCompleting = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator with score
            VStack(spacing: 2) {
            Circle()
                .fill(priorityColor(task.priority))
                    .frame(width: 16, height: 16)
                
                Text("\(task.priority.priorityScore)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(priorityColor(task.priority))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Task title
                Text(task.title)
                    .font(.headline)
                    .lineLimit(2)
                
                // Description if available
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Task metadata row
                HStack(spacing: 12) {
                    // Priority label
                    HStack(spacing: 4) {
                        Image(systemName: priorityIcon(task.priority))
                            .font(.caption)
                            .foregroundColor(priorityColor(task.priority))
                        Text(task.priority.displayName)
                            .font(.caption)
                            .foregroundColor(priorityColor(task.priority))
                            .fontWeight(.medium)
                    }
                    
                    // Due date if available
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatTaskDate(dueDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Duration if available
                    if let duration = task.estimatedDuration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(duration)m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                }
            }
            
            Spacer()
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                // Focus indicator
            if task.isFocus {
                Image(systemName: "target")
                    .foregroundColor(.orange)
                        .font(.system(size: 14))
                }
                
                // Work/Personal indicator
                Image(systemName: task.workPersonal == .work ? "briefcase.fill" : "house.fill")
                    .font(.caption)
                    .foregroundColor(task.workPersonal == .work ? .blue : .purple)
                
                // Complete button
                Button(action: {
                    completeTask()
                }) {
                    if isCompleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundColor(task.status == .completed ? .green : .secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isCompleting || task.status == .completed)
                .help(task.status == .completed ? "Task completed" : "Mark as completed")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(task.status == .completed ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .opacity(task.status == .completed ? 0.6 : 1.0)
    }
    
    private func completeTask() {
        guard task.status != .completed else { return }
        
        isCompleting = true
        Task {
            do {
                await viewModel.completeTask(task)
                await MainActor.run {
                    isCompleting = false
                }
            } catch {
                await MainActor.run {
                    isCompleting = false
                    viewModel.errorMessage = "Failed to complete task: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
    
    private func priorityIcon(_ priority: TaskPriority) -> String {
        switch priority {
        case .urgent: return "exclamationmark.triangle.fill"
        case .high: return "arrow.up.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }
    
    private func formatTaskDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today " + displayFormatter.string(from: date).components(separatedBy: " ").last!
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow " + displayFormatter.string(from: date).components(separatedBy: " ").last!
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            displayFormatter.dateFormat = "E h:mm a"
            return displayFormatter.string(from: date)
        } else {
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
    }
}

/// Add content sheet
struct AddContentView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var contentText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add New Content")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextEditor(text: $contentText)
                    .font(.body)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    .frame(minHeight: 200)
                
                Button("Add & Process") {
                    Task {
                        await viewModel.addQuickNote(contentText)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(contentText.isEmpty)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Search view for advanced content search
struct SearchView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var searchQuery = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Advanced Search")
                .font(.title2)
                .fontWeight(.semibold)
            
            TextField("Search across all content...", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        await viewModel.search(query: searchQuery)
                    }
                }
            
            if !viewModel.searchResults.isEmpty {
                List(viewModel.searchResults, id: \.id) { result in
                    VStack(alignment: .leading) {
                        Text("Search results coming soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Enter a search query to find content")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

/// History view for content timeline
struct HistoryView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Processing History & Audit Trail")
                .font(.title2)
                .fontWeight(.semibold)
            
            if viewModel.processingResults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No processing history yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Process some notes to see their history here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(Array(viewModel.processingResults.keys).map { $0.uuidString }.sorted().reversed(), id: \.self) { blobIdString in
                        if let blobId = UUID(uuidString: blobIdString),
                           let result = viewModel.processingResults[blobId],
                           let blob = viewModel.recentBlobs.first(where: { $0.id == blobId }) {
                            HistoryRowView(blob: blob, result: result)
                                .environmentObject(viewModel)
                        }
                    }
                }
            }
            
            // Show current session summary if available
            if let session = viewModel.currentProcessingSession {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Session")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Started: \(formatDate(session.startTime))")
                            Text("Processed: \(session.processedBlobs)/\(session.totalBlobs)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if session.canUndo {
                            Button("Undo Session") {
                                Task {
                                    await viewModel.undoBatchProcessing(session: session)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

/// History row view for individual processing events
struct HistoryRowView: View {
    let blob: Blob
    let result: ProcessingResult
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.paraCategory.icon)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(blob.content.prefix(60) + (blob.content.count > 60 ? "..." : ""))
                        .font(.body)
                        .lineLimit(1)
                    
                    Text("Processed → \(result.paraCategory.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    ConfidenceIndicator(confidence: result.confidence)
                    
                    Text(formatDate(result.processingTimestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Show summary of actions
            if !result.actions.isEmpty {
                HStack(spacing: 12) {
                    ForEach(result.actions.prefix(3)) { action in
                        HStack(spacing: 2) {
                            Image(systemName: action.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(action.success ? .green : .red)
                                .font(.caption2)
                            
                            Text(action.type.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if result.actions.count > 3 {
                        Text("+ \(result.actions.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetails = true
        }
        .sheet(isPresented: $showingDetails) {
            ProcessingDetailsView(blob: blob, result: result)
                .environmentObject(viewModel)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .none
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

/// Processing confirmation dialog for low-confidence results
struct ProcessingConfirmationView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    
    var body: some View {
        NavigationView {
            ProcessingConfirmationContent(
                viewModel: viewModel,
                currentIndex: $currentIndex,
                dismiss: dismiss
            )
        }
        .frame(minWidth: 900, minHeight: 800)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Skip All") {
                    Task {
                        for result in viewModel.pendingConfirmations {
                            await viewModel.confirmProcessing(for: result, approved: false)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProcessingConfirmationContent: View {
    let viewModel: MainViewModel
    @Binding var currentIndex: Int
    let dismiss: DismissAction
    
    var body: some View {
            if !viewModel.pendingConfirmations.isEmpty && currentIndex < viewModel.pendingConfirmations.count {
                let result = viewModel.pendingConfirmations[currentIndex]
            ProcessingConfirmationDetail(
                result: result,
                currentIndex: currentIndex,
                totalCount: viewModel.pendingConfirmations.count,
                viewModel: viewModel,
                onNext: { moveToNext() },
                onDismiss: { dismiss() }
            )
        } else {
            ProcessingConfirmationEmpty(onDismiss: { dismiss() })
        }
    }
    
    private func moveToNext() {
        if currentIndex < viewModel.pendingConfirmations.count - 1 {
            currentIndex += 1
        } else {
            dismiss()
        }
    }
}

struct ProcessingConfirmationDetail: View {
    let result: ProcessingResult
    let currentIndex: Int
    let totalCount: Int
    let viewModel: MainViewModel
    let onNext: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
                VStack(spacing: 0) {
            ProcessingConfirmationHeader(
                currentIndex: currentIndex,
                totalCount: totalCount
            )
            
            ScrollView {
                ProcessingConfirmationBody(
                    result: result,
                    viewModel: viewModel
                )
            }
            
            ProcessingConfirmationFooter(
                result: result,
                currentIndex: currentIndex,
                totalCount: totalCount,
                viewModel: viewModel,
                onNext: onNext,
                onDismiss: onDismiss
            )
        }
    }
}

struct ProcessingConfirmationHeader: View {
    let currentIndex: Int
    let totalCount: Int
    
    var body: some View {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Review AI Processing")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                Text("\(currentIndex + 1) of \(totalCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        Divider()
                    }
                    .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ProcessingConfirmationBody: View {
    let result: ProcessingResult
    let viewModel: MainViewModel
    
    var body: some View {
                        VStack(spacing: 24) {
                            if let blob = viewModel.recentBlobs.first(where: { $0.id == result.blobId }) {
                ProcessingOriginalNote(blob: blob)
            }
            
            ProcessingAIAnalysis(result: result)
            
            Rectangle()
                .fill(Color.clear)
                .frame(height: 100)
        }
        .padding(.top, 24)
    }
}

struct ProcessingOriginalNote: View {
    let blob: Blob
    
    var body: some View {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Original Note")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    
                                    Text(blob.content)
                                        .font(.body)
                                        .padding(16)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(NSColor.controlBackgroundColor))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal, 24)
    }
                            }
                            
struct ProcessingAIAnalysis: View {
    let result: ProcessingResult
    
    var body: some View {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Text("AI Analysis Results")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
            ProcessingCategoryInfo(result: result)
            ProcessingTasksInfo(result: result)
            ProcessingTagsInfo(result: result)
            
            if let summary = result.summary, !summary.isEmpty {
                ProcessingSummaryInfo(summary: summary)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }
}

struct ProcessingCategoryInfo: View {
    let result: ProcessingResult
    
    var body: some View {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 16) {
                                        Image(systemName: result.paraCategory.icon)
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                            .frame(width: 32)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Category: \(result.paraCategory.displayName)")
                                                .font(.body)
                                                .fontWeight(.medium)
                                            
                                            if let area = result.suggestedArea {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "square.stack.3d.up")
                                                        .foregroundColor(.green)
                                                        .font(.caption)
                                                    Text("Area: \(area)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            if let project = result.suggestedProject {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "target")
                                                        .foregroundColor(.orange)
                                                        .font(.caption)
                                                    Text("Project: \(project)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            ConfidenceIndicator(confidence: result.confidence)
                                            Text("Confidence")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                }
            }
        }
                                        }
                                    }
                                    
struct ProcessingTasksInfo: View {
    let result: ProcessingResult
    
    var body: some View {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Extracted Tasks")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                            
                                            Text("\(result.extractedTasks.count) task\(result.extractedTasks.count == 1 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if !result.extractedTasks.isEmpty {
                                            VStack(spacing: 10) {
                                                ForEach(result.extractedTasks.prefix(5)) { task in
                        ProcessingTaskRow(task: task)
                    }
                    
                    if result.extractedTasks.count > 5 {
                        Text("+ \(result.extractedTasks.count - 5) more tasks will be created")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                    }
                }
            } else {
                Text("No tasks detected in this note")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
            }
        }
    }
}

struct ProcessingTaskRow: View {
    let task: TaskExtractionInfo
    
    var body: some View {
                                                    HStack(alignment: .top, spacing: 12) {
                                                        Circle()
                                                            .fill(priorityColor(task.priority))
                                                            .frame(width: 10, height: 10)
                                                            .padding(.top, 6)
                                                        
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(task.title)
                                                                .font(.body)
                                                                .multilineTextAlignment(.leading)
                                                            
                                                            if let description = task.description, !description.isEmpty {
                                                                Text(description)
                                                                    .font(.caption)
                                                                    .foregroundColor(.secondary)
                                                                    .multilineTextAlignment(.leading)
                                                            }
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Text(task.priority.displayName)
                                                            .font(.caption)
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 4)
                                                            .background(priorityColor(task.priority).opacity(0.2))
                                                            .foregroundColor(priorityColor(task.priority))
                                                            .cornerRadius(4)
                                                    }
                                                    .padding(.vertical, 2)
                                                }
                                                
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
                                                }
                                            }
}

struct ProcessingTagsInfo: View {
    let result: ProcessingResult
    
    var body: some View {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Suggested Tags")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                            
                                            Text("\(result.autoTags.count) tag\(result.autoTags.count == 1 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if !result.autoTags.isEmpty {
                                            LazyVGrid(columns: [
                                                GridItem(.adaptive(minimum: 70, maximum: 140))
                                            ], alignment: .leading, spacing: 8) {
                                                ForEach(result.autoTags.prefix(12), id: \.self) { tag in
                                                    Text(tag)
                                                        .font(.caption)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(Color.blue.opacity(0.2))
                                                        .foregroundColor(.blue)
                                                        .cornerRadius(6)
                                                        .fixedSize()
                                                }
                                            }
                                            
                                            if result.autoTags.count > 12 {
                                                Text("+ \(result.autoTags.count - 12) more tags will be applied")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 12)
                                            }
                                        } else {
                                            Text("No tags suggested for this note")
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 12)
                                        }
        }
    }
}

struct ProcessingSummaryInfo: View {
    let summary: String
    
    var body: some View {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("AI Summary")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Text(summary)
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

struct ProcessingConfirmationFooter: View {
    let result: ProcessingResult
    let currentIndex: Int
    let totalCount: Int
    let viewModel: MainViewModel
    let onNext: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 16) {
                            Button("Skip This Note") {
                                Task {
                                    await viewModel.confirmProcessing(for: result, approved: false)
                                    onNext()
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Approve & Process") {
                                Task {
                                    await viewModel.confirmProcessing(for: result, approved: true)
                                    onNext()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                if totalCount > 1 {
                    if currentIndex < totalCount - 1 {
                                    Button("Next →") {
                            onNext()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                    .background(Color(NSColor.windowBackgroundColor))
                }
}

struct ProcessingConfirmationEmpty: View {
    let onDismiss: () -> Void
    
    var body: some View {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("All items reviewed!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("Close") {
                onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
    }
}

/// Processing summary view showing results of batch processing
struct ProcessingSummaryView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Processing Complete!")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 30)
                .padding(.horizontal, 20)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        if let session = viewModel.currentProcessingSession {
                            // Summary statistics
                            LazyVGrid(columns: [
                                GridItem(.flexible(minimum: 120, maximum: 200)),
                                GridItem(.flexible(minimum: 120, maximum: 200))
                            ], spacing: 16) {
                                StatCard(title: "Notes Processed", value: "\(session.summary.totalProcessed)", icon: "doc.text", color: .blue)
                                StatCard(title: "Tasks Created", value: "\(session.summary.tasksCreated)", icon: "checkmark.square", color: .green)
                                StatCard(title: "Tags Applied", value: "\(session.summary.tagsApplied)", icon: "tag", color: .purple)
                                StatCard(title: "Cross-Links", value: "\(session.summary.crossLinksCreated)", icon: "link", color: .orange)
                            }
                            .padding(.horizontal, 20)
                            
                            // PARA breakdown
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PARA Distribution")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                PARABreakdownView(summary: session.summary)
                            }
                            .padding(20)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            
                            // Error handling
                            if session.summary.errors > 0 {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Processing Errors")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("\(session.summary.errors) notes had processing errors")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            }
                            
                            // Add bottom padding for fixed buttons
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 100)
                        }
                    }
                    .padding(.top, 20)
                }
                
                // Fixed bottom action buttons
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 16) {
                        if let session = viewModel.currentProcessingSession, session.canUndo {
                            Button("Undo All Changes") {
                                Task {
                                    await viewModel.undoBatchProcessing(session: session)
                                    dismiss()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        Button("Done") {
                            viewModel.currentProcessingSession = nil
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.currentProcessingSession = nil
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

/// Confidence indicator component
struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .fontWeight(.medium)
            
            Rectangle()
                .fill(confidenceColor)
                .frame(width: 30, height: 4)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 4)
                        .overlay(
                            Rectangle()
                                .fill(confidenceColor)
                                .frame(width: 30 * confidence, height: 4),
                            alignment: .leading
                        )
                )
        }
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

/// Statistics card component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

/// PARA breakdown visualization
struct PARABreakdownView: View {
    let summary: BatchProcessingSummary
    
    var body: some View {
        VStack(spacing: 8) {
            BreakdownRow(label: "Projects", count: summary.notesFiledAsProjects, icon: "target", color: .blue)
            BreakdownRow(label: "Areas", count: summary.notesFiledAsAreas, icon: "square.stack.3d.up", color: .green)
            BreakdownRow(label: "Resources", count: summary.notesFiledAsResources, icon: "books.vertical", color: .purple)
            BreakdownRow(label: "Archives", count: summary.notesArchived, icon: "archivebox", color: .gray)
        }
    }
}

struct BreakdownRow: View {
    let label: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text("\(count)")
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

/// Toast notification view
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    enum ToastType {
        case success, error, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .foregroundColor(.white)
                .font(.caption)
            
            Text(message)
                .foregroundColor(.white)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(type.color)
        .cornerRadius(6)
        .shadow(radius: 2)
        .padding(.horizontal, 20)
        .onAppear {
            // Auto-dismiss after 5 seconds (reduced from 10)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                onDismiss()
            }
        }
    }
}

/// Quick stat display component
struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// AI Transparency view showing what AI did and why
struct AITransparencyView: View {
    let blob: Blob
    let project: Project?
    let area: Area?
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(blob: Blob, project: Project? = nil, area: Area? = nil) {
        self.blob = blob
        self.project = project
        self.area = area
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                AITransparencyContent(
                    blob: blob,
                    project: project,
                    area: area,
                    dismiss: dismiss
                )
            }
            .navigationTitle("AI Processing Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct AITransparencyContent: View {
    let blob: Blob
    let project: Project?
    let area: Area?
    let dismiss: DismissAction
    
    var body: some View {
                VStack(alignment: .leading, spacing: 20) {
            AITransparencyOriginalNote(blob: blob)
            AITransparencyAnalysis(blob: blob, project: project, area: area)
            AITransparencyMetadata(blob: blob)
            AITransparencyActions(dismiss: dismiss)
        }
        .padding()
    }
}

struct AITransparencyOriginalNote: View {
    let blob: Blob
    
    var body: some View {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Original Note")
                            .font(.headline)
                        
                        Text(blob.content)
                            .padding()
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
    }
}

struct AITransparencyAnalysis: View {
    let blob: Blob
    let project: Project?
    let area: Area?
    
    var body: some View {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain")
                                .foregroundColor(.blue)
                            Text("AI Analysis")
                                .font(.headline)
                        }
                        
                        if let project = project {
                AITransparencyProjectAssignment(blob: blob, project: project)
            }
            
            if let area = area {
                AITransparencyAreaAssignment(blob: blob, area: area)
            }
        }
    }
}

struct AITransparencyProjectAssignment: View {
    let blob: Blob
    let project: Project
    
    var body: some View {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Assigned to Project: **\(project.name)**")
                                
                                if let description = project.description {
                                    Text("Project Description: \(description)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("**Why this assignment:**")
                                    .font(.subheadline)
                                    .padding(.top, 8)
                                
                                Text("• Content mentions actionable items related to \(project.name.lowercased())")
                                Text("• Timeline and deliverables suggest project-based work")
                                Text("• Keywords match project scope and objectives")
                                
                                if blob.workPersonal == .work {
                                    Text("• Classified as work-related content")
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
}

struct AITransparencyAreaAssignment: View {
    let blob: Blob
    let area: Area
    
    var body: some View {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Assigned to Area: **\(area.name)**")
                                
                                if let description = area.description {
                                    Text("Area Description: \(description)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("**Why this assignment:**")
                                    .font(.subheadline)
                                    .padding(.top, 8)
                                
                                Text("• Content relates to ongoing responsibilities in \(area.name.lowercased())")
                                Text("• No specific project timeline identified")
                                Text("• Maintenance or improvement-focused content")
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
struct AITransparencyMetadata: View {
    let blob: Blob
    
    var body: some View {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Processing Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Source:")
                                Spacer()
                                Text(blob.sourceType.rawValue.capitalized)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Category:")
                                Spacer()
                                Text(blob.workPersonal.rawValue.capitalized)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Processed:")
                                Spacer()
                    Text(formatRelativeDate(blob.createdAt))
                                    .foregroundColor(.secondary)
                            }
                            
                            if blob.processed {
                                HStack {
                                    Text("Status:")
                                    Spacer()
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Processed")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
        }
    }
                    }
                    
struct AITransparencyActions: View {
    let dismiss: DismissAction
    
    var body: some View {
                    VStack(spacing: 12) {
                        Text("Don't agree with this assignment?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Button("Move to Different Project") {
                                // TODO: Implement reassignment
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Move to Area") {
                                // TODO: Implement reassignment
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Move to Resources") {
                                // TODO: Implement reassignment
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top)
    }
}

// MARK: - Helper Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Helper function for formatting relative dates
func formatRelativeDate(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: dateString) {
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
    return dateString
}

// MARK: - New Feature Views (Stubs)

/// Tags view for managing and visualizing tags
struct TagsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tags")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Image(systemName: "tag")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Tag Management")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("View and organize all tags across your content. Coming soon!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .padding()
    }
}

/// Mind map view for visual content organization
struct MindmapView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Mind Map")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Visual Organization")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Explore your content connections in a visual mind map format. Coming soon!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .padding()
    }
}



/// Timeline view for chronological content organization







/// Unscheduled tasks sidebar
struct UnscheduledTasksSidebar: View {
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Unscheduled Tasks")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(calendarViewModel.filteredUnscheduledTasks.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                
                // Auto-schedule button
                if !calendarViewModel.filteredUnscheduledTasks.isEmpty {
                    Button(action: {
                        Task {
                            await calendarViewModel.autoScheduleUnscheduledTasks()
                        }
                    }) {
                        HStack {
                            Image(systemName: "brain.filled.head.profile")
                                .foregroundColor(.white)
                            Text("Auto-Schedule All")
                    .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(calendarViewModel.isLoading)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Elegant divider
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.1), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
            
            // Enhanced Tasks list
            if calendarViewModel.filteredUnscheduledTasks.isEmpty {
                // Enhanced empty state
                VStack(spacing: 20) {
                    // Animated checkmark
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.green.opacity(0.2), .green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .shadow(color: .green.opacity(0.2), radius: 10, x: 0, y: 4)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    VStack(spacing: 8) {
                        Text("All tasks scheduled!")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Great job staying organized.\nAll your tasks have been assigned to time slots.")
                            .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    
                    // Subtle action hint
                    VStack(spacing: 8) {
                        Text("Next steps:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Label("Add new tasks", systemImage: "plus.circle")
                            Label("Review schedule", systemImage: "calendar")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))
                    }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(calendarViewModel.filteredUnscheduledTasks) { task in
                            UnscheduledTaskRow(task: task)
                                .environmentObject(calendarViewModel)
                                .transition(.asymmetric(
                                    insertion: .slide.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(16)
                }
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// Individual unscheduled task row with enhanced drag support
struct UnscheduledTaskRow: View {
    let task: LifeTask
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            taskHeader
            
            if !suggestedTimes.isEmpty {
                suggestedTimesSection
            }
        }
        .padding(16)
        .background(taskBackgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(isDragging ? 0.2 : (isHovered ? 0.1 : 0.05)), 
                radius: isDragging ? 8 : (isHovered ? 4 : 2), 
                x: 0, 
                y: isDragging ? 4 : (isHovered ? 2 : 1))
        .scaleEffect(isDragging ? 0.95 : (isHovered ? 1.02 : 1.0))
        .rotationEffect(.degrees(isDragging ? 2 : 0))
        .offset(dragOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .gesture(dragGesture)
    }
    
    private var taskHeader: some View {
        HStack(spacing: 12) {
            priorityIndicator
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            taskMetadata
        }
    }
    
    private var priorityIndicator: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [priorityColor(task.priority), priorityColor(task.priority).opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 16, height: 16)
                .shadow(color: priorityColor(task.priority).opacity(0.4), radius: 2, x: 0, y: 1)
            
            Circle()
                .fill(priorityColor(task.priority))
                .frame(width: 8, height: 8)
        }
    }
    
    private var taskMetadata: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if let duration = task.estimatedDuration {
                Text("\(duration)min")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.blue.gradient))
                    .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            workPersonalIndicator
        }
    }
    
    private var workPersonalIndicator: some View {
        ZStack {
            Circle()
                .fill(task.workPersonal == .work ? 
                      LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                      LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            Image(systemName: task.workPersonal == .work ? "briefcase.fill" : "house.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var suggestedTimesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            suggestedTimesHeader
            suggestedTimesButtons
        }
    }
    
    private var suggestedTimesHeader: some View {
            Text("Suggested times:")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
    }
            
    private var suggestedTimesButtons: some View {
            HStack(spacing: 8) {
                ForEach(suggestedTimes.prefix(2), id: \.self) { time in
                suggestedTimeButton(for: time)
            }
            
            Spacer()
            
            dragIndicator
        }
    }
    
    private func suggestedTimeButton(for time: Date) -> some View {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            // Schedule this for the next run loop to avoid Task conflict
                            DispatchQueue.main.async {
                                Task.detached(priority: .background) {
                                    await calendarViewModel.scheduleTask(task, at: time)
                                }
                            }
                        }
                    }) {
                        Text(time.calendarSuggestionFormat())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
                
    private var dragIndicator: some View {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.6))
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isDragging = true
                    }
                    calendarViewModel.startDragging(task)
                    hapticFeedback()
                }
                dragOffset = value.translation
                calendarViewModel.updateDragPosition(value.translation)
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isDragging = false
                    dragOffset = .zero
                }
                calendarViewModel.cancelDrag()
                hapticFeedback()
            }
    }
    
    private var taskBackgroundColor: Color {
        if isDragging {
            return Color(NSColor.controlAccentColor).opacity(0.2)
        } else if isHovered {
            return Color(NSColor.controlBackgroundColor).opacity(0.8)
        } else {
            return Color(NSColor.controlBackgroundColor).opacity(0.6)
        }
    }
    
    private var suggestedTimes: [Date] {
        calendarViewModel.suggestedSlots(for: task)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
    
    private func hapticFeedback() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }
}

// MARK: - Additional Calendar Components





/// Enhanced filter chip component
struct FilterChip: View {
    let title: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, color: Color = .blue, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white : color)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(chipBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.05), radius: isSelected ? 3 : 1, x: 0, y: isSelected ? 2 : 1)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var chipBackground: some View {
        Group {
            if isSelected {
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(NSColor.controlBackgroundColor)
            }
        }
    }
}

/// Create event view (placeholder)
struct CreateEventView: View {
    let calendarViewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Create Event")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Event creation coming soon!")
                .foregroundColor(.secondary)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

/// Task details view (placeholder)
struct TaskDetailsView: View {
    let task: LifeTask
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Task Details")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(task.title)
                .font(.headline)
            
            if let description = task.description {
                Text(description)
                    .foregroundColor(.secondary)
            }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

/// Timeline view for chronological content organization
struct TimelineView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Timeline")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Image(systemName: "timeline.selection")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Chronological View")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("See your content evolution over time in a timeline format. Coming soon!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .padding()
    }
}

/// Expandable resource category section
struct ResourceCategorySection: View {
    let category: String
    let blobs: [Blob]
    @EnvironmentObject var viewModel: MainViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                LazyVStack(spacing: 8) {
                    ForEach(blobs) { blob in
                        ResourceBlobRowView(blob: blob)
                            .environmentObject(viewModel)
                    }
                }
                .padding(.top, 8)
            },
            label: {
                HStack {
                    Image(systemName: categoryIcon(category))
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category)
                            .font(.headline)
                        
                        Text("\(blobs.count) AI-organized references")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // AI indicator
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("AI")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        )
        .padding(.horizontal)
    }
    
    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Research Papers": return "doc.text.magnifyingglass"
        case "Articles": return "newspaper"
        case "Videos": return "play.rectangle"
        case "Books": return "book.closed"
        case "Guides": return "map"
        case "Recipes": return "fork.knife"
        case "Insights": return "lightbulb"
        case "References": return "link"
        default: return "doc.text"
        }
    }
}

/// Resource blob row view for AI-organized references
struct ResourceBlobRowView: View {
    let blob: Blob
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingAIDetails = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Resource type icon
            Image(systemName: "doc.text")
                .foregroundColor(.purple)
                .font(.title2)
                .frame(width: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(blob.content)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    // Source type
                    Label(blob.sourceType.rawValue.capitalized, systemImage: sourceTypeIcon(blob.sourceType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Work/Personal
                    Text(blob.workPersonal.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(blob.workPersonal == .work ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        .foregroundColor(blob.workPersonal == .work ? .blue : .green)
                        .cornerRadius(4)
                    
                    // AI assignment indicator
                    Button(action: {
                        showingAIDetails = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "brain")
                            Text("AI categorized")
                        }
                        .font(.caption)
                        .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                    .help("See why AI categorized this as a resource")
                    
                    Spacer()
                    
                    // Timestamp
                    Text(formatRelativeDate(blob.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .sheet(isPresented: $showingAIDetails) {
            AITransparencyView(blob: blob)
                .environmentObject(viewModel)
        }
    }
    
    private func sourceTypeIcon(_ sourceType: SourceType) -> String {
        switch sourceType {
        case .note: return "note.text"
        case .journal: return "book"
        case .email: return "envelope"
        case .meeting: return "person.2"
        case .idea: return "lightbulb"
        case .research: return "magnifyingglass"
        case .recipe: return "fork.knife"
        case .financial: return "dollarsign.circle"
        case .inventory: return "list.clipboard"
        case .knowledge: return "brain"
        case .therapy: return "heart"
        case .media: return "play.rectangle"
        case .grocery: return "cart"
        default: return "doc.text"
        }
    }
}

/// Expandable archive category section
struct ArchiveCategorySection: View {
    let category: String
    let blobs: [Blob]
    let tasks: [LifeTask]
    @EnvironmentObject var viewModel: MainViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                LazyVStack(spacing: 8) {
                    // Show recently deleted tasks first (if category is Recently Deleted)
                    ForEach(tasks) { task in
                        if category == "Recently Deleted" {
                            RecentlyDeletedTaskRowView(task: task)
                                .environmentObject(viewModel)
                        } else {
                        CompletedTaskRowView(task: task)
                            .environmentObject(viewModel)
                        }
                    }
                    
                    // Then show archived blobs
                    ForEach(blobs) { blob in
                        ArchiveBlobRowView(blob: blob)
                            .environmentObject(viewModel)
                    }
                }
                .padding(.top, 8)
            },
            label: {
                HStack {
                    Image(systemName: categoryIcon(category))
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category)
                            .font(.headline)
                        
                        Text("\(tasks.count + blobs.count) items" + (tasks.count > 0 ? " (\(tasks.count) tasks, \(blobs.count) archived)" : ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // AI indicator
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("AI")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        )
        .padding(.horizontal)
    }
    
    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Completed Projects": return "checkmark.circle"
        case "Inactive Areas": return "pause.circle"
        case "Old Resources": return "clock.arrow.circlepath"
        case "Past Notes": return "note.text.badge.plus"
        case "Outdated References": return "link.badge.plus"
        case "Historical Data": return "calendar.badge.clock"
        default: return "archivebox"
        }
    }
}

/// Archive blob row view for AI-archived content
struct ArchiveBlobRowView: View {
    let blob: Blob
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingAIDetails = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Archive type icon
            Image(systemName: "archivebox")
                .foregroundColor(.gray)
                .font(.title2)
                .frame(width: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(blob.content)
                    .font(.body)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary) // Muted for archived content
                
                HStack(spacing: 8) {
                    // Source type
                    Label(blob.sourceType.rawValue.capitalized, systemImage: sourceTypeIcon(blob.sourceType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Work/Personal
                    Text(blob.workPersonal.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.secondary)
                        .cornerRadius(4)
                    
                    // AI assignment indicator
                    Button(action: {
                        showingAIDetails = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "brain")
                            Text("AI archived")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .help("See why AI archived this content")
                    
                    Spacer()
                    
                    // Timestamp
                    Text(formatRelativeDate(blob.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Restore button
            Button(action: {
                Task {
                    await viewModel.restoreBlobFromArchive(blob)
                }
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .help("Restore from archive")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .sheet(isPresented: $showingAIDetails) {
            AITransparencyView(blob: blob)
                .environmentObject(viewModel)
        }
    }
    
    private func sourceTypeIcon(_ sourceType: SourceType) -> String {
        switch sourceType {
        case .note: return "note.text"
        case .journal: return "book"
        case .email: return "envelope"
        case .meeting: return "person.2"
        case .idea: return "lightbulb"
        case .research: return "magnifyingglass"
        case .recipe: return "fork.knife"
        case .financial: return "dollarsign.circle"
        case .inventory: return "list.clipboard"
        case .knowledge: return "brain"
        case .therapy: return "heart"
        case .media: return "play.rectangle"
        case .grocery: return "cart"
        default: return "doc.text"
        }
    }
}

/// Completed task row view for archive display
struct CompletedTaskRowView: View {
    let task: LifeTask
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingTaskDetails = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Completed task icon
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
                .frame(width: 32)
            
            // Task content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .strikethrough(true) // Show as completed
                    
                    Spacer()
                    
                    // Completion date
                    if let completedAt = task.completedAt {
                        let formatter = ISO8601DateFormatter()
                        if let completedDate = formatter.date(from: completedAt) {
                            Text("Completed \(completedDate.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Task metadata
                HStack(spacing: 12) {
                    // Priority
                    HStack(spacing: 4) {
                        Circle()
                            .fill(priorityColor(task.priority))
                            .frame(width: 8, height: 8)
                        Text(task.priority.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Work/Personal
                    HStack(spacing: 4) {
                        Image(systemName: task.workPersonal == .work ? "briefcase.fill" : "house.fill")
                        Text(task.workPersonal.displayName)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Duration if available
                    if let duration = task.estimatedDuration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("\(duration)m")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Actions menu
            Menu {
                Button(action: {
                    Task {
                        await restoreTask()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Restore Task")
                    }
                }
                
                Button(role: .destructive, action: {
                    Task {
                        await deleteCompletedTask()
                    }
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Permanently")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
        .contextMenu {
            Button("View Details") {
                showingTaskDetails = true
            }
            
            Button("Restore Task") {
                Task {
                    await restoreTask()
                }
            }
            
            Button(role: .destructive) {
                Task {
                    await deleteCompletedTask()
                }
            } label: {
                Text("Delete Permanently")
            }
        }
        .sheet(isPresented: $showingTaskDetails) {
            TaskDetailsView(task: task)
                .environmentObject(viewModel)
        }
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
    
    private func restoreTask() async {
        do {
            let taskRepository = TaskRepository()
            let restoredTask = LifeTask(
                id: task.id,
                blobId: task.blobId,
                title: task.title,
                description: task.description,
                priority: task.priority,
                status: .todo, // Restore as todo
                dueDate: task.dueDate,
                estimatedDuration: task.estimatedDuration,
                workPersonal: task.workPersonal,
                projectId: task.projectId,
                areaId: task.areaId,
                resourceId: task.resourceId,
                isFocus: task.isFocus,
                isArchived: task.isArchived,
                createdAt: task.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                completedAt: nil, // Clear completion date
                archivedAt: task.archivedAt
            )
            
            _ = try await taskRepository.updateTask(restoredTask)
            
            await MainActor.run {
                viewModel.successMessage = "Task '\(task.title)' restored to active tasks"
            }
            
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Failed to restore task: \(error.localizedDescription)"
            }
        }
    }
    
    private func deleteCompletedTask() async {
        do {
            let taskRepository = TaskRepository()
            try await taskRepository.deleteTask(id: task.id)
            
            // Also delete associated blob if exists
            if let blobId = task.blobId {
                let blobRepository = BlobRepository()
                try await blobRepository.deleteBlob(id: blobId)
            }
            
            await MainActor.run {
                viewModel.successMessage = "Task permanently deleted"
            }
            
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Failed to delete task: \(error.localizedDescription)"
            }
        }
    }
}

/// Personal mode view showing all personal content
struct PersonalView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var personalBlobs: [Blob] = []
    @State private var personalTasks: [LifeTask] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            VStack(spacing: 16) {
                HStack {
                    Text("Personal")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Stats
                    if !personalBlobs.isEmpty || !personalTasks.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "person")
                                .foregroundColor(.green)
                            
                            Text("\(personalBlobs.count) notes • \(personalTasks.count) tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Quick stats
                HStack(spacing: 20) {
                    StatView(
                        title: "Personal Notes", 
                        value: "\(personalBlobs.count)",
                        color: .green
                    )
                    StatView(
                        title: "Personal Tasks", 
                        value: "\(personalTasks.count)",
                        color: .blue
                    )
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor))
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Personal Tasks
                    if !personalTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.blue)
                                Text("Personal Tasks")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(personalTasks) { task in
                                TaskRowView(task: task)
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    
                    // Personal Notes
                    if !personalBlobs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.green)
                                Text("Personal Notes")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(personalBlobs) { blob in
                                BlobRowView(blob: blob)
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    
                    // Empty state
                    if personalBlobs.isEmpty && personalTasks.isEmpty {
                        if #available(macOS 14.0, *) {
                            ContentUnavailableView(
                                "No personal content yet",
                                systemImage: "person",
                                description: Text("Add some personal notes or tasks")
                            )
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "person")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No personal content yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Add some personal notes or tasks")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                await loadPersonalContent()
            }
        }
    }
    
    private func loadPersonalContent() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let blobsTask = BlobRepository().fetchBlobs(workPersonal: .personal)
            async let tasksTask = TaskRepository().fetchTasks(workPersonal: .personal)
            
            let (blobs, tasks) = try await (blobsTask, tasksTask)
            
            await MainActor.run {
                self.personalBlobs = blobs
                self.personalTasks = tasks
            }
        } catch {
            Logger.shared.debug("Error loading personal content: \(error)")
        }
    }
}

/// Work mode view showing all work content
struct WorkView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var workBlobs: [Blob] = []
    @State private var workTasks: [LifeTask] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            VStack(spacing: 16) {
                HStack {
                    Text("Work")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Stats
                    if !workBlobs.isEmpty || !workTasks.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "briefcase")
                                .foregroundColor(.blue)
                            
                            Text("\(workBlobs.count) notes • \(workTasks.count) tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Quick stats
                HStack(spacing: 20) {
                    StatView(
                        title: "Work Notes", 
                        value: "\(workBlobs.count)",
                        color: .blue
                    )
                    StatView(
                        title: "Work Tasks", 
                        value: "\(workTasks.count)",
                        color: .purple
                    )
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(NSColor.controlBackgroundColor))
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Work Tasks
                    if !workTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.purple)
                                Text("Work Tasks")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(workTasks) { task in
                                TaskRowView(task: task)
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    
                    // Work Notes
                    if !workBlobs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.blue)
                                Text("Work Notes")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            ForEach(workBlobs) { blob in
                                BlobRowView(blob: blob)
                                    .environmentObject(viewModel)
                            }
                        }
                    }
                    
                    // Empty state
                    if workBlobs.isEmpty && workTasks.isEmpty {
                        if #available(macOS 14.0, *) {
                            ContentUnavailableView(
                                "No work content yet",
                                systemImage: "briefcase",
                                description: Text("Add some work notes or tasks")
                            )
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "briefcase")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No work content yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Add some work notes or tasks")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            Task {
                await loadWorkContent()
            }
        }
    }
    
    private func loadWorkContent() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let blobsTask = BlobRepository().fetchBlobs(workPersonal: .work)
            async let tasksTask = TaskRepository().fetchTasks(workPersonal: .work)
            
            let (blobs, tasks) = try await (blobsTask, tasksTask)
            
            await MainActor.run {
                self.workBlobs = blobs
                self.workTasks = tasks
            }
        } catch {
            Logger.shared.debug("Error loading work content: \(error)")
        }
    }
}

/// Edit event sheet
struct EditEventSheet: View {
    let event: CalendarEvent
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var startDate: Date
    @State private var duration: Int
    @State private var priority: TaskPriority
    @State private var workPersonal: WorkPersonalType
    
    init(event: CalendarEvent) {
        self.event = event
        self._title = State(initialValue: event.title)
        self._description = State(initialValue: event.description ?? "")
        self._startDate = State(initialValue: event.startDate)
        self._duration = State(initialValue: Int(event.duration / 60))
        self._priority = State(initialValue: event.priority)
        self._workPersonal = State(initialValue: event.workPersonal)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Scheduling") {
                    DatePicker("Start Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Picker("Duration", selection: $duration) {
                            ForEach([15, 30, 45, 60, 90, 120, 180, 240], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("Properties") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    
                    Picker("Type", selection: $workPersonal) {
                        Text("Work").tag(WorkPersonalType.work)
                        Text("Personal").tag(WorkPersonalType.personal)
                        Text("Both").tag(WorkPersonalType.both)
                    }
                }
            }
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private func saveChanges() async {
        guard let taskId = event.taskId else {
            dismiss()
            return
        }
        
        do {
            let taskRepository = TaskRepository()
            
            // Get the current task
            guard let currentTask = try await taskRepository.fetchTask(id: taskId) else {
                throw SupabaseError.notFound
            }
            
            // Create updated task
            let updatedTask = LifeTask(
                id: currentTask.id,
                blobId: currentTask.blobId,
                title: title,
                description: description.isEmpty ? nil : description,
                priority: priority,
                status: currentTask.status,
                dueDate: ISO8601DateFormatter().string(from: startDate),
                estimatedDuration: duration,
                workPersonal: workPersonal,
                projectId: currentTask.projectId,
                areaId: currentTask.areaId,
                resourceId: currentTask.resourceId,
                isFocus: currentTask.isFocus,
                isArchived: currentTask.isArchived,
                createdAt: currentTask.createdAt,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                completedAt: currentTask.completedAt,
                archivedAt: currentTask.archivedAt
            )
            
            _ = try await taskRepository.updateTask(updatedTask)
            
            // Refresh calendar
            await calendarViewModel.loadCalendarData()
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                calendarViewModel.errorMessage = "Failed to update event: \(error.localizedDescription)"
                dismiss()
            }
        }
    }
}

/// Reschedule event sheet
struct RescheduleEventSheet: View {
    let event: CalendarEvent
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newStartDate: Date
    @State private var suggestedSlots: [Date] = []
    
    init(event: CalendarEvent) {
        self.event = event
        self._newStartDate = State(initialValue: event.startDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reschedule: \(event.title)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    DatePicker("New Time", selection: $newStartDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                }
                .padding()
                
                if !suggestedSlots.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested Times")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(suggestedSlots.prefix(6), id: \.self) { slot in
                                Button(action: {
                                    newStartDate = slot
                                }) {
                                    Text(slot.calendarSuggestionFormat())
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Reschedule Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reschedule") {
                        Task {
                            await rescheduleEvent()
                        }
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
        .onAppear {
            loadSuggestedSlots()
        }
    }
    
    private func loadSuggestedSlots() {
        // Generate suggested slots based on working hours and availability
        let calendar = Calendar.current
        let today = Date()
        
        var slots: [Date] = []
        
        // Generate slots for next 7 days
        for day in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: day, to: today) else { continue }
            
            // Working hours: 9 AM to 5 PM
            for hour in 9...17 {
                guard let slot = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) else { continue }
                
                // Skip past times
                if slot > Date() {
                    slots.append(slot)
                }
            }
        }
        
        // Filter out conflicting times
        let availableSlots = slots.filter { slot in
            let endTime = slot.addingTimeInterval(TimeInterval(event.duration * 60))
            return !calendarViewModel.events.contains { existingEvent in
                existingEvent.id != event.id &&
                existingEvent.startDate < endTime &&
                existingEvent.endDate > slot
            }
        }
        
        suggestedSlots = Array(availableSlots.prefix(10))
    }
    
    private func rescheduleEvent() async {
        await calendarViewModel.rescheduleEvent(event, to: newStartDate)
        await MainActor.run {
            dismiss()
        }
    }
}

/// Recently deleted task row with restore/permanent delete options
struct RecentlyDeletedTaskRowView: View {
    let task: LifeTask
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Deleted status indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.red.opacity(0.6))
                    .frame(width: 12, height: 12)
                
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(true, color: .secondary)
                    .foregroundColor(.secondary)
                
                if let description = task.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    // Priority indicator
                    Text(task.priority.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor(task.priority).opacity(0.2))
                        .foregroundColor(priorityColor(task.priority))
                        .cornerRadius(4)
                    
                    // Deletion time
                    if let deletedAtString = task.deletedAt,
                       let deletedDate = ISO8601DateFormatter().date(from: deletedAtString) {
                        Text("Deleted \(RelativeDateTimeFormatter().localizedString(for: deletedDate, relativeTo: Date()))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Permanent deletion countdown
                    if task.canBePermalentlyDeleted {
                        Text("Ready for permanent deletion")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else {
                        let hoursLeft = hoursUntilPermanentDeletion(task)
                        Text("\(hoursLeft)h left")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 8) {
                Button(action: {
                    Task {
                        await restoreTask()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Restore")
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete")
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(12)
        .background(Color(NSColor.systemGray).opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .alert("Permanently Delete Task", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await permanentlyDeleteTask()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func restoreTask() async {
        do {
            let taskRepository = TaskRepository()
            try await taskRepository.restoreDeletedTask(id: task.id)
            await viewModel.refreshData()
        } catch {
            Logger.shared.debug("Failed to restore task: \(error)")
        }
    }
    
    private func permanentlyDeleteTask() async {
        do {
            let taskRepository = TaskRepository()
            try await taskRepository.permanentlyDeleteTask(id: task.id)
            await viewModel.refreshData()
        } catch {
            Logger.shared.debug("Failed to permanently delete task: \(error)")
        }
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    private func hoursUntilPermanentDeletion(_ task: LifeTask) -> Int {
        guard let deletedAtString = task.deletedAt,
              let deletedAt = ISO8601DateFormatter().date(from: deletedAtString) else {
            return 0
        }
        
        let deleteTime = deletedAt.addingTimeInterval(24 * 60 * 60) // 24 hours later
        let hoursLeft = Int(deleteTime.timeIntervalSinceNow / 3600)
        return max(0, hoursLeft)
    }
}

// MARK: - Filter Toggle Button

struct FilterToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
} 