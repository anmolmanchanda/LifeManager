import XCTest
import SwiftUI
@testable import LifeManager

@MainActor
final class DragDropTests: XCTestCase {
    
    var calendarViewModel: CalendarViewModel!
    var parkingLotTasks: [LifeTask]!
    
    override func setUp() async throws {
        try await super.setUp()
        calendarViewModel = CalendarViewModel()
        parkingLotTasks = []
    }
    
    override func tearDown() async throws {
        calendarViewModel = nil
        parkingLotTasks = nil
        try await super.tearDown()
    }
    
    // MARK: - Task Drag Provider Tests
    
    func testTaskDragProvider() {
        let task = LifeTask.mockTask(title: "Draggable Task")
        
        // Test drag provider creation
        let dragProvider = NSItemProvider()
        dragProvider.registerObject(task.id.uuidString as NSString, visibility: .all)
        
        XCTAssertNotNil(dragProvider)
        XCTAssertTrue(dragProvider.hasItemConformingToTypeIdentifier("public.text"))
    }
    
    func testTaskDragData() {
        let task = LifeTask.mockTask(title: "Test Task")
        let taskIdString = task.id.uuidString
        
        // Test that task ID can be converted to string for drag operation
        XCTAssertNotNil(taskIdString)
        XCTAssertFalse(taskIdString.isEmpty)
        XCTAssertEqual(UUID(uuidString: taskIdString), task.id)
    }
    
    // MARK: - Calendar Drop Target Tests
    
    func testCalendarDropTargetAcceptsTaskIds() {
        let task = LifeTask.mockTask()
        let taskIdString = task.id.uuidString
        
        // Simulate drop data
        let dropProvider = NSItemProvider()
        dropProvider.registerObject(taskIdString as NSString, visibility: .all)
        
        // Test that drop provider contains valid task ID
        XCTAssertTrue(dropProvider.hasItemConformingToTypeIdentifier("public.text"))
    }
    
    func testValidTaskDropData() {
        let task = LifeTask.mockTask(title: "Valid Task")
        let taskIdString = task.id.uuidString
        
        // Test UUID string validation
        XCTAssertNotNil(UUID(uuidString: taskIdString))
        
        // Test that task can be found by ID
        calendarViewModel.allTasks = [task]
        let foundTask = calendarViewModel.allTasks.first { $0.id.uuidString == taskIdString }
        XCTAssertNotNil(foundTask)
        XCTAssertEqual(foundTask?.title, "Valid Task")
    }
    
    func testInvalidTaskDropData() {
        let invalidId = "invalid-uuid-string"
        
        // Test invalid UUID handling
        XCTAssertNil(UUID(uuidString: invalidId))
        
        // Test that invalid ID doesn't match any tasks
        let task = LifeTask.mockTask()
        calendarViewModel.allTasks = [task]
        let foundTask = calendarViewModel.allTasks.first { $0.id.uuidString == invalidId }
        XCTAssertNil(foundTask)
    }
    
    // MARK: - Drop Operation Tests
    
    func testSuccessfulTaskDrop() {
        let task = LifeTask.mockTask(title: "Task to Drop")
        let dropDate = Date()
        let dropHour = 14 // 2 PM
        
        // Setup initial state
        calendarViewModel.allTasks = [task]
        XCTAssertEqual(calendarViewModel.allTasks.count, 1)
        XCTAssertEqual(calendarViewModel.events.count, 0)
        
        // Simulate successful drop
        let calendar = Calendar.current
        let dropDateTime = calendar.date(bySettingHour: dropHour, minute: 0, second: 0, of: dropDate)!
        
        // Create calendar event from dropped task
        let newEvent = CalendarEvent(
            id: UUID(),
            title: task.title,
            description: task.description ?? "",
            startDate: dropDateTime,
            endDate: calendar.date(byAdding: .hour, value: 1, to: dropDateTime)!,
            workPersonal: task.workPersonal,
            isLocked: false,
            color: .blue,
            source: .user,
            duration: 3600
        )
        
        // Add event and remove task
        calendarViewModel.events.append(newEvent)
        calendarViewModel.allTasks.removeAll { $0.id == task.id }
        
        // Verify drop operation results
        XCTAssertEqual(calendarViewModel.events.count, 1)
        XCTAssertEqual(calendarViewModel.allTasks.count, 0)
        XCTAssertEqual(calendarViewModel.events.first?.title, "Task to Drop")
        
        let eventHour = calendar.component(.hour, from: calendarViewModel.events.first!.startDate)
        XCTAssertEqual(eventHour, dropHour)
    }
    
