import SwiftUI

/// Review UI for brain dump analysis results before saving to database
struct BrainDumpReviewView: View {
    let result: BrainDumpResult
    @State private var editableItems: [EnhancedBrainDumpItem]
    @State private var isProcessing = false
    @State private var showingExecutionSummary = false
    @State private var executionSummary: ExecutionSummary?
    
    let onComplete: (ExecutionSummary) -> Void
    let onCancel: () -> Void
    
    private let brainDumpProcessor = LLMBrainDumpProcessor()
    
    init(result: BrainDumpResult, onComplete: @escaping (ExecutionSummary) -> Void, onCancel: @escaping () -> Void) {
        self.result = result
        self.onComplete = onComplete
        self.onCancel = onCancel
        self._editableItems = State(initialValue: result.suggestedItems)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with confidence indicator
            headerView
            
            Divider()
            
            // Original input preview
            originalInputView
            
            Divider()
            
            // Items list for review/editing
            itemsListView
            
            Divider()
            
            // Action buttons
            actionButtonsView
        }
        .navigationTitle("Review Brain Dump")
        .sheet(isPresented: $showingExecutionSummary) {
            if let summary = executionSummary {
                ExecutionSummaryView(summary: summary) {
                    onComplete(summary)
                }
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI Analysis Complete")
                    .font(.headline)
                Spacer()
                confidenceIndicator
            }
            
            if result.requiresReview {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Some items need your review")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    private var confidenceIndicator: some View {
        HStack(spacing: 4) {
            Text("Confidence:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(result.confidence * 100))%")
                .font(.caption.weight(.semibold))
                .foregroundColor(confidenceColor)
            
            Circle()
                .fill(confidenceColor)
                .frame(width: 8, height: 8)
        }
    }
    
    private var confidenceColor: Color {
        switch result.confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var originalInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Original Input")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(result.originalInput.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                Text(result.originalInput)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 100)
        }
        .padding()
    }
    
