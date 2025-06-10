import SwiftUI

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
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

/// Main authenticated app interface with PARA navigation
struct MainAppView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        NavigationSplitView {
            // PARA Sidebar
            PARAsidebar()
        } content: {
            // Main content based on selection
            MainContentArea()
        } detail: {
            // Detail view (for selected items)
            DetailView()
        }
        .searchable(text: $viewModel.searchText, prompt: "Search across all content")
        .onSubmit(of: .search) {
            Task {
                await viewModel.search(query: viewModel.searchText)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.showingAddContent = true
                }) {
                    Image(systemName: "plus")
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
        }
        .sheet(isPresented: $viewModel.showingAddContent) {
            AddContentView()
                .environmentObject(viewModel)
        }
    }
    
    @ViewBuilder
    private func PARAsidebar() -> some View {
        List(selection: $viewModel.selectedSidebarItem) {
            Section("PARA") {
                ForEach(SidebarItem.allCases) { item in
                    Label(item.displayName, systemImage: item.iconName)
                        .tag(item)
                }
            }
            
            Section("Areas") {
                ForEach(viewModel.areas) { area in
                    HStack {
                        Circle()
                            .fill(Color(hex: area.color))
                            .frame(width: 12, height: 12)
                        
                        Text(area.name)
                            .font(.caption)
                        
                        Spacer()
                    }
                    .onTapGesture {
                        // Navigate to area detail
                    }
                }
            }
            
            Section("Projects") {
                ForEach(viewModel.projects) { project in
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.blue)
                        
                        Text(project.name)
                            .font(.caption)
                        
                        Spacer()
                        
                        // Project status indicator
                        Circle()
                            .fill(project.status == .active ? .green : .gray)
                            .frame(width: 8, height: 8)
                    }
                    .onTapGesture {
                        // Navigate to project detail
                    }
                }
            }
        }
        .navigationTitle("LifeManager")
        .listStyle(SidebarListStyle())
    }
}

/// Main content area that changes based on sidebar selection
struct MainContentArea: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        Group {
            switch viewModel.selectedSidebarItem {
            case .inbox:
                InboxView()
            case .areas:
                AreasView()
            case .projects:
                ProjectsView()
            case .resources:
                ResourcesView()
            case .archives:
                ArchivesView()
            case .focus:
                FocusView()
            }
        }
        .navigationTitle(viewModel.selectedSidebarItem.displayName)
    }
}

/// Detail view for selected content
struct DetailView: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Select an item to view details")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }
}

// MARK: - Content Views

/// Inbox view for unprocessed content
struct InboxView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Natural Language Input Bar
            NaturalLanguageInputBar()
            
            // Recent unprocessed blobs
            if viewModel.recentBlobs.isEmpty {
                ContentUnavailableView(
                    "No recent content",
                    systemImage: "tray",
                    description: Text("Add some content using the input bar above or the + button")
                )
            } else {
                List(viewModel.recentBlobs) { blob in
                    BlobRowView(blob: blob)
                }
            }
        }
        .padding()
    }
}

/// Natural language input bar for quick content addition
struct NaturalLanguageInputBar: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var inputText = ""
    @State private var isProcessing = false
    
    var body: some View {
        HStack {
            TextField("Type anything... \"Lunch with Sarah tomorrow at noon\", \"Review Q3 budget\", etc.", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    processInput()
                }
            
            Button(action: processInput) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                }
            }
            .disabled(inputText.isEmpty || isProcessing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func processInput() {
        guard !inputText.isEmpty else { return }
        
        isProcessing = true
        let content = inputText
        inputText = ""
        
        Task {
            await viewModel.addQuickNote(content)
            isProcessing = false
        }
    }
}

/// Row view for displaying blobs
struct BlobRowView: View {
    let blob: Blob
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: sourceTypeIcon(blob.sourceType))
                    .foregroundColor(.blue)
                
                Text(blob.sourceType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
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
                
                if !blob.processed {
                    Label("Unprocessed", systemImage: "exclamationmark.circle")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
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

/// Areas overview
struct AreasView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 200))
        ], spacing: 20) {
            ForEach(viewModel.areas) { area in
                AreaCardView(area: area)
            }
        }
        .padding()
    }
}

struct AreaCardView: View {
    let area: Area
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let iconName = area.icon {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(Color(hex: area.color))
                }
                
                Spacer()
                
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(height: 120)
    }
}

/// Projects view
struct ProjectsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        List(viewModel.projects) { project in
            ProjectRowView(project: project)
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    
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
    }
}

/// Resources view
struct ResourcesView: View {
    var body: some View {
        Text("Resources view - Knowledge base coming soon")
            .font(.title2)
            .foregroundColor(.secondary)
    }
}

/// Archives view
struct ArchivesView: View {
    var body: some View {
        Text("Archives view - Archived content coming soon")
            .font(.title2)
            .foregroundColor(.secondary)
    }
}

/// Focus view for focus tasks
struct FocusView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            if viewModel.focusTasks.isEmpty {
                ContentUnavailableView(
                    "No focus tasks",
                    systemImage: "target",
                    description: Text("Mark tasks as focus to see them here")
                )
            } else {
                List(viewModel.focusTasks) { task in
                    TaskRowView(task: task)
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: Task
    
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
                    .background(Color(.systemGray6))
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
            .navigationBarTitleDisplayMode(.inline)
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

#Preview {
    ContentView()
} 