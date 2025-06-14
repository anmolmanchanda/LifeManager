import SwiftUI

/// Sidebar view displaying parking lot events with drag-to-reschedule functionality
struct ParkingLotSidebar: View {
    
    // MARK: - Properties
    
    @ObservedObject var calendarViewModel: CalendarViewModel
    @State private var draggedEvent: ParkingLotEvent?
    @State private var showingDecisionModal = false
    @State private var selectedDecision: ParkingDecision?
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection
            
            // Buffer status indicator
            bufferStatusSection
            
            Divider()
                .padding(.vertical, 8)
            
            // Parked events list
            if calendarViewModel.parkedEvents.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(calendarViewModel.parkedEvents) { parkedEvent in
                            ParkingLotEventRow(
                                event: parkedEvent,
                                onRemove: {
                                    calendarViewModel.removeFromParkingLot(parkedEvent.id)
                                },
                                onReschedule: { date in
                                    Task {
                                        await calendarViewModel.rescheduleParkedEvent(parkedEvent.id, to: date)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            
            Spacer()
            
            // Actions section
            actionsSection
        }
        .frame(width: 280)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .trailing
        )
        .sheet(isPresented: $showingDecisionModal) {
            if let decision = selectedDecision {
                ParkingDecisionModal(
                    decision: decision,
                    onDecision: { selectedEventIds in
                        Task {
                            await calendarViewModel.parkingLotService.processUserDecision(
                                decisionId: decision.id,
                                selectedEventIds: selectedEventIds
                            )
                        }
                        showingDecisionModal = false
                    }
                )
            }
        }
        .onReceive(calendarViewModel.parkingLotService.$pendingDecisions) { decisions in
            if let firstDecision = decisions.first, selectedDecision == nil {
                selectedDecision = firstDecision
                showingDecisionModal = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "tray.full")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Parking Lot")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Event count badge
                if !calendarViewModel.parkedEvents.isEmpty {
                    Text("\(calendarViewModel.parkedEvents.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
            
            Text("Events that couldn't be scheduled")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Buffer Status Section
    
    private var bufferStatusSection: some View {
        HStack(spacing: 8) {
            Image(systemName: calendarViewModel.bufferStatus.icon)
                .foregroundColor(calendarViewModel.bufferStatus.color)
                .font(.system(size: 12, weight: .medium))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Buffer Status")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(calendarViewModel.bufferStatus.rawValue.capitalized)
                    .font(.system(size: 10))
                    .foregroundColor(calendarViewModel.bufferStatus.color)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(calendarViewModel.bufferStatus.color.opacity(0.1))
        )
        .padding(.horizontal, 12)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No Parked Events")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Text("Events that can't be scheduled will appear here")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack(spacing: 12) {
                // Refresh parking lot
                Button(action: {
                    Task {
                        await calendarViewModel.processIntelligentScheduling()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("Refresh")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Settings
                Button(action: {
                    // Open buffer settings
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Parking Lot Event Row

struct ParkingLotEventRow: View {
    
    let event: ParkingLotEvent
    let onRemove: () -> Void
    let onReschedule: (Date) -> Void
    
    @State private var isHovered = false
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title and importance indicator
            HStack(spacing: 6) {
                // Importance indicator
                Circle()
                    .fill(event.isImportant ? Color.red : Color.orange)
                    .frame(width: 6, height: 6)
                
                Text(event.originalEvent.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Days in parking lot badge
                if event.daysInParkingLot > 0 {
                    Text("\(event.daysInParkingLot)d")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(event.daysInParkingLot >= 7 ? Color.red : Color.gray)
                        .clipShape(Capsule())
                }
            }
            
            // Reason and duration
            HStack(spacing: 4) {
                Text(event.reason.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("\(event.originalEvent.durationMinutes)min")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            // Action buttons (shown on hover)
            if isHovered || isDragging {
                HStack(spacing: 8) {
                    Button("Reschedule") {
                        onReschedule(Date())
                    }
                    .font(.system(size: 9))
                    .foregroundColor(.blue)
                    .buttonStyle(PlainButtonStyle())
                    
                    Button("Remove") {
                        onRemove()
                    }
                    .font(.system(size: 9))
                    .foregroundColor(.red)
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(event.isImportant ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .opacity(isDragging ? 0.7 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onDrag {
            isDragging = true
            return NSItemProvider(object: event.id.uuidString as NSString)
        }
        .onChange(of: isDragging) { newValue in
            if !newValue {
                // Drag ended
                withAnimation(.spring()) {
                    isDragging = false
                }
            }
        }
    }
}

// MARK: - Parking Decision Modal

struct ParkingDecisionModal: View {
    
    let decision: ParkingDecision
    let onDecision: ([UUID]) -> Void
    
    @State private var selectedEventIds: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Scheduling Decision Required")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Multiple events need to be parked. Select which events to park:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // LLM Suggestion
            if !decision.llmSuggestion.reasoning.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Recommendation")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(decision.llmSuggestion.reasoning)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Events list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(decision.events) { event in
                        HStack(spacing: 12) {
                            // Checkbox
                            Button(action: {
                                if selectedEventIds.contains(event.id) {
                                    selectedEventIds.remove(event.id)
                                } else {
                                    selectedEventIds.insert(event.id)
                                }
                            }) {
                                Image(systemName: selectedEventIds.contains(event.id) ? "checkmark.square" : "square")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Event details
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text("\(event.durationMinutes)min • \(event.type.displayName)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // AI recommendation badge
                            if decision.llmSuggestion.recommendedToPark.contains(event.id) {
                                Text("AI Pick")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedEventIds.contains(event.id) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
            
            // Actions
            HStack(spacing: 12) {
                Button("Use AI Recommendation") {
                    selectedEventIds = Set(decision.llmSuggestion.recommendedToPark)
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Park Selected") {
                    onDecision(Array(selectedEventIds))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedEventIds.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 500)
        .onAppear {
            // Pre-select AI recommendations
            selectedEventIds = Set(decision.llmSuggestion.recommendedToPark)
        }
    }
}

// MARK: - Preview

#Preview {
    ParkingLotSidebar(calendarViewModel: CalendarViewModel())
        .frame(height: 600)
} 