import XCTest
import Foundation
@testable import LifeManager

@MainActor
final class CalendarViewModelTests: XCTestCase {
    
    var viewModel: CalendarViewModel!
    var mockTogglService: MockTogglService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockTogglService = MockTogglService()
        viewModel = CalendarViewModel()
        // Replace with mock service for testing
        // viewModel.togglService = mockTogglService
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockTogglService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.viewMode, .day, "Should default to day view")
        XCTAssertEqual(viewModel.events.count, 0, "Should start with no events")
        XCTAssertEqual(viewModel.allTasks.count, 0, "Should start with no tasks")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Should have no error initially")
    }
    
    // MARK: - View Mode Tests
    
    func testViewModeSwitch() {
        // Test switching to week view
        viewModel.viewMode = .week
        XCTAssertEqual(viewModel.viewMode, .week)
        
        // Test switching to month view
        viewModel.viewMode = .month
        XCTAssertEqual(viewModel.viewMode, .month)
        
        // Test switching back to day view
        viewModel.viewMode = .day
        XCTAssertEqual(viewModel.viewMode, .day)
    }
    
    // MARK: - Date Navigation Tests
    
    func testDateNavigation() {
        let originalDate = viewModel.selectedDate
        
        // Test next day
        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: originalDate)!
        XCTAssertNotEqual(viewModel.selectedDate, originalDate)
        
        // Test previous day
        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: originalDate)!
        XCTAssertEqual(Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: originalDate)!), true)
        
        // Test today navigation
        viewModel.selectedDate = Date()
        XCTAssertTrue(Calendar.current.isDateInToday(viewModel.selectedDate))
    }
    
    // MARK: - Event Management Tests
    
    func testAddEvent() {
        let event = CalendarEvent.mockEvent()
        viewModel.events.append(event)
        
        XCTAssertEqual(viewModel.events.count, 1)
        XCTAssertEqual(viewModel.events.first?.id, event.id)
    }
    
    func testRemoveEvent() {
        let event = CalendarEvent.mockEvent()
        viewModel.events.append(event)
        
        XCTAssertEqual(viewModel.events.count, 1)
        
        viewModel.events.removeAll { $0.id == event.id }
        XCTAssertEqual(viewModel.events.count, 0)
    }
    
    func testEventsForDate() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todayEvent = CalendarEvent.mockEvent(title: "Today Event", startDate: today)
        let tomorrowEvent = CalendarEvent.mockEvent(title: "Tomorrow Event", startDate: tomorrow)
        
        viewModel.events = [todayEvent, tomorrowEvent]
        
        let todayEvents = viewModel.events(for: today)
        let tomorrowEvents = viewModel.events(for: tomorrow)
        
        XCTAssertEqual(todayEvents.count, 1)
        XCTAssertEqual(tomorrowEvents.count, 1)
        XCTAssertEqual(todayEvents.first?.title, "Today Event")
        XCTAssertEqual(tomorrowEvents.first?.title, "Tomorrow Event")
    }
    
    func testEventsForHour() {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        let eventInHour = CalendarEvent.mockEvent(title: "Hour Event", startDate: date)
        let eventOutsideHour = CalendarEvent.mockEvent(
            title: "Other Hour Event",
            startDate: calendar.date(byAdding: .hour, value: 2, to: date)!
        )
        
        viewModel.events = [eventInHour, eventOutsideHour]
        
        let hourEvents = viewModel.events(for: date, hour: hour)
        
        XCTAssertEqual(hourEvents.count, 1)
        XCTAssertEqual(hourEvents.first?.title, "Hour Event")
    }
    
    // MARK: - Task Management Tests
    
    func testAddTask() {
        let task = LifeTask.mockTask()
        viewModel.allTasks.append(task)
        
        XCTAssertEqual(viewModel.allTasks.count, 1)
        XCTAssertEqual(viewModel.allTasks.first?.id, task.id)
    }
    
    func testRemoveTask() {
        let task = LifeTask.mockTask()
        viewModel.allTasks.append(task)
        
        XCTAssertEqual(viewModel.allTasks.count, 1)
        
        viewModel.allTasks.removeAll { $0.id == task.id }
        XCTAssertEqual(viewModel.allTasks.count, 0)
    }
    
    // MARK: - Drag & Drop Tests
    
    func testDragTaskToCalendar() {
        let task = LifeTask.mockTask(title: "Dragged Task")
        viewModel.allTasks.append(task)
        viewModel.draggedTask = task
        
        XCTAssertNotNil(viewModel.draggedTask)
        XCTAssertEqual(viewModel.draggedTask?.id, task.id)
    }
    
    func testDropTaskOnCalendar() {
        let task = LifeTask.mockTask(title: "Dropped Task")
        let dropDate = Date()
        
        viewModel.allTasks.append(task)
        viewModel.draggedTask = task
        
        // Simulate drop operation
        let event = CalendarEvent.fromTask(task, at: dropDate, duration: 3600)
        viewModel.events.append(event)
        
        // Remove from tasks after successful drop
        viewModel.allTasks.removeAll { $0.id == task.id }
        viewModel.draggedTask = nil
        
        XCTAssertEqual(viewModel.events.count, 1)
        XCTAssertEqual(viewModel.allTasks.count, 0)
        XCTAssertNil(viewModel.draggedTask)
        XCTAssertEqual(viewModel.events.first?.title, "Dropped Task")
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingState() {
        XCTAssertFalse(viewModel.isLoading)
        
        viewModel.isLoading = true
        XCTAssertTrue(viewModel.isLoading)
        
        viewModel.isLoading = false
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        XCTAssertNil(viewModel.errorMessage)
        
        let errorMessage = "Test error occurred"
        viewModel.errorMessage = errorMessage
        
        XCTAssertEqual(viewModel.errorMessage, errorMessage)
        
        // Clear error
        viewModel.errorMessage = nil
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Toggl Integration Tests
    
    func testSyncWithToggl() async throws {
        viewModel.isLoading = true
        
        // Mock sync operation
        let mockEntries = [TogglTimeEntry.mockEntry()]
        let mockEvents = mockEntries.map { mockTogglService.convertToCalendarEvent($0) }
        
        viewModel.events = mockEvents
        viewModel.isLoading = false
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.events.count, 1)
        XCTAssertEqual(viewModel.events.first?.source, .toggl)
    }
    
    // MARK: - Performance Tests
    
    func testLargeEventSet() {
        // Test with large number of events
        let events = (0..<1000).map { i in
            CalendarEvent.mockEvent(title: "Event \(i)")
        }
        
        measure {
            viewModel.events = events
            _ = viewModel.events(for: Date())
        }
        
        XCTAssertEqual(viewModel.events.count, 1000)
    }
    
    func testEventFiltering() {
        let today = Date()
        let events = (0..<100).map { i in
            let date = Calendar.current.date(byAdding: .hour, value: i, to: today) ?? today
            return CalendarEvent.mockEvent(title: "Event \(i)", startDate: date)
        }
        
        viewModel.events = events
        
        measure {
            _ = viewModel.events(for: today)
        }
    }
}

