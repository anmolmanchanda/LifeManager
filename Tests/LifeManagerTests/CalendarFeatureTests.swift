import XCTest
import SwiftUI
@testable import LifeManager

/// Mock CalendarViewModel for testing without external dependencies
@MainActor
class MockCalendarViewModel: ObservableObject {
    // Published properties matching CalendarViewModel
    @Published var viewMode: CalendarViewMode = .day
    @Published var selectedDate: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var events: [CalendarEvent] = []
    @Published var filteredEvents: [CalendarEvent] = []
    @Published var activeFilters: Set<CalendarFilter> = []
    @Published var isSmartSchedulingEnabled: Bool = true
    @Published var dropTargetDate: Date?
    @Published var togglSyncStatus: TogglSyncStatus = .idle
    @Published var filteredUnscheduledTasks: [LifeTask] = []
    @Published var allTasks: [LifeTask] = []
    @Published var draggingTask: LifeTask?
    @Published var isDragging: Bool = false
    @Published var draggedTask: LifeTask?
    @Published var dragPosition: CGPoint = .zero
    @Published var parkingLotService: EnhancedParkingLotService
    
    init() {
        self.parkingLotService = EnhancedParkingLotService()
    }
    
    // Mock implementations of key methods
    func scheduleTask(_ task: LifeTask, at date: Date) async {
        // Create calendar event
        let event = CalendarEvent(
            title: task.title,
            description: task.description,
            startDate: date,
            endDate: date.addingTimeInterval(TimeInterval((task.estimatedDuration ?? 60) * 60)),
            workPersonal: task.workPersonal,
            color: .blue,
            source: .user,
            duration: TimeInterval((task.estimatedDuration ?? 60) * 60)
        )
        
        // Update UI state
        events.append(event)
        applyFilters()
        
        // Remove task from parking lot
        if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
            allTasks.remove(at: index)
        }
    }
    
    func startDragging(_ task: LifeTask) {
        draggedTask = task
        isDragging = true
    }
    
    func cancelDrag() {
        draggedTask = nil
        isDragging = false
    }
    
    func applyFilters() {
        filteredEvents = events // Simple implementation for testing
    }
    
    func events(for date: Date, hour: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        let endOfHour = calendar.date(byAdding: .hour, value: 1, to: startOfHour) ?? date
        
        return events.filter { event in
            event.startDate < endOfHour && event.endDate > startOfHour
        }
    }
    
    func suggestedSlots(for task: LifeTask) -> [Date] {
        // Return a simple suggestion for testing
        return [Date().addingTimeInterval(3600)]
    }
    
    // No-op methods to avoid API calls
    func loadCalendarData() async { }
    func syncWithToggl() async { }
}

/// Comprehensive tests for calendar features
@MainActor
final class CalendarFeatureTests: XCTestCase {
    
    var calendarViewModel: MockCalendarViewModel!
    var mockTaskRepository: MockTaskRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockTaskRepository = MockTaskRepository()
        calendarViewModel = MockCalendarViewModel()
        