    private var itemsListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Extracted Items")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(editableItems.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            List {
                ForEach(editableItems.indices, id: \.self) { index in
                    BrainDumpItemRow(
                        item: $editableItems[index],
                        onRemove: {
                            editableItems.remove(at: index)
                        }
                    )
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Execute Brain Dump") {
                executeBrainDump()
            }
            .buttonStyle(.borderedProminent)
            .disabled(editableItems.isEmpty || isProcessing)
        }
        .padding()
        .background(Color.clear)
    }
    
    private func executeBrainDump() {
        print("🧠 BRAIN DUMP REVIEW: Starting execution with \(editableItems.count) items")
        isProcessing = true
        
        Task {
            do {
                print("🧠 BRAIN DUMP REVIEW: Calling brainDumpProcessor.executeBrainDump...")
                let summary = try await brainDumpProcessor.executeBrainDump(result, userApprovedItems: editableItems)
                print("🧠 BRAIN DUMP REVIEW: ✅ Execution completed successfully")
                
                await MainActor.run {
                    self.executionSummary = summary
                    self.showingExecutionSummary = true
                    self.isProcessing = false
                }
                
            } catch {
                print("🧠 BRAIN DUMP REVIEW: ❌ Execution failed: \(error)")
                print("🧠 BRAIN DUMP REVIEW: ❌ Error details: \(error.localizedDescription)")
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
}

/// Individual item row for editing
struct BrainDumpItemRow: View {
    @Binding var item: EnhancedBrainDumpItem
    let onRemove: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main item info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    
                    if !item.content.isEmpty && item.content != item.title {
                        Text(item.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Category and confidence chips
                    HStack(spacing: 4) {
                        paraChip
                        confidenceChip
                    }
                    
                    // Work/Personal chip
                    workPersonalChip
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded details
            if isExpanded {
                expandedDetailsView
            }
            
            // Action buttons
            HStack {
                Button("Remove") {
                    onRemove()
                }
                .foregroundColor(.red)
                .font(.caption)
                
                Spacer()
                
                Button(isExpanded ? "Collapse" : "Expand") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var paraChip: some View {
        Text(item.paraCategory.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(item.paraCategory.color.opacity(0.2))
            .foregroundColor(item.paraCategory.color)
            .cornerRadius(4)
    }
    
    private var workPersonalChip: some View {
        Text(item.workPersonal.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(item.workPersonal == WorkPersonalType.work ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
            .foregroundColor(item.workPersonal == WorkPersonalType.work ? .blue : .green)
            .cornerRadius(4)
    }
    
    private var confidenceChip: some View {
        Text("\(Int(item.confidence * 100))%")
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(item.confidence > 0.7 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
            .foregroundColor(item.confidence > 0.7 ? .green : .orange)
            .cornerRadius(4)
    }
    
    private var expandedDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content type and suggested assignments
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Type:")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text(item.contentType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                    
                    Spacer()
                    
                    if let area = item.suggestedArea {
                        Text("Area:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text(area)
                            .font(.caption)
                    }
                }
                
                if let project = item.suggestedProject {
                    HStack {
                        Text("Project:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text(project)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
            
            // Tags
            if !item.tags.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tags:")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], alignment: .leading, spacing: 4) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Priority and due date
            HStack {
                if item.priority != .medium {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Priority:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text(item.priority.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(item.priority.color)
                    }
                }
                
                if let dueDate = item.dueDate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Due Date:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Text(dueDate)
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.leading, 24)
    }
}

/// Execution summary view
struct ExecutionSummaryView: View {
    let summary: ExecutionSummary
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Success summary
                    successSummaryView
                    
                    // Created items breakdown
                    if summary.successCount > 0 {
                        createdItemsView
                    }
                    
                    // Errors (if any)
                    if !summary.errors.isEmpty {
                        errorsView
                    }
                }
                .padding()
            }
            .navigationTitle("Brain Dump Complete")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Additional prominent Done button at bottom
                HStack {
                    Spacer()
                    Button("Done") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                    .padding()
                    Spacer()
                }
                .background(.regularMaterial)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    private var successSummaryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Brain Dump Executed Successfully")
                    .font(.headline)
                
                Spacer()
            }
            
            Text("Created \(summary.successCount) items from your input")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var createdItemsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Created Items")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if !summary.tasksCreated.isEmpty {
                    itemTypeSection(title: "Tasks", count: summary.tasksCreated.count, icon: "checkmark.square", color: .blue)
                }
                
                if !summary.notesCreated.isEmpty {
                    itemTypeSection(title: "Notes", count: summary.notesCreated.count, icon: "note.text", color: .orange)
                }
                
                if !summary.journalEntriesCreated.isEmpty {
                    itemTypeSection(title: "Journal Entries", count: summary.journalEntriesCreated.count, icon: "book", color: .purple)
                }
                
                if !summary.resourcesCreated.isEmpty {
                    itemTypeSection(title: "Resources", count: summary.resourcesCreated.count, icon: "folder", color: .green)
                }
                
                if !summary.appointmentsCreated.isEmpty {
                    itemTypeSection(title: "Appointments", count: summary.appointmentsCreated.count, icon: "calendar", color: .red)
                }
                
                if !summary.habitsCreated.isEmpty {
                    itemTypeSection(title: "Habits", count: summary.habitsCreated.count, icon: "repeat", color: .indigo)
                }
                
                if !summary.goalsCreated.isEmpty {
                    itemTypeSection(title: "Goals", count: summary.goalsCreated.count, icon: "target", color: .pink)
                }
                
                if !summary.financialTransactionsCreated.isEmpty {
                    itemTypeSection(title: "Financial Transactions", count: summary.financialTransactionsCreated.count, icon: "dollarsign.circle", color: .yellow)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private func itemTypeSection(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
    
    private var errorsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Errors")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(summary.errors, id: \.self) { error in
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
}

// MARK: - Extensions

extension PARACategory {
    var color: Color {
        switch self {
        case .project:
            return .blue
        case .area:
            return .green
        case .resource:
            return .purple
        case .archive:
            return .gray
        }
    }
}

extension TaskPriority {
    var color: Color {
        switch self {
        case .urgent:
            return .red
        case .high:
            return .orange
        case .medium:
            return .blue
        case .low:
            return .gray
        }
    }
} 