// MARK: - Mock Services

class MockTogglService: ObservableObject {
    func convertToCalendarEvent(_ entry: TogglTimeEntry) -> CalendarEvent {
        return CalendarEvent.mockEvent(
            title: entry.description ?? "Untitled",
            duration: TimeInterval(entry.duration)
        )
    }
}

// MARK: - Mock Data Extensions

extension CalendarEvent {
    static func mockEvent(
        id: UUID = UUID(),
        title: String = "Mock Event",
        startDate: Date = Date(),
        duration: TimeInterval = 3600,
        workPersonal: WorkPersonalType = .work,
        source: CalendarEvent.EventSource = .user
    ) -> CalendarEvent {
        return CalendarEvent(
            id: id,
            title: title,
            description: "Mock description",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(duration),
            workPersonal: workPersonal,
            isLocked: false,
            color: .blue,
            source: source,
            duration: duration
        )
    }
    
    static func fromTask(_ task: LifeTask, at date: Date, duration: TimeInterval) -> CalendarEvent {
        return CalendarEvent(
            id: UUID(),
            title: task.title,
            description: task.description ?? "",
            startDate: date,
            endDate: date.addingTimeInterval(duration),
            workPersonal: task.workPersonal,
            isLocked: false,
            color: .blue,
            source: .user,
            duration: duration
        )
    }
}

extension LifeTask {
    static func mockTask(
        id: UUID = UUID(),
        title: String = "Mock Task",
        workPersonal: WorkPersonalType = .work,
        priority: TaskPriority = .medium
    ) -> LifeTask {
        return LifeTask(
            id: id,
            blobId: nil,
            title: title,
            description: "Mock task description",
            priority: priority,
            status: .todo,
            dueDate: nil,
            estimatedDuration: 30,
            workPersonal: workPersonal,
            projectId: nil,
            areaId: nil,
            resourceId: nil,
            isFocus: false,
            isArchived: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            completedAt: nil,
            archivedAt: nil,
            deletedAt: nil
        )
    }
} 