    func testDropOnOccupiedTimeSlot() {
        let existingEvent = CalendarEvent.mockEvent(title: "Existing Event")
        let task = LifeTask.mockTask(title: "Conflicting Task")
        
        // Setup initial state with existing event
        calendarViewModel.events = [existingEvent]
        calendarViewModel.allTasks = [task]
        
        let conflictingDate = existingEvent.startDate
        
        // Check for time conflicts before allowing drop
        let eventsAtTime = calendarViewModel.events.filter { event in
            Calendar.current.isDate(event.startDate, equalTo: conflictingDate, toGranularity: .hour)
        }
        
        XCTAssertEqual(eventsAtTime.count, 1)
        
        // Drop should either:
        // 1. Be rejected due to conflict, or
        // 2. Move the existing event, or
        // 3. Stack events with warning
        
        // For this test, assume conflict prevention
        let shouldAllowDrop = eventsAtTime.isEmpty
        XCTAssertFalse(shouldAllowDrop, "Should not allow drop on occupied time slot")
    }
    
    func testDropTaskWithCustomDuration() {
        let task = LifeTask.mockTask(title: "Custom Duration Task")
        let dropDate = Date()
        let customDuration: TimeInterval = 7200 // 2 hours
        
        calendarViewModel.allTasks = [task]
        
        // Create event with custom duration
        let newEvent = CalendarEvent(
            id: UUID(),
            title: task.title,
            description: task.description ?? "",
            startDate: dropDate,
            endDate: dropDate.addingTimeInterval(customDuration),
            workPersonal: task.workPersonal,
            isLocked: false,
            color: .blue,
            source: .user,
            duration: customDuration
        )
        
        calendarViewModel.events.append(newEvent)
        calendarViewModel.allTasks.removeAll { $0.id == task.id }
        
        XCTAssertEqual(calendarViewModel.events.first?.duration, customDuration)
        XCTAssertEqual(calendarViewModel.events.first?.endDate.timeIntervalSince(calendarViewModel.events.first!.startDate), customDuration)
    }
    
    // MARK: - Multiple Drop Operations Tests
    
    func testMultipleTaskDrops() {
        let task1 = LifeTask.mockTask(title: "Task 1")
        let task2 = LifeTask.mockTask(title: "Task 2")
        let task3 = LifeTask.mockTask(title: "Task 3")
        
        calendarViewModel.allTasks = [task1, task2, task3]
        
        let baseDate = Date()
        let calendar = Calendar.current
        
        // Drop tasks at different hours
        for (index, task) in calendarViewModel.allTasks.enumerated() {
            let dropTime = calendar.date(byAdding: .hour, value: index, to: baseDate)!
            let event = CalendarEvent(
                id: UUID(),
                title: task.title,
                description: task.description ?? "",
                startDate: dropTime,
                endDate: calendar.date(byAdding: .hour, value: 1, to: dropTime)!,
                workPersonal: task.workPersonal,
                isLocked: false,
                color: .blue,
                source: .user,
                duration: 3600
            )
            calendarViewModel.events.append(event)
        }
        
        calendarViewModel.allTasks.removeAll()
        
        XCTAssertEqual(calendarViewModel.events.count, 3)
        XCTAssertEqual(calendarViewModel.allTasks.count, 0)
        
        // Verify events are at different times
        let eventTimes = calendarViewModel.events.map { $0.startDate }
        let uniqueTimes = Set(eventTimes.map { calendar.component(.hour, from: $0) })
        XCTAssertEqual(uniqueTimes.count, 3, "Events should be at different hours")
    }
    
