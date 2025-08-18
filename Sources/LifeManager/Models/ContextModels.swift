//
// ContextModels.swift
// LifeManager
//
// Model types for the refactored context memory system
//

import Foundation

// MARK: - Context Item

struct ContextItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let category: PARACategory
    let subcategory: String?
    let tags: [String]
    let workPersonal: WorkPersonalType
    let priority: TaskPriority
    let timestamp: Date
    let isCompleted: Bool
    
    init(from paraItem: PARAItem) {
        self.id = UUID()
        self.title = paraItem.title
        self.content = paraItem.content
        self.category = paraItem.category
        self.subcategory = nil
        self.tags = paraItem.tags
        self.workPersonal = paraItem.workPersonal
        self.priority = paraItem.priority
        self.timestamp = paraItem.createdAt
        self.isCompleted = paraItem.isCompleted
    }
    
    init(from record: ContextWindowRecord) {
        self.id = record.id
        self.title = record.title
        self.content = record.content
        self.category = PARACategory(rawValue: record.category) ?? .resource
        self.subcategory = record.subcategory
        self.tags = record.tags
        self.workPersonal = WorkPersonalType(rawValue: record.workPersonal) ?? .personal
        self.priority = TaskPriority(rawValue: record.priority) ?? .medium
        self.timestamp = record.timestamp
        self.isCompleted = record.isCompleted
    }
}

// MARK: - Context Window Record

struct ContextWindowRecord: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let content: String
    let category: String
    let subcategory: String?
    let workPersonal: String
    let tags: [String]
    let priority: Int
    let timestamp: Date
    let isCompleted: Bool
}

// MARK: - Daily Summary

class DailySummary: ObservableObject, Identifiable {
    let id = UUID()
    let date: Date
    @Published var projectsActive: [String] = []
    @Published var areasActive: [String] = []
    @Published var tasksCompleted: Int = 0
    @Published var resourcesAdded: Int = 0
    @Published var topTags: [String] = []
    @Published var totalItems: Int = 0
    
    init(date: Date) {
        self.date = date
    }
    
    init(from record: DailySummaryRecord) {
        self.date = record.date
        self.projectsActive = record.projectsActive
        self.areasActive = record.areasActive
        self.tasksCompleted = record.tasksCompleted
        self.resourcesAdded = record.resourcesAdded
        self.topTags = record.topTags
        self.totalItems = record.totalItems
    }
    
    func addItems(_ items: [ContextItem]) {
        for item in items {
            switch item.category {
            case .project:
                if !projectsActive.contains(item.title) {
                    projectsActive.append(item.title)
                }
            case .area:
                if !areasActive.contains(item.title) {
                    areasActive.append(item.title)
                }
            case .resource:
                resourcesAdded += 1
            case .archive:
                break
            }
            
            if item.isCompleted {
                tasksCompleted += 1
            }
        }
        
        totalItems += items.count
        updateTopTags(from: items)
    }
    
    private func updateTopTags(from items: [ContextItem]) {
        let allTags = items.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags, by: { $0 }).mapValues { $0.count }
        topTags = tagCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
}

// MARK: - Daily Summary Record

struct DailySummaryRecord: Codable {
    let id: UUID
    let userId: UUID
    let date: Date
    let projectsActive: [String]
    let areasActive: [String]
    let tasksCompleted: Int
    let resourcesAdded: Int
    let topTags: [String]
    let totalItems: Int
    
    init(from summary: DailySummary) {
        self.id = summary.id
        self.userId = SupabaseService.shared.currentUserId ?? UUID()
        self.date = summary.date
        self.projectsActive = summary.projectsActive
        self.areasActive = summary.areasActive
        self.tasksCompleted = summary.tasksCompleted
        self.resourcesAdded = summary.resourcesAdded
        self.topTags = summary.topTags
        self.totalItems = summary.totalItems
    }
}

// MARK: - Weekly Summary

struct WeeklySummary: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let dailySummaries: [DailySummary]
    
    init(weekStartDate: Date, dailySummaries: [DailySummary] = []) {
        self.weekStartDate = weekStartDate
        self.dailySummaries = dailySummaries
    }
    
    var topProjects: [String] {
        let allProjects = dailySummaries.flatMap { $0.projectsActive }
        return Array(Set(allProjects)).prefix(5).map { String($0) }
    }
    
    var topAreas: [String] {
        let allAreas = dailySummaries.flatMap { $0.areasActive }
        return Array(Set(allAreas)).prefix(5).map { String($0) }
    }
    
    var totalTasks: Int {
        return dailySummaries.reduce(0) { $0 + $1.tasksCompleted }
    }
    
    var workPersonalRatio: String {
        return "60% work, 40% personal"
    }
    
    var keyThemes: [String] {
        let allTags = dailySummaries.flatMap { $0.topTags }
        return Array(Set(allTags)).prefix(3).map { String($0) }
    }
}

// MARK: - Monthly Summary

struct MonthlySummary: Identifiable {
    let id = UUID()
    let monthStartDate: Date
    let weeklySummaries: [WeeklySummary]
    
    init(monthStartDate: Date, weeklySummaries: [WeeklySummary] = []) {
        self.monthStartDate = monthStartDate
        self.weeklySummaries = weeklySummaries
    }
    
    var majorProjects: [String] {
        let allProjects = weeklySummaries.flatMap { $0.topProjects }
        return Array(Set(allProjects)).prefix(3).map { String($0) }
    }
    
    var focusAreas: [String] {
        let allAreas = weeklySummaries.flatMap { $0.topAreas }
        return Array(Set(allAreas)).prefix(3).map { String($0) }
    }
    
    var productivityTrends: String {
        return "Trending upward"
    }
    
    var goalProgress: String {
        return "75% on track"
    }
}

// MARK: - Processing Context

struct ProcessingContext {
    let recentItems: [ContextItem]
    let dailySummaries: [DailySummary]
    let weeklySummaries: [WeeklySummary]
    let monthlySummaries: [MonthlySummary]
    let contextStats: ContextStats
    let timestamp: Date
}

// MARK: - Context Stats

class ContextStats: ObservableObject {
    @Published var projectsActive: [String] = []
    @Published var areasActive: [String] = []
    @Published var tasksCompleted: Int = 0
    @Published var resourcesAdded: Int = 0
    @Published var topTags: [String] = []
    @Published var totalItems: Int = 0
    
    init() {}
    
    init(projectsActive: [String], areasActive: [String], tasksCompleted: Int, 
         resourcesAdded: Int, topTags: [String], totalItems: Int) {
        self.projectsActive = projectsActive
        self.areasActive = areasActive
        self.tasksCompleted = tasksCompleted
        self.resourcesAdded = resourcesAdded
        self.topTags = topTags
        self.totalItems = totalItems
    }
}