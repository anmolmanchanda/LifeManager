import SwiftUI
import Foundation
import AppKit

/// Main content view for LifeManager
/// Provides PARA-based navigation and content management
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
        .overlay(alignment: .top) {
            // Success toast
            if let successMessage = viewModel.successMessage {
                ToastView(message: successMessage, type: .success) {
                    viewModel.successMessage = nil
                }
                .padding(.top, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .overlay(alignment: .top) {
            // Error toast (only for critical errors)
            if let errorMessage = viewModel.errorMessage, shouldShowError(errorMessage) {
                ToastView(message: errorMessage, type: .error) {
                viewModel.errorMessage = nil
            }
                .padding(.top, viewModel.successMessage != nil ? 80 : 20)
                .transition(.move(edge: .top).combined(with: .opacity))
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
                    // Toggle sidebar
                }) {
                    Image(systemName: "sidebar.left")
                }
            }
            
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
                    Label("Projects", systemImage: "target")
                }
                .tag(PARAView.projects)
                
                NavigationLink(destination: AreasView().environmentObject(viewModel)) {
                    Label("Areas", systemImage: "square.stack.3d.up")
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
                
                NavigationLink(destination: TagsView().environmentObject(viewModel)) {
                    Label("Tags", systemImage: "tag")
                }
                .tag(PARAView.tags)
                
                NavigationLink(destination: MindmapView().environmentObject(viewModel)) {
                    Label("Mind Map", systemImage: "brain.head.profile")
                }
                .tag(PARAView.mindmap)
                
                NavigationLink(destination: CalendarView().environmentObject(viewModel)) {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(PARAView.calendar)
                
                NavigationLink(destination: TimelineView().environmentObject(viewModel)) {
                    Label("Timeline", systemImage: "timeline.selection")
                }
                .tag(PARAView.timeline)
            }
            
            Section("Search & History") {
                NavigationLink(destination: SearchView().environmentObject(viewModel)) {
                    Label("Search", systemImage: "magnifyingglass")
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
        VStack(spacing: 20) {
            // Natural Language Input Bar
            NaturalLanguageInputView()
                .environmentObject(viewModel)
            
            // Bulk actions toolbar
            if !viewModel.recentBlobs.isEmpty {
                HStack {
                    Text("\(viewModel.recentBlobs.count) notes in inbox")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Show processing stats if available
                    if !viewModel.processingResults.isEmpty {
                        let processedCount = viewModel.recentBlobs.filter { blob in
                            viewModel.getProcessingState(for: blob.id).isProcessed
                        }.count
                        
                        Text("• \(processedCount) processed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Button("🤖 Process All with AI") {
                        Task {
                            await viewModel.processAllUnprocessedBlobs()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                    
                    Button("🔄 Refresh") {
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal)
            }
            
            // Recent unprocessed blobs
            if viewModel.recentBlobs.isEmpty {
                if #available(macOS 14.0, *) {
                ContentUnavailableView(
                    "No recent content",
                    systemImage: "tray",
                        description: Text("Add some content using the input field above")
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No recent content")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Add some content using the input field above")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            } else {
                List(viewModel.recentBlobs) { blob in
                    BlobRowView(blob: blob)
                        .environmentObject(viewModel)
                }
            }
            
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
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
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
            HStack {
                TextField("What's on your mind? (e.g., 'Buy groceries tomorrow', 'Research Swift async/await')", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        submitInput()
                    }
                    .disabled(isProcessing)
                
                Button(isProcessing ? "Processing..." : "Add") {
                    submitInput()
                }
                .disabled(inputText.isEmpty || isProcessing)
                .buttonStyle(.borderedProminent)
            }
            
            if isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Saving and processing with AI...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func submitInput() {
        guard !inputText.isEmpty else { return }
        
        let content = inputText
        
        // Clear input immediately for better UX
        inputText = ""
        isProcessing = true
        
        Task {
            await viewModel.addQuickNote(content)
            
            await MainActor.run {
                isProcessing = false
            }
        }
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
        case .knowledge: return "lightbulb"
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
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 200))
        ], spacing: 20) {
            ForEach(viewModel.areas) { area in
                AreaCardView(area: area)
                    .environmentObject(viewModel)
            }
        }
        .padding()
    }
}

struct AreaCardView: View {
    let area: Area
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let iconName = area.icon {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(Color(hex: area.color))
                }
                
                Spacer()
                
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
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .frame(height: 120)
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

/// Projects view
struct ProjectsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        List(viewModel.projects) { project in
            ProjectRowView(project: project)
                .environmentObject(viewModel)
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(project.name)
                    .font(.headline)
                
                if let description = project.description {
                    Text(description)
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
            .help("Delete this project")
            
            // Status badge
            Text(project.status.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(project.status == .active ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .foregroundColor(project.status == .active ? .green : .gray)
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
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

/// Resources view
struct ResourcesView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Resources")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("+ Add Resource") {
                    // TODO: Add resource creation
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            
            // Resources list
            if viewModel.resources.isEmpty {
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No resources yet",
                        systemImage: "books.vertical",
                        description: Text("Add reference materials, documents, and knowledge items")
                    )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No resources yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Add reference materials, documents, and knowledge items")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                List(viewModel.resources) { resource in
                    ResourceRowView(resource: resource)
                        .environmentObject(viewModel)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Archives")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Inactive items from Projects, Areas, and Resources")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Archives list
            if viewModel.archives.isEmpty {
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
            } else {
                List(viewModel.archives) { archive in
                    ArchiveRowView(archive: archive)
                        .environmentObject(viewModel)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
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
    
    var body: some View {
        HStack {
            // Priority indicator
            Circle()
                .fill(priorityColor(task.priority))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                
                if let description = task.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if task.isFocus {
                Image(systemName: "target")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
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
            if !viewModel.pendingConfirmations.isEmpty && currentIndex < viewModel.pendingConfirmations.count {
                let result = viewModel.pendingConfirmations[currentIndex]
                
                VStack(spacing: 0) {
                    // Fixed header
                    VStack(spacing: 12) {
                        HStack {
                            Text("Review AI Processing")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("\(currentIndex + 1) of \(viewModel.pendingConfirmations.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        Divider()
                    }
                    .background(Color(NSColor.windowBackgroundColor))
                    
                    // Scrollable content area
                    ScrollView {
                        VStack(spacing: 24) {
                            // Original content preview
                            if let blob = viewModel.recentBlobs.first(where: { $0.id == result.blobId }) {
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
                            
                            // AI Analysis results
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Text("AI Analysis Results")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                // Category and confidence
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
                                    
                                    // Extracted tasks section
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
                                    
                                    // Auto tags section
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
                                    
                                    // Summary if available
                                    if let summary = result.summary, !summary.isEmpty {
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
                            }
                            .padding(20)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                            
                            // Bottom spacer for fixed buttons
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 100)
                        }
                        .padding(.top, 24)
                    }
                    
                    // Fixed bottom action buttons
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 16) {
                            Button("Skip This Note") {
                                Task {
                                    await viewModel.confirmProcessing(for: result, approved: false)
                                    moveToNext()
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Approve & Process") {
                                Task {
                                    await viewModel.confirmProcessing(for: result, approved: true)
                                    moveToNext()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            if viewModel.pendingConfirmations.count > 1 {
                                if currentIndex < viewModel.pendingConfirmations.count - 1 {
                                    Button("Next →") {
                                        currentIndex += 1
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
            } else {
                // No items to review
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("All items reviewed!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(40)
            }
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
    
    private func moveToNext() {
        if currentIndex < viewModel.pendingConfirmations.count - 1 {
            currentIndex += 1
        } else {
            dismiss()
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
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(.white)
                .font(.headline)
            
            Text(message)
                .foregroundColor(.white)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.color)
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding(.horizontal, 20)
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

/// Calendar view for time-based content organization
struct CalendarView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Calendar")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Time-Based View")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("View your tasks, projects, and content organized by time. Coming soon!")
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

#Preview {
    ContentView()
} 