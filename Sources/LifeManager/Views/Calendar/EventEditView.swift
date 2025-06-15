import SwiftUI

/// Simple popup view for quickly editing calendar events
struct EventEditView: View {
    @Binding var event: CalendarEvent
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    
    let onSave: (CalendarEvent) -> Void
    
    init(event: Binding<CalendarEvent>, onSave: @escaping (CalendarEvent) -> Void) {
        self._event = event
        self.onSave = onSave
        
        // Initialize state from event
        self._title = State(initialValue: event.wrappedValue.title)
        self._startDate = State(initialValue: event.wrappedValue.startDate)
        self._endDate = State(initialValue: event.wrappedValue.endDate)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Edit Event")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("✕") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.title2)
            }
            
            // Form fields
            VStack(spacing: 16) {
                // Title field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Event title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                // Start time field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                // End time field
                VStack(alignment: .leading, spacing: 4) {
                    Text("End Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Save") {
                    saveEvent()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .onChange(of: startDate) { newStartDate in
            // Automatically adjust end date if it's before start date
            if endDate <= newStartDate {
                endDate = newStartDate.addingTimeInterval(3600) // Add 1 hour
            }
        }
    }
    
    private func saveEvent() {
        // Ensure end date is after start date
        if endDate <= startDate {
            endDate = startDate.addingTimeInterval(3600) // Default 1 hour duration
        }
        
        let updatedEvent = CalendarEvent(
            id: event.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: event.description, // Preserve existing description
            startDate: startDate,
            endDate: endDate,
            workPersonal: event.workPersonal, // Preserve existing classification
            isLocked: event.isLocked, // Preserve lock status
            color: event.color, // Preserve existing color
            source: event.source, // Preserve source
            duration: endDate.timeIntervalSince(startDate)
        )
        
        onSave(updatedEvent)
        dismiss()
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        EventEditView(
            event: .constant(CalendarEvent.sampleWorkEvent),
            onSave: { _ in }
        )
    }
} 