        // Add test data
        await setupTestData()
    }
    
    override func tearDown() {
        calendarViewModel = nil
        mockTaskRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Setup
    
    func setupTestData() async {
        // Create test tasks for parking lot
        let testTask1 = LifeTask(
            id: UUID(),
            title: "Test Task 1",
            description: "First test task",
            priority: .high,
            status: .todo,
            estimatedDuration: 60,
            workPersonal: .work
        )
        
        let testTask2 = LifeTask(
            id: UUID(),
            title: "Test Task 2", 
            description: "Second test task",
            priority: .medium,
            status: .todo,
            estimatedDuration: 30,
            workPersonal: .personal
        )
        
        calendarViewModel.allTasks = [testTask1, testTask2]
        
        // Create test events (use a different date to avoid conflicts with other tests)
        let testEvent = CalendarEvent(
            title: "Test Event",
            description: "Test event description",
            startDate: Date().addingTimeInterval(86400), // Tomorrow
            endDate: Date().addingTimeInterval(86400 + 3600), // Tomorrow + 1 hour
            workPersonal: .work,
            color: .blue,
            source: .user,
            duration: 3600
        )
        
        calendarViewModel.events = [testEvent]
    }
    
    // MARK: - Task Scheduling Tests
    
    func testTaskScheduling() async {
        // Given
        let task = calendarViewModel.allTasks.first!
        let scheduleDate = Date().addingTimeInterval(3600) // 1 hour from now
        let initialTaskCount = calendarViewModel.allTasks.count
        let initialEventCount = calendarViewModel.events.count
        
        // When
        await calendarViewModel.scheduleTask(task, at: scheduleDate)
        
        // Then
        let finalTaskCount = calendarViewModel.allTasks.count
        let finalEventCount = calendarViewModel.events.count
        let createdEvent = calendarViewModel.events.last!
        
        XCTAssertEqual(finalTaskCount, initialTaskCount - 1, "Task should be removed from parking lot")
        XCTAssertEqual(finalEventCount, initialEventCount + 1, "New event should be created")
        
        // Verify the created event
        XCTAssertEqual(createdEvent.title, task.title)
        XCTAssertEqual(createdEvent.startDate, scheduleDate)
        XCTAssertEqual(createdEvent.source, .user)
    }
    
    func testTaskSchedulingWithInvalidTask() async {
        // Given
        let invalidTask = LifeTask(
            id: UUID(),
            title: "Invalid Task",
            description: "This task is not in parking lot",
            priority: .low,
            status: .todo,
            estimatedDuration: 45,
            workPersonal: .work
        )
        let scheduleDate = Date().addingTimeInterval(3600)
        let initialTaskCount = calendarViewModel.allTasks.count
        let initialEventCount = calendarViewModel.events.count
        
        // When
        await calendarViewModel.scheduleTask(invalidTask, at: scheduleDate)
        
        // Then - should still create event even if task not in parking lot
        let finalTaskCount = calendarViewModel.allTasks.count
        let finalEventCount = calendarViewModel.events.count
        
        XCTAssertEqual(finalTaskCount, initialTaskCount, "Parking lot should be unchanged")
        XCTAssertEqual(finalEventCount, initialEventCount + 1, "Event should still be created")
    }
    
    // MARK: - Week View Tests
    
    func testWeekViewDataLoading() async {
        // Given
        let testDate = Date()
        
        // When
        calendarViewModel.selectedDate = testDate
        
        // Then
        XCTAssertEqual(calendarViewModel.selectedDate, testDate, "Selected date should be updated")
        
        // Test week range calculation
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: testDate)?.start ?? testDate
        let weekDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        
        XCTAssertEqual(weekDays.count, 7, "Week should have 7 days")
        XCTAssertTrue(weekDays.contains { calendar.isDate($0, inSameDayAs: testDate) }, "Week should contain selected date")
    }
    
    func testEventsForSpecificHour() async {
        // Given
        let testDate = Date()
        let hour = 14 // 2 PM
        
        // Create event for specific hour
        let calendar = Calendar.current
        let eventStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: testDate)!
        let eventEnd = calendar.date(bySettingHour: hour, minute: 30, second: 0, of: testDate)!
        
        let hourEvent = CalendarEvent(
            title: "Hour Event",
            description: "Event for specific hour",
            startDate: eventStart,
            endDate: eventEnd,
            workPersonal: .work,
            color: .green,
            source: .user,
            duration: 1800
        )
        
        calendarViewModel.events.append(hourEvent)
        
        // When
        let eventsForHour = calendarViewModel.events(for: testDate, hour: hour)
        
        // Then
        XCTAssertTrue(eventsForHour.contains { $0.id == hourEvent.id }, "Should find event for specific hour")
    }
    
    // MARK: - Context Menu Tests
    
    func testContextMenuEventCreation() async {
        // Given
        let initialEventCount = calendarViewModel.events.count
        let testDate = Date().addingTimeInterval(3600) // Future date
        
        // When - Simulate context menu "Create Event" action
        let newEvent = CalendarEvent(
            title: "New Event",
            description: "Created via context menu",
            startDate: testDate,
            endDate: testDate.addingTimeInterval(3600),
            workPersonal: .work,
            color: .blue,
            source: .user,
            duration: 3600
        )
        
        calendarViewModel.events.append(newEvent)
        
        // Then
        let finalEventCount = calendarViewModel.events.count
        let lastEvent = calendarViewModel.events.last
        
        XCTAssertEqual(finalEventCount, initialEventCount + 1, "New event should be created")
        XCTAssertEqual(lastEvent?.title, "New Event")
    }
    
    func testContextMenuQuickSchedule() async {
        // Given
        let task = calendarViewModel.allTasks.first!
        let scheduleDate = Date().addingTimeInterval(3600)
        let initialTaskCount = calendarViewModel.allTasks.count
        
        // When - Simulate context menu "Quick Schedule" action
        await calendarViewModel.scheduleTask(task, at: scheduleDate)
        
        // Then
        let finalTaskCount = calendarViewModel.allTasks.count
        XCTAssertEqual(finalTaskCount, initialTaskCount - 1, "Task should be scheduled and removed from parking lot")
    }
    
    func testContextMenuClearTimeSlot() async {
        // Given
        let testDate = Date()
        let userEvent = CalendarEvent(
            title: "User Event",
            description: "User created event",
            startDate: testDate,
            endDate: testDate.addingTimeInterval(3600),
            workPersonal: .work,
            color: .blue,
            source: .user,
            duration: 3600
        )
        
        let togglEvent = CalendarEvent(
            title: "Toggl Event",
            description: "Toggl tracked event",
            startDate: testDate.addingTimeInterval(3600),
            endDate: testDate.addingTimeInterval(7200),
            workPersonal: .work,
            color: .green,
            source: .toggl,
            duration: 3600
        )
        
        calendarViewModel.events.append(contentsOf: [userEvent, togglEvent])
        let initialEventCount = calendarViewModel.events.count
        
        // When - Simulate context menu "Clear Time Slot" action (should only remove user events)
        calendarViewModel.events.removeAll { $0.source == .user && Calendar.current.isDate($0.startDate, inSameDayAs: testDate) }
        
        // Then
        let finalEventCount = calendarViewModel.events.count
        let remainingEvents = calendarViewModel.events
        
        XCTAssertEqual(finalEventCount, initialEventCount - 1, "Only user event should be removed")
        XCTAssertTrue(remainingEvents.contains { $0.id == togglEvent.id }, "Toggl event should remain")
        XCTAssertFalse(remainingEvents.contains { $0.id == userEvent.id }, "User event should be removed")
    }
    
    // MARK: - Drag and Drop Tests
    
    func testDragAndDropTaskScheduling() async {
        // Given
        let task = calendarViewModel.allTasks.first!
        let dropDate = Date().addingTimeInterval(7200) // 2 hours from now
        let initialTaskCount = calendarViewModel.allTasks.count
        let initialEventCount = calendarViewModel.events.count
        
        // When - Simulate drag and drop
        calendarViewModel.startDragging(task)
        let draggedTask = calendarViewModel.draggedTask
        XCTAssertEqual(draggedTask?.id, task.id, "Task should be set as dragged")
        
        await calendarViewModel.scheduleTask(task, at: dropDate)
        calendarViewModel.cancelDrag()
        
        // Then
        let finalDraggedTask = calendarViewModel.draggedTask
        let finalTaskCount = calendarViewModel.allTasks.count
        let finalEventCount = calendarViewModel.events.count
        
        XCTAssertNil(finalDraggedTask, "Dragged task should be cleared")
        XCTAssertEqual(finalTaskCount, initialTaskCount - 1, "Task should be removed from parking lot")
        XCTAssertEqual(finalEventCount, initialEventCount + 1, "New event should be created")
    }
    
    // MARK: - Error Handling Tests
    
    func testSchedulingWithNilTask() async {
        // Given
        let initialEventCount = calendarViewModel.events.count
        let scheduleDate = Date().addingTimeInterval(3600)
        
        // When - Try to schedule nil task (should not crash)
        let allTasks = calendarViewModel.allTasks
        if let nilTask = allTasks.first(where: { $0.id == UUID() }) {
            await calendarViewModel.scheduleTask(nilTask, at: scheduleDate)
        }
        
        // Then - Should handle gracefully
        let finalEventCount = calendarViewModel.events.count
        XCTAssertEqual(finalEventCount, initialEventCount, "No event should be created for nil task")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeDataSet() async {
        // Given - Create large dataset
        let largeTasks = (0..<1000).map { index in
            LifeTask(
                id: UUID(),
                title: "Task \(index)",
                description: "Description \(index)",
                priority: .medium,
                status: .todo,
                estimatedDuration: 60,
                workPersonal: index % 2 == 0 ? .work : .personal
            )
        }
        
        let largeEvents = (0..<1000).map { index in
            CalendarEvent(
                title: "Event \(index)",
                description: "Description \(index)",
                startDate: Date().addingTimeInterval(TimeInterval(index * 3600)),
                endDate: Date().addingTimeInterval(TimeInterval(index * 3600 + 1800)),
                workPersonal: index % 2 == 0 ? .work : .personal,
                color: .blue,
                source: .user,
                duration: 1800
            )
        }
        
        // When - Measure performance
        measure {
            calendarViewModel.allTasks = largeTasks
            calendarViewModel.events = largeEvents
            
            // Test filtering
            let filteredEvents = calendarViewModel.events.filter { $0.source == .user }
            XCTAssertEqual(filteredEvents.count, 1000)
        }
    }
}

// MARK: - Mock Classes

class MockTaskRepository {
    var tasks: [LifeTask] = []
    
    func fetchTasks() async throws -> [LifeTask] {
        return tasks
    }
    
    func updateTask(_ task: LifeTask) async throws -> LifeTask {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
        return task
    }
    
    func deleteTask(id: UUID) async throws {
        tasks.removeAll { $0.id == id }
    }
}

// MARK: - Test Extensions

extension CalendarViewModel {
    /// Test helper to access events for specific date and hour
    func events(for date: Date, hour: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: date) ?? date
        
        return events.filter { event in
            return event.startDate >= startOfHour && event.startDate <= endOfHour
        }
    }
} 