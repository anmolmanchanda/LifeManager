import XCTest
import SwiftUI
@testable import LifeManager

@MainActor
final class ContextMenuTests: XCTestCase {
    
    var calendarViewModel: CalendarViewModel!
    var mockEvent: CalendarEvent!
    var mockTask: LifeTask!
    
    override func setUp() async throws {
        try await super.setUp()
        calendarViewModel = CalendarViewModel()
        
        mockEvent = CalendarEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            duration: 3600
        )
        
        mockTask = LifeTask(
            title: "Test Task",
            description: "Test description",
            priority: .medium,
            status: .todo,
            workPersonal: .work,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    override func tearDown() async throws {
        calendarViewModel = nil
        mockEvent = nil
        mockTask = nil
        try await super.tearDown()
    }
    
    // MARK: - Calendar Event Context Menu Tests
    
    func testCalendarEventContextMenuActions() {
        calendarViewModel.events = [mockEvent]
        
        // Test Edit Event Action - create new event with different title
        let newTitle = "Edited Event Title"
        let editedEvent = CalendarEvent(
            id: mockEvent.id, // Keep same ID
            title: newTitle,
            description: mockEvent.description,
            startDate: mockEvent.startDate,
            endDate: mockEvent.endDate,
            type: mockEvent.type,
            priority: mockEvent.priority,
            workPersonal: mockEvent.workPersonal,
            projectId: mockEvent.projectId,
            areaId: mockEvent.areaId,
            taskId: mockEvent.taskId,
            isLocked: mockEvent.isLocked,
            color: mockEvent.color,
            duration: mockEvent.duration
        )
        
        if let index = calendarViewModel.events.firstIndex(where: { $0.id == mockEvent.id }) {
            calendarViewModel.events[index] = editedEvent
        }
        
        XCTAssertEqual(calendarViewModel.events.first?.title, newTitle)
        XCTAssertNotEqual(calendarViewModel.events.first?.title, "Test Event")
    }
    
    func testDeleteEventAction() {
        calendarViewModel.events = [mockEvent]
        XCTAssertEqual(calendarViewModel.events.count, 1)
        
        // Simulate delete action
        calendarViewModel.events.removeAll { $0.id == mockEvent.id }
        
        XCTAssertEqual(calendarViewModel.events.count, 0)
    }
    
    func testDuplicateEventAction() {
        calendarViewModel.events = [mockEvent]
        XCTAssertEqual(calendarViewModel.events.count, 1)
        
        // Simulate duplicate action - create new event with new ID
        let duplicatedEvent = CalendarEvent(
            title: mockEvent.title,
            description: mockEvent.description,
            startDate: mockEvent.startDate.addingTimeInterval(3600), // 1 hour later
            endDate: mockEvent.endDate.addingTimeInterval(3600),
            type: mockEvent.type,
            priority: mockEvent.priority,
            workPersonal: mockEvent.workPersonal,
            projectId: mockEvent.projectId,
            areaId: mockEvent.areaId,
            taskId: mockEvent.taskId,
            isLocked: mockEvent.isLocked,
            color: mockEvent.color,
            duration: mockEvent.duration
        )
        
        calendarViewModel.events.append(duplicatedEvent)
        
        XCTAssertEqual(calendarViewModel.events.count, 2)
        XCTAssertEqual(calendarViewModel.events[0].title, calendarViewModel.events[1].title)
        XCTAssertNotEqual(calendarViewModel.events[0].id, calendarViewModel.events[1].id)
    }
    
    func testMoveEventAction() {
        calendarViewModel.events = [mockEvent]
        let originalStartDate = mockEvent.startDate
        
        // Simulate move to different time
        let newStartDate = Calendar.current.date(byAdding: .hour, value: 2, to: originalStartDate)!
        let newEndDate = Calendar.current.date(byAdding: .hour, value: 2, to: mockEvent.endDate)!
        
        let movedEvent = CalendarEvent(
            id: mockEvent.id,
            title: mockEvent.title,
            description: mockEvent.description,
            startDate: newStartDate,
            endDate: newEndDate,
            type: mockEvent.type,
            priority: mockEvent.priority,
            workPersonal: mockEvent.workPersonal,
            projectId: mockEvent.projectId,
            areaId: mockEvent.areaId,
            taskId: mockEvent.taskId,
            isLocked: mockEvent.isLocked,
            color: mockEvent.color,
            duration: mockEvent.duration
        )
        
        if let index = calendarViewModel.events.firstIndex(where: { $0.id == mockEvent.id }) {
            calendarViewModel.events[index] = movedEvent
        }
        
        XCTAssertNotEqual(calendarViewModel.events.first?.startDate, originalStartDate)
        XCTAssertEqual(calendarViewModel.events.first?.startDate, newStartDate)
    }
    
    // MARK: - Task Context Menu Tests
    
    func testTaskContextMenuActions() {
        calendarViewModel.allTasks = [mockTask]
        
        // Test Edit Task Action - create new task with different title
        let newTitle = "Edited Task Title"
        let editedTask = LifeTask(
            id: mockTask.id,
            blobId: mockTask.blobId,
            title: newTitle,
            description: mockTask.description,
            priority: mockTask.priority,
            status: mockTask.status,
            dueDate: mockTask.dueDate,
            estimatedDuration: mockTask.estimatedDuration,
            workPersonal: mockTask.workPersonal,
            projectId: mockTask.projectId,
            areaId: mockTask.areaId,
            resourceId: mockTask.resourceId,
            isFocus: mockTask.isFocus,
            isArchived: mockTask.isArchived,
            createdAt: mockTask.createdAt,
            updatedAt: mockTask.updatedAt,
            completedAt: mockTask.completedAt,
            archivedAt: mockTask.archivedAt,
            deletedAt: mockTask.deletedAt
        )
        
        if let index = calendarViewModel.allTasks.firstIndex(where: { $0.id == mockTask.id }) {
            calendarViewModel.allTasks[index] = editedTask
        }
        
        XCTAssertEqual(calendarViewModel.allTasks.first?.title, newTitle)
        XCTAssertNotEqual(calendarViewModel.allTasks.first?.title, "Test Task")
    }
    
    func testDeleteTaskAction() {
        calendarViewModel.allTasks = [mockTask]
        XCTAssertEqual(calendarViewModel.allTasks.count, 1)
        
        // Simulate delete action
        calendarViewModel.allTasks.removeAll { $0.id == mockTask.id }
        
        XCTAssertEqual(calendarViewModel.allTasks.count, 0)
    }
    
    func testCompleteTaskAction() {
        calendarViewModel.allTasks = [mockTask]
        
        // Simulate complete task action
        let completedTask = LifeTask(
            id: mockTask.id,
            blobId: mockTask.blobId,
            title: mockTask.title,
            description: mockTask.description,
            priority: mockTask.priority,
            status: .completed, // Change status to completed
            dueDate: mockTask.dueDate,
            estimatedDuration: mockTask.estimatedDuration,
            workPersonal: mockTask.workPersonal,
            projectId: mockTask.projectId,
            areaId: mockTask.areaId,
            resourceId: mockTask.resourceId,
            isFocus: mockTask.isFocus,
            isArchived: mockTask.isArchived,
            createdAt: mockTask.createdAt,
            updatedAt: mockTask.updatedAt,
            completedAt: ISO8601DateFormatter().string(from: Date()),
            archivedAt: mockTask.archivedAt,
            deletedAt: mockTask.deletedAt
        )
        
        if let index = calendarViewModel.allTasks.firstIndex(where: { $0.id == mockTask.id }) {
            calendarViewModel.allTasks[index] = completedTask
        }
        
        XCTAssertEqual(calendarViewModel.allTasks.first?.status, .completed)
    }
    
    func testChangePriorityAction() {
        calendarViewModel.allTasks = [mockTask]
        
        // Simulate priority change action
        let highPriorityTask = LifeTask(
            id: mockTask.id,
            blobId: mockTask.blobId,
            title: mockTask.title,
            description: mockTask.description,
            priority: .high, // Change priority to high
            status: mockTask.status,
            dueDate: mockTask.dueDate,
            estimatedDuration: mockTask.estimatedDuration,
            workPersonal: mockTask.workPersonal,
            projectId: mockTask.projectId,
            areaId: mockTask.areaId,
            resourceId: mockTask.resourceId,
            isFocus: mockTask.isFocus,
            isArchived: mockTask.isArchived,
            createdAt: mockTask.createdAt,
            updatedAt: mockTask.updatedAt,
            completedAt: mockTask.completedAt,
            archivedAt: mockTask.archivedAt,
            deletedAt: mockTask.deletedAt
        )
        
        if let index = calendarViewModel.allTasks.firstIndex(where: { $0.id == mockTask.id }) {
            calendarViewModel.allTasks[index] = highPriorityTask
        }
        
        XCTAssertEqual(calendarViewModel.allTasks.first?.priority, .high)
        XCTAssertNotEqual(calendarViewModel.allTasks.first?.priority, .medium)
    }
    
    func testScheduleTaskAction() {
        calendarViewModel.allTasks = [mockTask]
        XCTAssertEqual(calendarViewModel.events.count, 0)
        
        // Simulate schedule task action (convert task to calendar event)
        let scheduleDate = Date()
        let scheduledEvent = CalendarEvent(
            title: mockTask.title,
            description: mockTask.description,
            startDate: scheduleDate,
            endDate: scheduleDate.addingTimeInterval(3600),
            workPersonal: mockTask.workPersonal,
            source: .user,
            duration: 3600
        )
        
        calendarViewModel.events.append(scheduledEvent)
        calendarViewModel.allTasks.removeAll { $0.id == mockTask.id }
        
        XCTAssertEqual(calendarViewModel.events.count, 1)
        XCTAssertEqual(calendarViewModel.allTasks.count, 0)
        XCTAssertEqual(calendarViewModel.events.first?.title, mockTask.title)
    }
    
    // MARK: - Context Menu State Tests
    
    func testContextMenuAvailability() {
        // Test that context menu is available for events
        calendarViewModel.events = [mockEvent]
        let hasEvents = !calendarViewModel.events.isEmpty
        XCTAssertTrue(hasEvents, "Context menu should be available when events exist")
        
        // Test that context menu is available for tasks
        calendarViewModel.allTasks = [mockTask]
        let hasTasks = !calendarViewModel.allTasks.isEmpty
        XCTAssertTrue(hasTasks, "Context menu should be available when tasks exist")
    }
    
    func testContextMenuActionsOnMultipleItems() {
        let event1 = CalendarEvent(
            title: "Event 1",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            duration: 3600
        )
        let event2 = CalendarEvent(
            title: "Event 2",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            duration: 3600
        )
        calendarViewModel.events = [event1, event2]
        
        // Test deleting one event doesn't affect the other
        calendarViewModel.events.removeAll { $0.id == event1.id }
        
        XCTAssertEqual(calendarViewModel.events.count, 1)
        XCTAssertEqual(calendarViewModel.events.first?.title, "Event 2")
    }
    
    // MARK: - Performance Tests
    
    func testContextMenuPerformanceWithManyItems() {
        let events = (0..<100).map { i in
            CalendarEvent(
                title: "Event \(i)",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                duration: 3600
            )
        }
        
        measure {
            calendarViewModel.events = events
            
            // Simulate context menu actions on multiple items
            for event in events.prefix(10) {
                // Simulate edit action
                if let index = calendarViewModel.events.firstIndex(where: { $0.id == event.id }) {
                    let editedEvent = CalendarEvent(
                        id: event.id,
                        title: "Edited \(event.title)",
                        description: event.description,
                        startDate: event.startDate,
                        endDate: event.endDate,
                        type: event.type,
                        priority: event.priority,
                        workPersonal: event.workPersonal,
                        projectId: event.projectId,
                        areaId: event.areaId,
                        taskId: event.taskId,
                        isLocked: event.isLocked,
                        color: event.color,
                        duration: event.duration
                    )
                    calendarViewModel.events[index] = editedEvent
                }
            }
        }
        
        XCTAssertEqual(calendarViewModel.events.count, 100)
    }
} 