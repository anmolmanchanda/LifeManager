import SwiftUI

/// Smart Filter Bar - Horizontal scrollable filter chips with predefined and custom filters
struct SmartFilterBar: View {
    @Binding var activeFilters: Set<FocusFilter>
    let availableFilters: [FocusFilter]
    let onFilterTap: (FocusFilter) -> Void
    let onCustomFilterTap: () -> Void
    
    @State private var showingClearConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with filter count
            HStack {
                Text("Smart Filters")
                    .font(.headline)
                
                if !activeFilters.isEmpty {
                    Text("(\(activeFilters.count) active)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !activeFilters.isEmpty {
                    Button("Clear All") {
                        showingClearConfirmation = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            
            // Scrollable filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Predefined filters
                    ForEach(availableFilters.sorted(by: { $0.sortOrder < $1.sortOrder })) { filter in
                        FilterChip(
                            filter: filter,
                            isActive: activeFilters.contains(filter),
                            onTap: {
                                onFilterTap(filter)
                            }
                        )
                    }
                    
                    // Custom filter button
                    CustomFilterButton(onTap: onCustomFilterTap)
                }
                .padding(.horizontal, 1) // Prevent clipping of shadows
            }
            .contentMargins(.horizontal, 1) // iOS 17+ content margins
        }
        .confirmationDialog(
            "Clear all active filters?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                activeFilters.removeAll()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let filter: FocusFilter
    let isActive: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Icon or emoji
                if filter.icon.count == 1 {
                    // Emoji
                    Text(filter.icon)
                        .font(.caption)
                } else {
                    // SF Symbol
                    Image(systemName: filter.icon)
                        .font(.caption)
                        .foregroundColor(textColor)
                }
                
                // Filter name
                Text(filter.name.replacingOccurrences(of: "🔥 ", with: "")
                          .replacingOccurrences(of: "🎯 ", with: "")
                          .replacingOccurrences(of: "⚡ ", with: "")
                          .replacingOccurrences(of: "🚀 ", with: "")
                          .replacingOccurrences(of: "📋 ", with: ""))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                // Count indicator (if active and has matches)
                if isActive {
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(textColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: shadowColor, radius: isActive ? 3 : 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1) {
            // Long press feedback
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    private var backgroundColor: Color {
        if isActive {
            return .blue
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var textColor: Color {
        if isActive {
            return .white
        } else {
            return .primary
        }
    }
    
    private var borderColor: Color {
        if isActive {
            return .blue
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var shadowColor: Color {
        if isActive {
            return .blue.opacity(0.3)
        } else {
            return Color.black.opacity(0.1)
        }
    }
}

// MARK: - Custom Filter Button

struct CustomFilterButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("Custom")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Customization Sheet

struct FilterCustomizationView: View {
    @Binding var availableFilters: [FocusFilter]
    @Binding var activeFilters: Set<FocusFilter>
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingNewFilterSheet = false
    @State private var editingFilter: FocusFilter?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(availableFilters.sorted(by: { $0.sortOrder < $1.sortOrder })) { filter in
                        FilterCustomizationRow(
                            filter: filter,
                            isActive: activeFilters.contains(filter),
                            onToggle: { isOn in
                                if isOn {
                                    activeFilters.insert(filter)
                                } else {
                                    activeFilters.remove(filter)
                                }
                            },
                            onEdit: {
                                editingFilter = filter
                            },
                            onDelete: {
                                if !filter.isDefault {
                                    availableFilters.removeAll { $0.id == filter.id }
                                    activeFilters.remove(filter)
                                }
                            }
                        )
                    }
                } header: {
                    Text("Available Filters")
                } footer: {
                    Text("Tap the toggle to apply filters. Edit custom filters by tapping the info button.")
                }
                
                Section {
                    Button(action: {
                        showingNewFilterSheet = true
                    }) {
                        Label("Create Custom Filter", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text("Custom Filters")
                }
            }
            .navigationTitle("Filter Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingNewFilterSheet) {
            CreateCustomFilterView(
                availableFilters: $availableFilters,
                onSave: { newFilter in
                    availableFilters.append(newFilter)
                }
            )
        }
        .sheet(item: $editingFilter) { filter in
            EditFilterView(
                filter: filter,
                onSave: { updatedFilter in
                    if let index = availableFilters.firstIndex(where: { $0.id == filter.id }) {
                        availableFilters[index] = updatedFilter
                    }
                }
            )
        }
    }
}

// MARK: - Filter Customization Row

struct FilterCustomizationRow: View {
    let filter: FocusFilter
    let isActive: Bool
    let onToggle: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            // Toggle
            Toggle("", isOn: .init(
                get: { isActive },
                set: onToggle
            ))
            .labelsHidden()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(filter.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(filter.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if !filter.isDefault {
                    // Edit button
                    Button(action: onEdit) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Delete button
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash.circle")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Default filter indicator
                    Text("Default")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("Delete Filter", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete the filter \"\(filter.name)\"? This action cannot be undone.")
        }
    }
}

// MARK: - Create Custom Filter View (Placeholder)

struct CreateCustomFilterView: View {
    @Binding var availableFilters: [FocusFilter]
    let onSave: (FocusFilter) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var filterName = ""
    @State private var filterDescription = ""
    @State private var selectedPriorities: Set<FocusPriority> = []
    @State private var selectedUrgencies: Set<UrgencyLevel> = []
    @State private var maxDuration: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Filter Name", text: $filterName)
                    TextField("Description", text: $filterDescription)
                } header: {
                    Text("Basic Information")
                }
                
                Section {
                    Text("Custom filter creation coming soon...")
                        .foregroundColor(.secondary)
                } header: {
                    Text("Filter Criteria")
                }
            }
            .navigationTitle("New Filter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        // TODO: Implement custom filter creation
                        dismiss()
                    }
                    .disabled(filterName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Filter View (Placeholder)

struct EditFilterView: View {
    let filter: FocusFilter
    let onSave: (FocusFilter) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Filter editing coming soon...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Filter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let sampleFilters = FocusFilter.defaultFilters
    
    return VStack {
        SmartFilterBar(
            activeFilters: .constant(Set([sampleFilters[0], sampleFilters[1]])),
            availableFilters: sampleFilters,
            onFilterTap: { _ in },
            onCustomFilterTap: { }
        )
        .padding()
        
        Spacer()
    }
}