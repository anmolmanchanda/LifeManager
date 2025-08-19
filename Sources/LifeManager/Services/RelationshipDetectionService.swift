//
// RelationshipDetectionService.swift
// LifeManager
//
// Implements: v2.0 "Intelligence Expansion" - Relationship Detection System
// Roadmap Reference: v2.0 Intelligence Expansion → Advanced AI Processing Pipeline
// Status: ✅ PRODUCTION - Enterprise-grade relationship detection
//
// Purpose: Detects and analyzes relationships between brain dump items
// including dependencies, hierarchies, sequences, and conflicts.
//

import Foundation

/// Enterprise-grade service for detecting relationships between brain dump items
/// Identifies dependencies, hierarchies, sequences, and conflicts
@MainActor
class RelationshipDetectionService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = RelationshipDetectionService()
    
    // MARK: - Dependencies
    private let llmService = LLMServiceCoordinator.shared
    private let semanticService = SemanticSimilarityService.shared
    private let logger = Logger.shared
    
    // MARK: - State
    @Published var isAnalyzing = false
    @Published var detectedRelationships: [ItemRelationship] = []
    
    // MARK: - Models
    enum RelationshipType: String, CaseIterable {
        case dependency = "dependency"
        case similarity = "similarity"
        case sequence = "sequence"
        case hierarchy = "hierarchy"
        case collaboration = "collaboration"
        case conflict = "conflict"
        case prerequisite = "prerequisite"
        case parentChild = "parent-child"
        case grouping = "grouping"
        case temporal = "temporal"
    }
    
    struct ItemRelationship {
        let id: UUID
        let sourceItemId: UUID
        let targetItemId: UUID
        let relationshipType: RelationshipType
        let strength: Double
        let bidirectional: Bool
        let description: String
        let evidence: [String]
        let confidence: Double
        let metadata: RelationshipMetadata
    }
    
    struct RelationshipMetadata {
        let detectedAt: Date
        let detectionMethod: DetectionMethod
        let contextFactors: [String]
        let alternativeInterpretations: [AlternativeRelationship]
    }
    
    enum DetectionMethod {
        case semantic
        case temporal
        case keyword
        case llmAnalysis
        case patternMatching
        case userDefined
    }
    
    struct AlternativeRelationship {
        let type: RelationshipType
        let probability: Double
        let reasoning: String
    }
    
    struct RelationshipGraph {
        let nodes: [RelationshipNode]
        let edges: [ItemRelationship]
        let clusters: [RelationshipCluster]
        let criticalPaths: [CriticalPath]
        let conflicts: [ConflictAnalysis]
    }
    
    struct RelationshipNode {
        let itemId: UUID
        let title: String
        let contentType: ContentType
        let incomingRelationships: [ItemRelationship]
        let outgoingRelationships: [ItemRelationship]
        let centrality: Double
    }
    
    struct RelationshipCluster {
        let id: UUID
        let memberIds: [UUID]
        let dominantRelationshipType: RelationshipType
        let cohesion: Double
        let description: String
    }
    
    struct CriticalPath {
        let pathId: UUID
        let itemSequence: [UUID]
        let totalDuration: TimeInterval?
        let bottlenecks: [UUID]
        let importance: Double
    }
    
    struct ConflictAnalysis {
        let conflictingItems: [UUID]
        let conflictType: ConflictType
        let severity: ConflictSeverity
        let resolution: String
    }
    
    enum ConflictType {
        case scheduling
        case resource
        case logical
        case priority
        case categorical
    }
    
    enum ConflictSeverity {
        case low
        case medium
        case high
        case critical
    }
    
    private init() {
        logger.info("RelationshipDetectionService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Detect relationships between brain dump items
    func detectRelationships(among items: [EnhancedBrainDumpItem]) async -> [ItemRelationship] {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        logger.info("Detecting relationships among \(items.count) items")
        
        var relationships: [ItemRelationship] = []
        
        // Method 1: Semantic similarity relationships
        let semanticRelationships = await detectSemanticRelationships(items)
        relationships.append(contentsOf: semanticRelationships)
        
        // Method 2: Temporal relationships
        let temporalRelationships = detectTemporalRelationships(items)
        relationships.append(contentsOf: temporalRelationships)
        
        // Method 3: Keyword-based relationships
        let keywordRelationships = detectKeywordRelationships(items)
        relationships.append(contentsOf: keywordRelationships)
        
        // Method 4: Category-based relationships
        let categoryRelationships = detectCategoryRelationships(items)
        relationships.append(contentsOf: categoryRelationships)
        
        // Method 5: LLM-powered deep analysis (if API available)
        if llmService.hasValidAPIKey() {
            let llmRelationships = await detectLLMRelationships(items)
            relationships.append(contentsOf: llmRelationships)
        }
        
        // Deduplicate and rank relationships
        relationships = deduplicateAndRank(relationships)
        
        // Store detected relationships
        detectedRelationships = relationships
        
        logger.success("Detected \(relationships.count) relationships")
        return relationships
    }
    
    /// Build a comprehensive relationship graph
    func buildRelationshipGraph(for items: [EnhancedBrainDumpItem]) async -> RelationshipGraph {
        logger.info("Building relationship graph for \(items.count) items")
        
        // Detect all relationships
        let relationships = await detectRelationships(among: items)
        
        // Build nodes
        let nodes = buildNodes(from: items, relationships: relationships)
        
        // Identify clusters
        let clusters = identifyClusters(nodes: nodes, relationships: relationships)
        
        // Find critical paths
        let criticalPaths = findCriticalPaths(nodes: nodes, relationships: relationships)
        
        // Analyze conflicts
        let conflicts = analyzeConflicts(nodes: nodes, relationships: relationships)
        
        return RelationshipGraph(
            nodes: nodes,
            edges: relationships,
            clusters: clusters,
            criticalPaths: criticalPaths,
            conflicts: conflicts
        )
    }
    
    /// Find dependencies for a specific item
    func findDependencies(for item: EnhancedBrainDumpItem, among items: [EnhancedBrainDumpItem]) async -> DependencyAnalysis {
        logger.debug("Finding dependencies for: \(item.title)")
        
        let relationships = await detectRelationships(among: items)
        
        let dependencies = relationships.filter {
            $0.targetItemId == item.id && 
            ($0.relationshipType == .dependency || $0.relationshipType == .prerequisite)
        }
        
        let dependents = relationships.filter {
            $0.sourceItemId == item.id && 
            ($0.relationshipType == .dependency || $0.relationshipType == .prerequisite)
        }
        
        return DependencyAnalysis(
            itemId: item.id,
            dependencies: dependencies,
            dependents: dependents,
            isBlocked: !dependencies.isEmpty,
            canStart: dependencies.isEmpty
        )
    }
    
    // MARK: - Detection Methods
    
    private func detectSemanticRelationships(_ items: [EnhancedBrainDumpItem]) async -> [ItemRelationship] {
        var relationships: [ItemRelationship] = []
        
        for i in 0..<items.count {
            let similarItems = await semanticService.findSimilarItems(for: items[i], limit: 5)
            
            for similar in similarItems {
                // Find the target item in our list
                if let targetIndex = items.firstIndex(where: { $0.id == similar.itemId }) {
                    let relationship = createRelationship(
                        from: items[i],
                        to: items[targetIndex],
                        type: determineSemanticRelationType(similar),
                        strength: Double(similar.similarity),
                        method: .semantic,
                        evidence: [similar.explanation]
                    )
                    relationships.append(relationship)
                }
            }
        }
        
        return relationships
    }
    
    private func detectTemporalRelationships(_ items: [EnhancedBrainDumpItem]) -> [ItemRelationship] {
        var relationships: [ItemRelationship] = []
        
        // Sort items by due date if available
        let itemsWithDates = items.compactMap { item -> (EnhancedBrainDumpItem, Date)? in
            guard let dateString = item.dueDate,
                  let date = ISO8601DateFormatter().date(from: dateString) else {
                return nil
            }
            return (item, date)
        }.sorted { $0.1 < $1.1 }
        
        // Detect sequences based on temporal proximity
        for i in 0..<itemsWithDates.count - 1 {
            let (item1, date1) = itemsWithDates[i]
            let (item2, date2) = itemsWithDates[i + 1]
            
            let timeDiff = date2.timeIntervalSince(date1)
            
            // If items are within 24 hours, they might be sequential
            if timeDiff <= 86400 {
                let relationship = createRelationship(
                    from: item1,
                    to: item2,
                    type: .sequence,
                    strength: 1.0 - (timeDiff / 86400),
                    method: .temporal,
                    evidence: ["Items scheduled within 24 hours"]
                )
                relationships.append(relationship)
            }
        }
        
        return relationships
    }
    
    private func detectKeywordRelationships(_ items: [EnhancedBrainDumpItem]) -> [ItemRelationship] {
        var relationships: [ItemRelationship] = []
        
        // Keywords that indicate relationships
        let dependencyKeywords = ["depends on", "requires", "needs", "after", "following"]
        let hierarchyKeywords = ["part of", "belongs to", "under", "within", "sub"]
        let conflictKeywords = ["conflicts with", "instead of", "versus", "or", "alternative"]
        
        for i in 0..<items.count {
            let content = items[i].content.lowercased()
            
            for j in 0..<items.count where i != j {
                let otherTitle = items[j].title.lowercased()
                
                // Check for dependency keywords
                for keyword in dependencyKeywords {
                    if content.contains("\(keyword) \(otherTitle)") {
                        let relationship = createRelationship(
                            from: items[i],
                            to: items[j],
                            type: .dependency,
                            strength: 0.8,
                            method: .keyword,
                            evidence: ["Contains keyword: '\(keyword)'"]
                        )
                        relationships.append(relationship)
                    }
                }
                
                // Check for hierarchy keywords
                for keyword in hierarchyKeywords {
                    if content.contains("\(keyword) \(otherTitle)") {
                        let relationship = createRelationship(
                            from: items[i],
                            to: items[j],
                            type: .hierarchy,
                            strength: 0.7,
                            method: .keyword,
                            evidence: ["Contains keyword: '\(keyword)'"]
                        )
                        relationships.append(relationship)
                    }
                }
                
                // Check for conflict keywords
                for keyword in conflictKeywords {
                    if content.contains("\(keyword) \(otherTitle)") {
                        let relationship = createRelationship(
                            from: items[i],
                            to: items[j],
                            type: .conflict,
                            strength: 0.9,
                            method: .keyword,
                            evidence: ["Contains keyword: '\(keyword)'"]
                        )
                        relationships.append(relationship)
                    }
                }
            }
        }
        
        return relationships
    }
    
    private func detectCategoryRelationships(_ items: [EnhancedBrainDumpItem]) -> [ItemRelationship] {
        var relationships: [ItemRelationship] = []
        
        // Group items by category
        let categoryGroups = Dictionary(grouping: items) { $0.paraCategory }
        
        for (category, groupItems) in categoryGroups {
            // Items in the same project likely have relationships
            let projectGroups = Dictionary(grouping: groupItems) { $0.suggestedProject ?? "none" }
            
            for (project, projectItems) in projectGroups where project != "none" && projectItems.count > 1 {
                // Create collaboration relationships within same project
                for i in 0..<projectItems.count {
                    for j in i+1..<projectItems.count {
                        let relationship = createRelationship(
                            from: projectItems[i],
                            to: projectItems[j],
                            type: .collaboration,
                            strength: 0.6,
                            method: .patternMatching,
                            evidence: ["Same project: \(project)", "Same category: \(category.rawValue)"]
                        )
                        relationships.append(relationship)
                    }
                }
            }
        }
        
        return relationships
    }
    
    private func detectLLMRelationships(_ items: [EnhancedBrainDumpItem]) async -> [ItemRelationship] {
        // Use LLM to detect complex relationships
        var relationships: [ItemRelationship] = []
        
        let itemSummaries = items.map { "[\($0.id.uuidString.prefix(8))]: \($0.title) - \($0.content.prefix(100))" }.joined(separator: "\n")
        
        let prompt = """
        Analyze these items and identify relationships between them:
        
        \(itemSummaries)
        
        For each relationship found, provide:
        1. Source item ID (first 8 characters)
        2. Target item ID (first 8 characters)
        3. Relationship type (dependency/hierarchy/sequence/conflict/collaboration)
        4. Confidence (0-1)
        5. Brief explanation
        
        Format: sourceId|targetId|type|confidence|explanation
        """
        
        do {
            let response = try await llmService.sendMessage(prompt)
            let lines = response.components(separatedBy: CharacterSet.newlines)
            
            for line in lines {
                let parts = line.components(separatedBy: "|")
                guard parts.count == 5 else { continue }
                
                // Find matching items
                let sourceId = parts[0].trimmingCharacters(in: CharacterSet.whitespaces)
                let targetId = parts[1].trimmingCharacters(in: CharacterSet.whitespaces)
                
                guard let source = items.first(where: { $0.id.uuidString.hasPrefix(sourceId) }),
                      let target = items.first(where: { $0.id.uuidString.hasPrefix(targetId) }),
                      let confidence = Double(parts[3]) else {
                    continue
                }
                
                let typeString = parts[2].lowercased()
                let type = RelationshipType(rawValue: typeString) ?? .similarity
                let explanation = parts[4]
                
                let relationship = createRelationship(
                    from: source,
                    to: target,
                    type: type,
                    strength: confidence,
                    method: .llmAnalysis,
                    evidence: [explanation]
                )
                
                relationships.append(relationship)
            }
        } catch {
            logger.error("LLM relationship detection failed: \(error)")
        }
        
        return relationships
    }
    
    // MARK: - Helper Methods
    
    private func createRelationship(
        from source: EnhancedBrainDumpItem,
        to target: EnhancedBrainDumpItem,
        type: RelationshipType,
        strength: Double,
        method: DetectionMethod,
        evidence: [String]
    ) -> ItemRelationship {
        let bidirectional = type == .similarity || type == .collaboration || type == .conflict
        
        let metadata = RelationshipMetadata(
            detectedAt: Date(),
            detectionMethod: method,
            contextFactors: [
                "Source: \(source.contentType.rawValue)",
                "Target: \(target.contentType.rawValue)"
            ],
            alternativeInterpretations: []
        )
        
        return ItemRelationship(
            id: UUID(),
            sourceItemId: source.id,
            targetItemId: target.id,
            relationshipType: type,
            strength: strength,
            bidirectional: bidirectional,
            description: "\(source.title) \(type.rawValue) \(target.title)",
            evidence: evidence,
            confidence: strength,
            metadata: metadata
        )
    }
    
    private func determineSemanticRelationType(_ match: SemanticSimilarityService.SimilarityMatch) -> RelationshipType {
        if match.similarity > 0.9 {
            return .similarity
        } else if match.relevanceType == .goalAlignment {
            return .collaboration
        } else if match.relevanceType == .categoryAlignment {
            return .grouping
        } else {
            return .similarity
        }
    }
    
    private func deduplicateAndRank(_ relationships: [ItemRelationship]) -> [ItemRelationship] {
        // Remove duplicates based on source, target, and type
        var uniqueRelationships: [String: ItemRelationship] = [:]
        
        for relationship in relationships {
            let key = "\(relationship.sourceItemId)-\(relationship.targetItemId)-\(relationship.relationshipType.rawValue)"
            
            if let existing = uniqueRelationships[key] {
                // Keep the one with higher confidence
                if relationship.confidence > existing.confidence {
                    uniqueRelationships[key] = relationship
                }
            } else {
                uniqueRelationships[key] = relationship
            }
        }
        
        return Array(uniqueRelationships.values).sorted { $0.confidence > $1.confidence }
    }
    
    private func buildNodes(from items: [EnhancedBrainDumpItem], relationships: [ItemRelationship]) -> [RelationshipNode] {
        return items.map { item in
            let incoming = relationships.filter { $0.targetItemId == item.id }
            let outgoing = relationships.filter { $0.sourceItemId == item.id }
            
            let centrality = Double(incoming.count + outgoing.count) / Double(max(relationships.count, 1))
            
            return RelationshipNode(
                itemId: item.id,
                title: item.title,
                contentType: item.contentType,
                incomingRelationships: incoming,
                outgoingRelationships: outgoing,
                centrality: centrality
            )
        }
    }
    
    private func identifyClusters(nodes: [RelationshipNode], relationships: [ItemRelationship]) -> [RelationshipCluster] {
        // Simple clustering based on strongly connected components
        var clusters: [RelationshipCluster] = []
        var visited = Set<UUID>()
        
        for node in nodes {
            guard !visited.contains(node.itemId) else { continue }
            
            var clusterMembers = Set<UUID>()
            var toVisit = [node.itemId]
            
            while !toVisit.isEmpty {
                let current = toVisit.removeFirst()
                guard !clusterMembers.contains(current) else { continue }
                
                clusterMembers.insert(current)
                visited.insert(current)
                
                // Add connected nodes
                let connected = relationships
                    .filter { ($0.sourceItemId == current || $0.targetItemId == current) && $0.strength > 0.5 }
                    .flatMap { [$0.sourceItemId, $0.targetItemId] }
                    .filter { !clusterMembers.contains($0) }
                
                toVisit.append(contentsOf: connected)
            }
            
            if clusterMembers.count > 1 {
                let cluster = RelationshipCluster(
                    id: UUID(),
                    memberIds: Array(clusterMembers),
                    dominantRelationshipType: .grouping,
                    cohesion: 0.7,
                    description: "Cluster of \(clusterMembers.count) related items"
                )
                clusters.append(cluster)
            }
        }
        
        return clusters
    }
    
    private func findCriticalPaths(nodes: [RelationshipNode], relationships: [ItemRelationship]) -> [CriticalPath] {
        // Find dependency chains
        var paths: [CriticalPath] = []
        
        // Find nodes with no incoming dependencies (potential start nodes)
        let startNodes = nodes.filter { node in
            !relationships.contains { $0.targetItemId == node.itemId && $0.relationshipType == .dependency }
        }
        
        for startNode in startNodes {
            var path = [startNode.itemId]
            var current = startNode.itemId
            
            // Follow dependency chain
            while let next = relationships.first(where: { 
                $0.sourceItemId == current && $0.relationshipType == .dependency 
            }) {
                path.append(next.targetItemId)
                current = next.targetItemId
            }
            
            if path.count > 1 {
                let criticalPath = CriticalPath(
                    pathId: UUID(),
                    itemSequence: path,
                    totalDuration: nil,
                    bottlenecks: [],
                    importance: Double(path.count) / 10.0
                )
                paths.append(criticalPath)
            }
        }
        
        return paths
    }
    
    private func analyzeConflicts(nodes: [RelationshipNode], relationships: [ItemRelationship]) -> [ConflictAnalysis] {
        let conflictRelationships = relationships.filter { $0.relationshipType == .conflict }
        
        return conflictRelationships.map { conflict in
            ConflictAnalysis(
                conflictingItems: [conflict.sourceItemId, conflict.targetItemId],
                conflictType: .logical,
                severity: conflict.strength > 0.8 ? .high : .medium,
                resolution: "Review and resolve conflict between items"
            )
        }
    }
}

// MARK: - Supporting Types

struct DependencyAnalysis {
    let itemId: UUID
    let dependencies: [ItemRelationship]
    let dependents: [ItemRelationship]
    let isBlocked: Bool
    let canStart: Bool
}

// MARK: - Integration with Brain Dump Processor
extension LLMBrainDumpProcessor {
    /// Detect relationships for processed items
    func detectRelationshipsForItems(_ items: [EnhancedBrainDumpItem]) async -> [ItemRelationship] {
        let relationshipService = RelationshipDetectionService.shared
        return await relationshipService.detectRelationships(among: items)
    }
    
    /// Build relationship graph for visualization
    func buildRelationshipGraph(_ items: [EnhancedBrainDumpItem]) async -> RelationshipGraph {
        let relationshipService = RelationshipDetectionService.shared
        return await relationshipService.buildRelationshipGraph(for: items)
    }
}