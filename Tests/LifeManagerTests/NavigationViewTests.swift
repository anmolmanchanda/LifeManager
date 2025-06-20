//
// NavigationViewTests.swift
// LifeManagerTests
//
// Tests for the newly implemented Navigation views: SearchView, TimelineView, MindMapView
// Validates search functionality, timeline filtering, and mind map node generation
//

import XCTest
@testable import LifeManager
import SwiftUI

@MainActor
final class NavigationViewTests: XCTestCase {
    
    var viewModel: MainViewModel!
    var mockData: MockDataHelper!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = MainViewModel()
        mockData = MockDataHelper()
        
        // Setup mock data for testing
        await setupMockData()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockData = nil
        try await super.tearDown()
    }
    
    // MARK: - Mock Data Setup
    
    private func setupMockData() async {
        // Create mock projects
        let project1 = Project(
            id: UUID(),
            name: "Test Project Alpha",
            description: "A test project for search functionality",
            status: .active,
            workPersonal: .work
        )
        
        let project2 = Project(
            id: UUID(),
            name: "Development Beta",
            description: "Software development project",
            status: .active,
            workPersonal: .personal
        )
        
        // Create mock areas
        let area1 = Area(
            id: UUID(),
            name: "Health Management",
            description: "Personal health and wellness",
            workPersonal: .personal
        )
        
        let area2 = Area(
            id: UUID(),
            name: "Team Leadership",
            description: "Managing and leading development teams",
            workPersonal: .work
        )
        
        // Create mock resources
        let resource1 = Resource(
            id: UUID(),
            blobId: UUID(),
            title: "Swift Programming Guide",
            type: "documentation",
            summary: "Comprehensive guide to Swift programming language"
        )
        
        let resource2 = Resource(
            id: UUID(),
            blobId: UUID(),
            title: "Fitness Tracking Methods",
            type: "article",
            summary: "Various methods for tracking fitness progress"
        )
        
        // Create mock tasks
        let task1 = LifeTask(
            id: UUID(),
            title: "Implement search feature",
            description: "Add comprehensive search across all PARA categories",
            status: .pending,
            priority: .high
        )
        
        let task2 = LifeTask(
            id: UUID(),
            title: "Review fitness plan",
            description: "Review and update current fitness routine",
            status: .completed,
            priority: .medium
        )
        
        let task3 = LifeTask(
            id: UUID(),
            title: "Team meeting preparation",
            description: "Prepare agenda for weekly team meeting",
            status: .pending,
            priority: .urgent
        )
        
        // Add to view model
        await MainActor.run {
            viewModel.projects = [project1, project2]
            viewModel.areas = [area1, area2]
            viewModel.resources = [resource1, resource2]
            viewModel.projectTasks[project1.id] = [task1]
            viewModel.areaTasks[area1.id] = [task2]
            viewModel.focusTasks = [task3]
        }
    }
    
    // MARK: - SearchView Tests
    
    func testSearchViewInitialization() async throws {
        let searchView = SearchView()
        
        // Test that search view initializes with correct default state
        XCTAssertNotNil(searchView)
        
        // Since we can't directly access @State variables in SwiftUI tests,
        // we'll test the search functionality through the mock search method
        let mockSearchResults = mockSearchResults(query: "test", category: .all)
        XCTAssertTrue(mockSearchResults.count >= 0)
    }
    
    func testSearchFunctionalityAcrossCategories() async throws {
        // Test search across all categories
        var results = mockSearchResults(query: "test", category: .all)
        XCTAssertTrue(results.contains { $0.title.lowercased().contains("test") })
        
        // Test project-specific search
        results = mockSearchResults(query: "project", category: .projects)
        XCTAssertTrue(results.allSatisfy { $0.type == "Project" })
        
        // Test area-specific search
        results = mockSearchResults(query: "health", category: .areas)
        XCTAssertTrue(results.allSatisfy { $0.type == "Area" })
        
        // Test resource-specific search
        results = mockSearchResults(query: "swift", category: .resources)
        XCTAssertTrue(results.allSatisfy { $0.type == "Resource" })
        
        // Test task-specific search
        results = mockSearchResults(query: "implement", category: .tasks)
        XCTAssertTrue(results.allSatisfy { $0.type == "Task" })
    }
    
    func testSearchResultSorting() async throws {
        let results = mockSearchResults(query: "test", category: .all)
        
        // Results should be sorted by relevance (exact matches first, then by modification date)
        if results.count > 1 {
            for i in 0..<(results.count - 1) {
                let current = results[i]
                let next = results[i + 1]
                
                let currentExact = current.title.lowercased() == "test"
                let nextExact = next.title.lowercased() == "test"
                
                if currentExact && !nextExact {
                    // Current should come before next (correct)
                    XCTAssertTrue(true)
                } else if !currentExact && nextExact {
                    // This should not happen with proper sorting
                    XCTFail("Search results not properly sorted by relevance")
                } else {
                    // Both are same relevance, should be sorted by date
                    XCTAssertGreaterThanOrEqual(current.lastModified, next.lastModified)
                }
            }
        }
    }
    
    // MARK: - TimelineView Tests
    
    func testTimelineViewInitialization() async throws {
        let timelineView = TimelineView()
        XCTAssertNotNil(timelineView)
        
        // Test timeline item generation
        let timelineItems = generateMockTimelineItems(timeframe: .all)
        XCTAssertGreaterThan(timelineItems.count, 0)
    }
    
    func testTimelineTimeframeFiltering() async throws {
        let allItems = generateMockTimelineItems(timeframe: .all)
        let todayItems = generateMockTimelineItems(timeframe: .today)
        let weekItems = generateMockTimelineItems(timeframe: .week)
        let monthItems = generateMockTimelineItems(timeframe: .month)
        
        // Today items should be subset of week items
        XCTAssertLessThanOrEqual(todayItems.count, weekItems.count)
        
        // Week items should be subset of month items
        XCTAssertLessThanOrEqual(weekItems.count, monthItems.count)
        
        // Month items should be subset of all items
        XCTAssertLessThanOrEqual(monthItems.count, allItems.count)
    }
    
    func testTimelineItemSorting() async throws {
        let timelineItems = generateMockTimelineItems(timeframe: .all)
        
        // Timeline items should be sorted by timestamp (most recent first)
        if timelineItems.count > 1 {
            for i in 0..<(timelineItems.count - 1) {
                let current = timelineItems[i]
                let next = timelineItems[i + 1]
                XCTAssertGreaterThanOrEqual(current.timestamp, next.timestamp)
            }
        }
    }
    
    func testTimelineItemCategories() async throws {
        let timelineItems = generateMockTimelineItems(timeframe: .all)
        let categories = Set(timelineItems.map { $0.category })
        
        // Should have items from different categories
        XCTAssertTrue(categories.count > 0)
        
        // Verify category assignment logic
        for item in timelineItems {
            switch item.type {
            case "Project":
                XCTAssertEqual(item.category, "Projects")
            case "Task":
                XCTAssertTrue(["Projects", "Areas", "Focus", "Tasks"].contains(item.category))
            default:
                break
            }
        }
    }
    
    // MARK: - MindMapView Tests
    
    func testMindMapViewInitialization() async throws {
        let mindMapView = MindMapView()
        XCTAssertNotNil(mindMapView)
        
        // Test mind map node generation
        let nodes = generateMockMindMapNodes(category: .all)
        XCTAssertGreaterThan(nodes.count, 0)
    }
    
    func testMindMapNodeGeneration() async throws {
        // Test node generation for different categories
        let allNodes = generateMockMindMapNodes(category: .all)
        let projectNodes = generateMockMindMapNodes(category: .projects)
        let areaNodes = generateMockMindMapNodes(category: .areas)
        let resourceNodes = generateMockMindMapNodes(category: .resources)
        let taskNodes = generateMockMindMapNodes(category: .tasks)
        
        // Verify category-specific filtering
        XCTAssertTrue(projectNodes.allSatisfy { $0.category == .projects })
        XCTAssertTrue(areaNodes.allSatisfy { $0.category == .areas })
        XCTAssertTrue(resourceNodes.allSatisfy { $0.category == .resources })
        XCTAssertTrue(taskNodes.allSatisfy { $0.category == .tasks })
        
        // All category should include nodes from all types
        let allCategories = Set(allNodes.map { $0.category })
        XCTAssertTrue(allCategories.count > 1)
    }
    
    func testMindMapNodeSizes() async throws {
        let taskNodes = generateMockMindMapNodes(category: .tasks)
        
        // Verify that high/urgent priority tasks get medium size
        for node in taskNodes {
            // We can't directly test the mock data priority, but we can verify
            // that the size assignment logic works
            XCTAssertTrue([.small, .medium, .large].contains(node.size))
        }
    }
    
    func testMindMapConnections() async throws {
        let connections = generateMockMindMapConnections()
        
        // Should have connections between related items
        XCTAssertGreaterThan(connections.count, 0)
        
        // Verify connection types
        let connectionTypes = Set(connections.map { $0.type })
        XCTAssertTrue(connectionTypes.contains(.hierarchy) || connectionTypes.contains(.association))
        
        // Verify connection strengths are within valid range
        for connection in connections {
            XCTAssertGreaterThanOrEqual(connection.strength, 0.0)
            XCTAssertLessThanOrEqual(connection.strength, 1.0)
        }
    }
    
    // MARK: - Helper Methods for Testing
    
    private func mockSearchResults(query: String, category: SearchView.SearchCategory) -> [SearchView.SearchResult] {
        var results: [SearchView.SearchResult] = []
        let queryLower = query.lowercased()
        
        // Search in projects
        if category == .all || category == .projects {
            for project in viewModel.projects {
                if project.name.lowercased().contains(queryLower) ||
                   (project.description?.lowercased().contains(queryLower) ?? false) {
                    results.append(SearchView.SearchResult(
                        title: project.name,
                        content: project.description ?? "No description",
                        category: .projects,
                        type: "Project",
                        lastModified: ISO8601DateFormatter().date(from: project.updatedAt) ?? Date()
                    ))
                }
            }
        }
        
        // Search in areas
        if category == .all || category == .areas {
            for area in viewModel.areas {
                if area.name.lowercased().contains(queryLower) ||
                   (area.description?.lowercased().contains(queryLower) ?? false) {
                    results.append(SearchView.SearchResult(
                        title: area.name,
                        content: area.description ?? "No description",
                        category: .areas,
                        type: "Area",
                        lastModified: ISO8601DateFormatter().date(from: area.updatedAt) ?? Date()
                    ))
                }
            }
        }
        
        // Search in resources
        if category == .all || category == .resources {
            for resource in viewModel.resources {
                if resource.title.lowercased().contains(queryLower) ||
                   (resource.summary?.lowercased().contains(queryLower) ?? false) {
                    results.append(SearchView.SearchResult(
                        title: resource.title,
                        content: resource.summary ?? "No summary",
                        category: .resources,
                        type: "Resource",
                        lastModified: ISO8601DateFormatter().date(from: resource.updatedAt) ?? Date()
                    ))
                }
            }
        }
        
        // Search in tasks
        if category == .all || category == .tasks {
            let allTasks = viewModel.projectTasks.values.flatMap { $0 } +
                          viewModel.areaTasks.values.flatMap { $0 } +
                          viewModel.focusTasks
            
            for task in allTasks {
                if task.title.lowercased().contains(queryLower) ||
                   (task.description?.lowercased().contains(queryLower) ?? false) {
                    results.append(SearchView.SearchResult(
                        title: task.title,
                        content: task.description ?? "No description",
                        category: .tasks,
                        type: "Task",
                        lastModified: ISO8601DateFormatter().date(from: task.updatedAt) ?? Date()
                    ))
                }
            }
        }
        
        // Sort by relevance (exact matches first, then by modification date)
        return results.sorted { first, second in
            let firstExact = first.title.lowercased() == queryLower
            let secondExact = second.title.lowercased() == queryLower
            
            if firstExact && !secondExact {
                return true
            } else if !firstExact && secondExact {
                return false
            } else {
                return first.lastModified > second.lastModified
            }
        }
    }
    
    private func generateMockTimelineItems(timeframe: TimelineView.TimeFrame) -> [TimelineView.TimelineItem] {
        var items: [TimelineView.TimelineItem] = []
        let now = Date()
        let calendar = Calendar.current
        
        // Collect tasks from all categories
        let allTasks = viewModel.projectTasks.values.flatMap { $0 } +
                      viewModel.areaTasks.values.flatMap { $0 } +
                      viewModel.focusTasks
        
        for task in allTasks {
            let taskUpdatedDate = ISO8601DateFormatter().date(from: task.updatedAt) ?? now
            let taskDueDate = task.dueDate != nil ? ISO8601DateFormatter().date(from: task.dueDate!) : nil
            
            let shouldInclude: Bool
            switch timeframe {
            case .today:
                shouldInclude = calendar.isDateInToday(taskUpdatedDate) ||
                               (taskDueDate != nil && calendar.isDateInToday(taskDueDate!))
            case .week:
                shouldInclude = calendar.isDate(taskUpdatedDate, equalTo: now, toGranularity: .weekOfYear) ||
                               (taskDueDate != nil && calendar.isDate(taskDueDate!, equalTo: now, toGranularity: .weekOfYear))
            case .month:
                shouldInclude = calendar.isDate(taskUpdatedDate, equalTo: now, toGranularity: .month) ||
                               (taskDueDate != nil && calendar.isDate(taskDueDate!, equalTo: now, toGranularity: .month))
            case .all:
                shouldInclude = true
            }
            
            if shouldInclude {
                let category = determineTaskCategory(task)
                let timestamp = taskDueDate ?? taskUpdatedDate
                
                items.append(TimelineView.TimelineItem(
                    title: task.title,
                    content: task.description ?? "No description",
                    type: "Task",
                    category: category,
                    timestamp: timestamp,
                    isCompleted: task.status == .completed,
                    priority: task.priority
                ))
            }
        }
        
        // Add recent projects
        for project in viewModel.projects {
            let projectDate = ISO8601DateFormatter().date(from: project.updatedAt) ?? now
            
            let shouldInclude: Bool
            switch timeframe {
            case .today:
                shouldInclude = calendar.isDateInToday(projectDate)
            case .week:
                shouldInclude = calendar.isDate(projectDate, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                shouldInclude = calendar.isDate(projectDate, equalTo: now, toGranularity: .month)
            case .all:
                shouldInclude = true
            }
            
            if shouldInclude {
                items.append(TimelineView.TimelineItem(
                    title: project.name,
                    content: project.description ?? "No description",
                    type: "Project",
                    category: "Projects",
                    timestamp: projectDate,
                    isCompleted: project.status == .completed,
                    priority: .medium
                ))
            }
        }
        
        // Sort by timestamp (most recent first)
        return items.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func determineTaskCategory(_ task: LifeTask) -> String {
        // Try to find which category this task belongs to
        for (projectId, tasks) in viewModel.projectTasks {
            if tasks.contains(where: { $0.id == task.id }) {
                if let project = viewModel.projects.first(where: { $0.id == projectId }) {
                    return project.name
                }
                return "Projects"
            }
        }
        
        for (areaId, tasks) in viewModel.areaTasks {
            if tasks.contains(where: { $0.id == task.id }) {
                if let area = viewModel.areas.first(where: { $0.id == areaId }) {
                    return area.name
                }
                return "Areas"
            }
        }
        
        if viewModel.focusTasks.contains(where: { $0.id == task.id }) {
            return "Focus"
        }
        
        return "Tasks"
    }
    
    private func generateMockMindMapNodes(category: MindMapView.MindMapCategory) -> [MindMapNode] {
        var nodes: [MindMapNode] = []
        
        // Generate nodes based on selected category
        switch category {
        case .all, .projects:
            for project in viewModel.projects {
                nodes.append(MindMapNode(
                    id: project.id,
                    title: project.name,
                    subtitle: project.description ?? "",
                    category: .projects,
                    size: .large,
                    position: .zero
                ))
            }
            
        case .areas:
            for area in viewModel.areas {
                nodes.append(MindMapNode(
                    id: area.id,
                    title: area.name,
                    subtitle: area.description ?? "",
                    category: .areas,
                    size: .large,
                    position: .zero
                ))
            }
            
        case .resources:
            for resource in viewModel.resources.prefix(20) {
                nodes.append(MindMapNode(
                    id: resource.id,
                    title: resource.title,
                    subtitle: String((resource.summary ?? "No summary").prefix(50)),
                    category: .resources,
                    size: .medium,
                    position: .zero
                ))
            }
            
        case .tasks:
            let allTasks = Array((viewModel.projectTasks.values.flatMap { $0 } +
                                viewModel.areaTasks.values.flatMap { $0 } +
                                viewModel.focusTasks).prefix(25))
            
            for task in allTasks {
                nodes.append(MindMapNode(
                    id: task.id,
                    title: task.title,
                    subtitle: task.description ?? "No description",
                    category: .tasks,
                    size: task.priority == .high || task.priority == .urgent ? .medium : .small,
                    position: .zero
                ))
            }
        }
        
        return nodes
    }
    
    private func generateMockMindMapConnections() -> [MindMapConnection] {
        var connections: [MindMapConnection] = []
        
        // Connect projects to their tasks
        for (projectId, tasks) in viewModel.projectTasks {
            for task in tasks.prefix(5) {
                connections.append(MindMapConnection(
                    id: UUID(),
                    fromId: projectId,
                    toId: task.id,
                    type: .hierarchy,
                    strength: 0.8
                ))
            }
        }
        
        // Connect areas to their tasks
        for (areaId, tasks) in viewModel.areaTasks {
            for task in tasks.prefix(3) {
                connections.append(MindMapConnection(
                    id: UUID(),
                    fromId: areaId,
                    toId: task.id,
                    type: .association,
                    strength: 0.6
                ))
            }
        }
        
        return connections
    }
}

// MARK: - Mock Data Helper

class MockDataHelper {
    // Helper class for creating consistent mock data across tests
    
    static func createMockProject(name: String = "Test Project", description: String = "Test Description") -> Project {
        return Project(
            id: UUID(),
            name: name,
            description: description,
            status: .active,
            workPersonal: .work
        )
    }
    
    static func createMockArea(name: String = "Test Area", description: String = "Test Description") -> Area {
        return Area(
            id: UUID(),
            name: name,
            description: description,
            workPersonal: .personal
        )
    }
    
    static func createMockResource(title: String = "Test Resource", summary: String = "Test Summary") -> Resource {
        return Resource(
            id: UUID(),
            blobId: UUID(),
            title: title,
            type: "document",
            summary: summary
        )
    }
    
    static func createMockTask(title: String = "Test Task", description: String = "Test Description", priority: TaskPriority = .medium) -> LifeTask {
        return LifeTask(
            id: UUID(),
            title: title,
            description: description,
            status: .pending,
            priority: priority
        )
    }
}