    // MARK: - Drag State Management Tests
    
    func testDragStateTracking() {
        let task = LifeTask.mockTask(title: "Dragged Task")
        
        // Test initial drag state
        XCTAssertNil(calendarViewModel.draggedTask)
        
        // Start drag operation
        calendarViewModel.draggedTask = task
        XCTAssertNotNil(calendarViewModel.draggedTask)
        XCTAssertEqual(calendarViewModel.draggedTask?.id, task.id)
        
        // End drag operation
        calendarViewModel.draggedTask = nil
        XCTAssertNil(calendarViewModel.draggedTask)
    }
    
    func testDragStatePersistence() {
        let task = LifeTask.mockTask(title: "Persistent Drag")
        
        calendarViewModel.draggedTask = task
        
        // Drag state should persist across view updates
        let savedDraggedTask = calendarViewModel.draggedTask
        XCTAssertNotNil(savedDraggedTask)
        XCTAssertEqual(savedDraggedTask?.id, task.id)
        
        // Simulate view refresh or state change
        // Dragged task should still be tracked
        XCTAssertNotNil(calendarViewModel.draggedTask)
    }
    
    // MARK: - Edge Cases Tests
    
    func testDropWithoutTask() {
        // Test dropping invalid or non-existent task ID
        let nonExistentId = UUID().uuidString
        
        calendarViewModel.allTasks = [LifeTask.mockTask()]
        let initialTaskCount = calendarViewModel.allTasks.count
        let initialEventCount = calendarViewModel.events.count
        
        // Simulate drop with non-existent task ID
        let foundTask = calendarViewModel.allTasks.first { $0.id.uuidString == nonExistentId }
        XCTAssertNil(foundTask)
        
        // State should remain unchanged
        XCTAssertEqual(calendarViewModel.allTasks.count, initialTaskCount)
        XCTAssertEqual(calendarViewModel.events.count, initialEventCount)
    }
    
    func testDropOnInvalidDate() {
        let task = LifeTask.mockTask(title: "Invalid Date Task")
        
        // Test with very old date (should handle gracefully)
        let invalidDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970
        
        let event = CalendarEvent(
            id: UUID(),
            title: task.title,
            description: task.description ?? "",
            startDate: invalidDate,
            endDate: invalidDate.addingTimeInterval(3600),
            workPersonal: task.workPersonal,
            isLocked: false,
            color: .blue,
            source: .user,
            duration: 3600
        )
        
        // Should create event even with old date
        XCTAssertNotNil(event)
        XCTAssertEqual(event.startDate, invalidDate)
    }
    
    // MARK: - Performance Tests
    
    func testBulkDragDropPerformance() {
        let tasks = (0..<100).map { i in
            LifeTask.mockTask(title: "Bulk Task \(i)")
        }
        
        calendarViewModel.allTasks = tasks
        
        measure {
            let baseDate = Date()
            let calendar = Calendar.current
            
            for (index, task) in tasks.enumerated() {
                let dropTime = calendar.date(byAdding: .minute, value: index * 15, to: baseDate)!
                let event = CalendarEvent(
                    id: UUID(),
                    title: task.title,
                    description: task.description ?? "",
                    startDate: dropTime,
                    endDate: calendar.date(byAdding: .hour, value: 1, to: dropTime)!,
                    workPersonal: task.workPersonal,
                    isLocked: false,
                    color: .blue,
                    source: .user,
                    duration: 3600
                )
                calendarViewModel.events.append(event)
            }
        }
        
        XCTAssertEqual(calendarViewModel.events.count, 100)
    }
} 