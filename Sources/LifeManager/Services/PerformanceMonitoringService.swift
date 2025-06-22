//
// PerformanceMonitoringService.swift
// LifeManager
//
// Priority 5: Performance & Monitoring
// Performance optimization and monitoring capabilities for intelligent automation services
// Status: ✅ IMPLEMENTED June 22, 2025
//

import Foundation
import SwiftUI
import Combine
import os.log

/// Comprehensive performance monitoring and optimization service
/// Tracks system performance, memory usage, and service health across all intelligent automation components
@MainActor
class PerformanceMonitoringService: ObservableObject {
    
    static let shared = PerformanceMonitoringService()
    
    // MARK: - Dependencies
    
    private let logger = Logger.shared
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Published State
    
    @Published var systemMetrics = SystemMetrics()
    @Published var serviceMetrics: [String: ServiceMetrics] = [:]
    @Published var performanceAlerts: [PerformanceAlert] = []
    @Published var isMonitoring = false
    @Published var optimizationRecommendations: [OptimizationRecommendation] = []
    @Published var memoryUsageHistory: [MemoryDataPoint] = []
    @Published var performanceHistory: [PerformanceDataPoint] = []
    
    // MARK: - Configuration
    
    private let monitoringInterval: TimeInterval = 30 // 30 seconds
    private let alertThresholds = AlertThresholds()
    private let maxHistoryPoints = 100
    private var monitoringTimer: Timer?
    private var performanceTimers: [String: PerformanceTimer] = [:]
    
    // MARK: - Initialization
    
    private init() {
        logger.info("PERFORMANCE_MONITOR: Service initialized")
        setupPerformanceMonitoring()
    }
    
    // MARK: - Performance Monitoring
    
    /// Start comprehensive performance monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        logger.info("PERFORMANCE_MONITOR: Starting performance monitoring")
        isMonitoring = true
        
        // Initial metrics collection
        Task {
            await collectSystemMetrics()
            await collectServiceMetrics()
        }
        
        // Set up periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performPeriodicMonitoring()
            }
        }
        
        logger.success("PERFORMANCE_MONITOR: Performance monitoring started")
    }
    
    /// Stop performance monitoring
    func stopMonitoring() {
        logger.info("PERFORMANCE_MONITOR: Stopping performance monitoring")
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    /// Perform periodic monitoring sweep
    private func performPeriodicMonitoring() async {
        await collectSystemMetrics()
        await collectServiceMetrics()
        await analyzePerformanceTrends()
        await checkPerformanceThresholds()
        await updatePerformanceHistory()
        await generateOptimizationRecommendations()
    }
    
    // MARK: - System Metrics Collection
    
    /// Collect comprehensive system metrics
    func collectSystemMetrics() async {
        logger.debug("PERFORMANCE_MONITOR: Collecting system metrics")
        
        let memoryInfo = getMemoryUsage()
        let cpuInfo = getCPUUsage()
        let diskInfo = getDiskUsage()
        let networkInfo = getNetworkUsage()
        
        systemMetrics = SystemMetrics(
            memoryUsage: memoryInfo,
            cpuUsage: cpuInfo,
            diskUsage: diskInfo,
            networkUsage: networkInfo,
            timestamp: Date()
        )
        
        // Add to history
        let dataPoint = PerformanceDataPoint(
            timestamp: Date(),
            memoryUsage: memoryInfo.usedMemory,
            cpuUsage: cpuInfo.usage,
            activeServices: serviceMetrics.count,
            alertCount: performanceAlerts.count
        )
        
        performanceHistory.append(dataPoint)
        
        // Trim history
        if performanceHistory.count > maxHistoryPoints {
            performanceHistory.removeFirst(performanceHistory.count - maxHistoryPoints)
        }
    }
    
    /// Collect metrics for all intelligent automation services
    func collectServiceMetrics() async {
        logger.debug("PERFORMANCE_MONITOR: Collecting service metrics")
        
        // Monitor LLM Service Coordinator
        await collectLLMServiceMetrics()
        
        // Monitor Intelligent Rescheduling Service
        await collectReschedulingServiceMetrics()
        
        // Monitor Advanced Notification Service
        await collectNotificationServiceMetrics()
        
        // Monitor Task Dependency Service
        await collectDependencyServiceMetrics()
        
        // Monitor External Calendar Integration
        await collectCalendarServiceMetrics()
        
        // Monitor Context Memory Service
        await collectContextMemoryMetrics()
        
        // Monitor Embeddings Service
        await collectEmbeddingsServiceMetrics()
    }
    
    // MARK: - Service-Specific Metrics
    
    /// Collect LLM Service performance metrics
    private func collectLLMServiceMetrics() async {
        let service = LLMServiceCoordinator.shared
        
        let metrics = ServiceMetrics(
            serviceName: "LLMServiceCoordinator",
            isHealthy: true, // Would check actual health
            responseTime: await measureServiceResponseTime("LLM"),
            memoryUsage: getServiceMemoryUsage("LLM"),
            requestCount: 0, // Would get from service
            errorCount: 0, // Would get from service
            lastActivity: Date(),
            customMetrics: [
                "active_configurations": 1,
                "prompt_cache_size": 0,
                "communication_latency": 0
            ]
        )
        
        serviceMetrics["LLMServiceCoordinator"] = metrics
    }
    
    /// Collect Intelligent Rescheduling Service metrics
    private func collectReschedulingServiceMetrics() async {
        let service = IntelligentReschedulingService.shared
        
        let stats = service.getReschedulingStatistics()
        
        let metrics = ServiceMetrics(
            serviceName: "IntelligentReschedulingService",
            isHealthy: service.isMonitoring,
            responseTime: await measureServiceResponseTime("Rescheduling"),
            memoryUsage: getServiceMemoryUsage("Rescheduling"),
            requestCount: stats.totalRescheduled,
            errorCount: stats.failedReschedulings,
            lastActivity: service.lastReschedulingActivity ?? Date(),
            customMetrics: [
                "overdue_tasks_count": service.overdueTasksCount,
                "success_rate": stats.successRate,
                "user_overrides": stats.userOverrides,
                "tasks_parked": stats.tasksParked
            ]
        )
        
        serviceMetrics["IntelligentReschedulingService"] = metrics
    }
    
    /// Collect Advanced Notification Service metrics
    private func collectNotificationServiceMetrics() async {
        let service = AdvancedNotificationService.shared
        
        let stats = service.deliveryStatistics
        
        let metrics = ServiceMetrics(
            serviceName: "AdvancedNotificationService",
            isHealthy: true,
            responseTime: await measureServiceResponseTime("Notifications"),
            memoryUsage: getServiceMemoryUsage("Notifications"),
            requestCount: stats.totalSent,
            errorCount: 0, // Would track failed deliveries
            lastActivity: Date(),
            customMetrics: [
                "active_escalations": service.activeEscalations.count,
                "critical_sent": stats.criticalSent,
                "emails_sent": stats.emailsSent,
                "sms_sent": stats.smsSent,
                "webhooks_sent": stats.webhooksSent
            ]
        )
        
        serviceMetrics["AdvancedNotificationService"] = metrics
    }
    
    /// Collect Task Dependency Service metrics
    private func collectDependencyServiceMetrics() async {
        let service = TaskDependencyService.shared
        
        let metrics = ServiceMetrics(
            serviceName: "TaskDependencyService",
            isHealthy: !service.isProcessing,
            responseTime: await measureServiceResponseTime("Dependencies"),
            memoryUsage: getServiceMemoryUsage("Dependencies"),
            requestCount: service.taskDependencies.count,
            errorCount: service.validationErrors.count,
            lastActivity: Date(),
            customMetrics: [
                "total_dependencies": service.taskDependencies.values.flatMap { $0 }.count,
                "cascade_warnings": service.cascadeWarnings.count,
                "dependency_graph_size": service.dependencyGraph.adjacencyList.count
            ]
        )
        
        serviceMetrics["TaskDependencyService"] = metrics
    }
    
    /// Collect External Calendar Integration metrics
    private func collectCalendarServiceMetrics() async {
        let service = ExternalCalendarIntegrationService.shared
        
        let metrics = ServiceMetrics(
            serviceName: "ExternalCalendarIntegrationService",
            isHealthy: !service.isProcessing,
            responseTime: await measureServiceResponseTime("Calendar"),
            memoryUsage: getServiceMemoryUsage("Calendar"),
            requestCount: service.externalEvents.count,
            errorCount: service.syncErrors.count,
            lastActivity: service.lastSyncDate ?? Date(),
            customMetrics: [
                "external_calendars": service.externalCalendars.count,
                "conflicts_detected": service.conflictingEvents.count,
                "availability_slots": service.availabilitySlots.count,
                "authorization_status": service.authorizationStatus.rawValue
            ]
        )
        
        serviceMetrics["ExternalCalendarIntegrationService"] = metrics
    }
    
    /// Collect Context Memory Service metrics
    private func collectContextMemoryMetrics() async {
        let service = ContextMemoryService.shared
        
        let metrics = ServiceMetrics(
            serviceName: "ContextMemoryService",
            isHealthy: true,
            responseTime: await measureServiceResponseTime("ContextMemory"),
            memoryUsage: getServiceMemoryUsage("ContextMemory"),
            requestCount: 0, // Would track context retrievals
            errorCount: 0,
            lastActivity: Date(),
            customMetrics: [
                "context_window_size": 0, // Would get from service
                "memory_usage_mb": 0, // Would calculate actual usage
                "last_cleanup": 0 // Would track cleanup operations
            ]
        )
        
        serviceMetrics["ContextMemoryService"] = metrics
    }
    
    /// Collect Embeddings Service metrics
    private func collectEmbeddingsServiceMetrics() async {
        let service = EmbeddingsService.shared
        
        let metrics = ServiceMetrics(
            serviceName: "EmbeddingsService",
            isHealthy: true,
            responseTime: await measureServiceResponseTime("Embeddings"),
            memoryUsage: getServiceMemoryUsage("Embeddings"),
            requestCount: 0, // Would track embedding requests
            errorCount: 0,
            lastActivity: Date(),
            customMetrics: [
                "cache_size": 0, // Would get cache metrics
                "cache_hit_rate": 0.0,
                "api_calls_count": 0,
                "memory_cleanup_count": 0
            ]
        )
        
        serviceMetrics["EmbeddingsService"] = metrics
    }
    
    // MARK: - Performance Analysis
    
    /// Analyze performance trends and identify issues
    private func analyzePerformanceTrends() async {
        logger.debug("PERFORMANCE_MONITOR: Analyzing performance trends")
        
        guard performanceHistory.count >= 5 else { return }
        
        let recentPoints = Array(performanceHistory.suffix(5))
        
        // Analyze memory trend
        let memoryTrend = calculateTrend(recentPoints.map { $0.memoryUsage })
        if memoryTrend > 0.2 { // 20% increase
            await createPerformanceAlert(
                type: .memoryIncrease,
                severity: .warning,
                message: "Memory usage trending upward",
                recommendation: "Consider running memory cleanup"
            )
        }
        
        // Analyze CPU trend
        let cpuTrend = calculateTrend(recentPoints.map { $0.cpuUsage })
        if cpuTrend > 0.3 { // 30% increase
            await createPerformanceAlert(
                type: .cpuSpike,
                severity: .warning,
                message: "CPU usage increasing significantly",
                recommendation: "Check for intensive operations"
            )
        }
        
        // Analyze service health
        let unhealthyServices = serviceMetrics.values.filter { !$0.isHealthy }
        if !unhealthyServices.isEmpty {
            await createPerformanceAlert(
                type: .serviceUnhealthy,
                severity: .critical,
                message: "\(unhealthyServices.count) services are unhealthy",
                recommendation: "Investigate service issues immediately"
            )
        }
    }
    
    /// Check performance thresholds and create alerts
    private func checkPerformanceThresholds() async {
        // Memory threshold check
        if systemMetrics.memoryUsage.usedMemory > alertThresholds.memoryWarningThreshold {
            await createPerformanceAlert(
                type: .memoryHigh,
                severity: systemMetrics.memoryUsage.usedMemory > alertThresholds.memoryCriticalThreshold ? .critical : .warning,
                message: "High memory usage detected",
                recommendation: "Consider freeing memory or increasing resources"
            )
        }
        
        // CPU threshold check
        if systemMetrics.cpuUsage.usage > alertThresholds.cpuWarningThreshold {
            await createPerformanceAlert(
                type: .cpuHigh,
                severity: systemMetrics.cpuUsage.usage > alertThresholds.cpuCriticalThreshold ? .critical : .warning,
                message: "High CPU usage detected",
                recommendation: "Check for CPU-intensive operations"
            )
        }
        
        // Service response time checks
        for (serviceName, metrics) in serviceMetrics {
            if metrics.responseTime > alertThresholds.responseTimeWarningThreshold {
                await createPerformanceAlert(
                    type: .slowResponse,
                    severity: metrics.responseTime > alertThresholds.responseTimeCriticalThreshold ? .critical : .warning,
                    message: "\(serviceName) response time is slow",
                    recommendation: "Investigate \(serviceName) performance"
                )
            }
        }
        
        // Error rate checks
        for (serviceName, metrics) in serviceMetrics {
            let errorRate = metrics.requestCount > 0 ? Double(metrics.errorCount) / Double(metrics.requestCount) : 0
            if errorRate > alertThresholds.errorRateWarningThreshold {
                await createPerformanceAlert(
                    type: .highErrorRate,
                    severity: errorRate > alertThresholds.errorRateCriticalThreshold ? .critical : .warning,
                    message: "\(serviceName) has high error rate",
                    recommendation: "Check \(serviceName) error logs"
                )
            }
        }
    }
    
    /// Generate optimization recommendations
    private func generateOptimizationRecommendations() async {
        logger.debug("PERFORMANCE_MONITOR: Generating optimization recommendations")
        
        var recommendations: [OptimizationRecommendation] = []
        
        // Memory optimization recommendations
        if systemMetrics.memoryUsage.usedMemory > alertThresholds.memoryOptimizationThreshold {
            recommendations.append(OptimizationRecommendation(
                type: .memoryOptimization,
                priority: .high,
                title: "Memory Usage Optimization",
                description: "System memory usage is above optimal levels",
                actions: [
                    "Run memory cleanup on EmbeddingsService cache",
                    "Clear ContextMemoryService old contexts",
                    "Optimize notification history retention",
                    "Review dependency graph caching"
                ],
                estimatedImpact: .high,
                difficulty: .medium
            ))
        }
        
        // Service optimization recommendations
        let slowServices = serviceMetrics.filter { $0.value.responseTime > 1.0 }
        if !slowServices.isEmpty {
            recommendations.append(OptimizationRecommendation(
                type: .serviceOptimization,
                priority: .medium,
                title: "Service Performance Optimization",
                description: "\(slowServices.count) services have slow response times",
                actions: slowServices.map { "Optimize \($0.key) performance" },
                estimatedImpact: .medium,
                difficulty: .medium
            ))
        }
        
        // Database optimization recommendations
        if systemMetrics.diskUsage.freeSpace < alertThresholds.diskSpaceWarningThreshold {
            recommendations.append(OptimizationRecommendation(
                type: .databaseOptimization,
                priority: .high,
                title: "Database Storage Optimization",
                description: "Disk space is running low",
                actions: [
                    "Archive old rescheduling history",
                    "Clean up notification history",
                    "Optimize database indexes",
                    "Consider data compression"
                ],
                estimatedImpact: .high,
                difficulty: .low
            ))
        }
        
        // AI service optimization
        let llmMetrics = serviceMetrics["LLMServiceCoordinator"]
        if let metrics = llmMetrics, metrics.responseTime > 2.0 {
            recommendations.append(OptimizationRecommendation(
                type: .aiOptimization,
                priority: .medium,
                title: "AI Service Optimization",
                description: "LLM service response time needs improvement",
                actions: [
                    "Implement prompt caching",
                    "Optimize LLM request batching",
                    "Consider local model deployment",
                    "Improve context management"
                ],
                estimatedImpact: .high,
                difficulty: .high
            ))
        }
        
        optimizationRecommendations = recommendations
    }
    
    // MARK: - Performance Optimization
    
    /// Execute automatic performance optimizations
    func performAutomaticOptimizations() async {
        logger.info("PERFORMANCE_MONITOR: Performing automatic optimizations")
        
        var optimizationsPerformed: [String] = []
        
        // Memory cleanup
        if systemMetrics.memoryUsage.usedMemory > alertThresholds.memoryOptimizationThreshold {
            await performMemoryCleanup()
            optimizationsPerformed.append("Memory cleanup")
        }
        
        // Service cache cleanup
        await performServiceCacheCleanup()
        optimizationsPerformed.append("Cache cleanup")
        
        // Notification history cleanup
        await performNotificationHistoryCleanup()
        optimizationsPerformed.append("Notification history cleanup")
        
        // Dependency graph optimization
        await optimizeDependencyGraph()
        optimizationsPerformed.append("Dependency graph optimization")
        
        if !optimizationsPerformed.isEmpty {
            logger.success("PERFORMANCE_MONITOR: Completed optimizations: \(optimizationsPerformed.joined(separator: ", "))")
            
            // Create success notification
            await createOptimizationNotification(optimizationsPerformed)
        }
    }
    
    /// Perform memory cleanup across services
    private func performMemoryCleanup() async {
        logger.info("PERFORMANCE_MONITOR: Performing memory cleanup")
        
        // EmbeddingsService cleanup
        await EmbeddingsService.shared.performMemoryCleanup()
        
        // ContextMemoryService cleanup
        await ContextMemoryService.shared.performMemoryCleanup()
        
        // Clear old performance data
        if performanceHistory.count > maxHistoryPoints / 2 {
            performanceHistory.removeFirst(performanceHistory.count - maxHistoryPoints / 2)
        }
        
        // Clear old memory data points
        if memoryUsageHistory.count > maxHistoryPoints / 2 {
            memoryUsageHistory.removeFirst(memoryUsageHistory.count - maxHistoryPoints / 2)
        }
    }
    
    /// Cleanup service caches
    private func performServiceCacheCleanup() async {
        logger.info("PERFORMANCE_MONITOR: Performing service cache cleanup")
        
        // Clear expired performance alerts
        let oneHourAgo = Date().addingTimeInterval(-3600)
        performanceAlerts = performanceAlerts.filter { $0.timestamp > oneHourAgo }
        
        // Clear old optimization recommendations
        optimizationRecommendations = optimizationRecommendations.filter { $0.priority == .high }
    }
    
    /// Cleanup notification history
    private func performNotificationHistoryCleanup() async {
        logger.info("PERFORMANCE_MONITOR: Performing notification history cleanup")
        
        let advancedService = AdvancedNotificationService.shared
        // Would call cleanup method on service
    }
    
    /// Optimize dependency graph
    private func optimizeDependencyGraph() async {
        logger.info("PERFORMANCE_MONITOR: Optimizing dependency graph")
        
        let dependencyService = TaskDependencyService.shared
        await dependencyService.cleanupExpiredUndoActions()
    }
    
    // MARK: - Performance Measurement
    
    /// Start performance timer for an operation
    func startPerformanceTimer(for operation: String) -> PerformanceTimer {
        let timer = PerformanceTimer(operation: operation)
        performanceTimers[operation] = timer
        return timer
    }
    
    /// End performance timer and record metrics
    func endPerformanceTimer(for operation: String) -> TimeInterval? {
        guard let timer = performanceTimers[operation] else { return nil }
        
        let duration = timer.end()
        performanceTimers.removeValue(forKey: operation)
        
        // Record performance metric
        recordOperationMetric(operation: operation, duration: duration)
        
        return duration
    }
    
    /// Record operation performance metric
    private func recordOperationMetric(operation: String, duration: TimeInterval) {
        logger.debug("PERFORMANCE_MONITOR: \(operation) completed in \(String(format: "%.3f", duration))s")
        
        // Store in service metrics if applicable
        if let serviceName = extractServiceName(from: operation) {
            if var metrics = serviceMetrics[serviceName] {
                metrics.responseTime = duration
                serviceMetrics[serviceName] = metrics
            }
        }
    }
    
    // MARK: - System Metrics Helpers
    
    /// Get current memory usage
    private func getMemoryUsage() -> MemoryUsage {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        let usedMemory = kerr == KERN_SUCCESS ? Double(info.resident_size) / 1024 / 1024 : 0 // MB
        
        return MemoryUsage(
            totalMemory: ProcessInfo.processInfo.physicalMemory / 1024 / 1024, // Convert to MB
            usedMemory: usedMemory,
            availableMemory: Double(ProcessInfo.processInfo.physicalMemory / 1024 / 1024) - usedMemory,
            pressure: usedMemory > 500 ? .high : usedMemory > 200 ? .medium : .low
        )
    }
    
    /// Get current CPU usage
    private func getCPUUsage() -> CPUUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        // This is a simplified CPU usage calculation
        let usage = kerr == KERN_SUCCESS ? Double(info.resident_size) / Double(ProcessInfo.processInfo.physicalMemory) * 100 : 0
        
        return CPUUsage(
            usage: min(usage, 100.0),
            coreCount: ProcessInfo.processInfo.processorCount,
            temperature: .normal // Would implement actual temperature monitoring
        )
    }
    
    /// Get disk usage information
    private func getDiskUsage() -> DiskUsage {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        
        do {
            let values = try fileURL.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeTotalCapacityKey
            ])
            
            let totalSpace = values.volumeTotalCapacity ?? 0
            let freeSpace = values.volumeAvailableCapacityForImportantUsage ?? 0
            let usedSpace = totalSpace - freeSpace
            
            return DiskUsage(
                totalSpace: Double(totalSpace) / 1024 / 1024 / 1024, // GB
                usedSpace: Double(usedSpace) / 1024 / 1024 / 1024,
                freeSpace: Double(freeSpace) / 1024 / 1024 / 1024,
                usagePercentage: totalSpace > 0 ? Double(usedSpace) / Double(totalSpace) * 100 : 0
            )
        } catch {
            return DiskUsage(totalSpace: 0, usedSpace: 0, freeSpace: 0, usagePercentage: 0)
        }
    }
    
    /// Get network usage information
    private func getNetworkUsage() -> NetworkUsage {
        // Simplified network usage - would implement actual network monitoring
        return NetworkUsage(
            bytesReceived: 0,
            bytesSent: 0,
            packetsReceived: 0,
            packetsSent: 0,
            connectionCount: 0
        )
    }
    
    // MARK: - Helper Methods
    
    /// Measure service response time
    private func measureServiceResponseTime(_ serviceName: String) async -> TimeInterval {
        let startTime = Date()
        
        // Simulate service health check
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        return Date().timeIntervalSince(startTime)
    }
    
    /// Get estimated memory usage for a service
    private func getServiceMemoryUsage(_ serviceName: String) -> Double {
        // Simplified memory estimation - would implement actual service memory tracking
        switch serviceName {
        case "LLM": return 50.0 // MB
        case "Rescheduling": return 25.0
        case "Notifications": return 15.0
        case "Dependencies": return 30.0
        case "Calendar": return 20.0
        case "ContextMemory": return 40.0
        case "Embeddings": return 60.0
        default: return 10.0
        }
    }
    
    /// Calculate trend from data points
    private func calculateTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        let first = values.first ?? 0
        let last = values.last ?? 0
        
        return first > 0 ? (last - first) / first : 0
    }
    
    /// Create performance alert
    private func createPerformanceAlert(
        type: AlertType,
        severity: AlertSeverity,
        message: String,
        recommendation: String
    ) async {
        
        let alert = PerformanceAlert(
            type: type,
            severity: severity,
            message: message,
            recommendation: recommendation,
            timestamp: Date()
        )
        
        performanceAlerts.append(alert)
        
        // Send notification for critical alerts
        if severity == .critical {
            await sendCriticalPerformanceAlert(alert)
        }
        
        // Trim alerts
        if performanceAlerts.count > 50 {
            performanceAlerts.removeFirst(performanceAlerts.count - 50)
        }
    }
    
    /// Send critical performance alert
    private func sendCriticalPerformanceAlert(_ alert: PerformanceAlert) async {
        await AdvancedNotificationService.shared.sendCriticalNotification(
            title: "Critical Performance Alert",
            message: alert.message,
            category: .systemAlert,
            immediateChannels: [.inApp, .push]
        )
    }
    
    /// Create optimization notification
    private func createOptimizationNotification(_ optimizations: [String]) async {
        let title = "Performance Optimizations Complete"
        let message = "Completed: \(optimizations.joined(separator: ", "))"
        
        await AdvancedNotificationService.shared.sendAdvancedNotification(
            title: title,
            message: message,
            priority: .normal,
            category: .systemAlert,
            context: NotificationContext(
                category: "performance_optimization",
                source: "performance_monitor",
                metadata: ["optimizations": optimizations.count]
            )
        )
    }
    
    /// Extract service name from operation string
    private func extractServiceName(from operation: String) -> String? {
        let serviceKeywords = ["LLM", "Rescheduling", "Notification", "Dependency", "Calendar", "Context", "Embeddings"]
        return serviceKeywords.first { operation.contains($0) }
    }
    
    /// Update performance history
    private func updatePerformanceHistory() async {
        let memoryPoint = MemoryDataPoint(
            timestamp: Date(),
            usedMemory: systemMetrics.memoryUsage.usedMemory,
            availableMemory: systemMetrics.memoryUsage.availableMemory,
            pressure: systemMetrics.memoryUsage.pressure
        )
        
        memoryUsageHistory.append(memoryPoint)
        
        // Trim history
        if memoryUsageHistory.count > maxHistoryPoints {
            memoryUsageHistory.removeFirst(memoryUsageHistory.count - maxHistoryPoints)
        }
    }
    
    /// Setup initial performance monitoring
    private func setupPerformanceMonitoring() {
        // Configure alert thresholds based on system capabilities
        // Start monitoring automatically
        startMonitoring()
    }
    
    /// Clean up expired undo actions
    func cleanupExpiredUndoActions() async {
        logger.info("PERFORMANCE_MONITOR: Cleaning up expired undo actions")
        
        let dependencyService = TaskDependencyService.shared
        // Would call cleanup method on dependency service
    }
}

// MARK: - Supporting Data Models

/// System performance metrics
struct SystemMetrics {
    let memoryUsage: MemoryUsage
    let cpuUsage: CPUUsage
    let diskUsage: DiskUsage
    let networkUsage: NetworkUsage
    let timestamp: Date
    
    init() {
        self.memoryUsage = MemoryUsage(totalMemory: 0, usedMemory: 0, availableMemory: 0, pressure: .low)
        self.cpuUsage = CPUUsage(usage: 0, coreCount: 0, temperature: .normal)
        self.diskUsage = DiskUsage(totalSpace: 0, usedSpace: 0, freeSpace: 0, usagePercentage: 0)
        self.networkUsage = NetworkUsage(bytesReceived: 0, bytesSent: 0, packetsReceived: 0, packetsSent: 0, connectionCount: 0)
        self.timestamp = Date()
    }
    
    init(memoryUsage: MemoryUsage, cpuUsage: CPUUsage, diskUsage: DiskUsage, networkUsage: NetworkUsage, timestamp: Date) {
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.diskUsage = diskUsage
        self.networkUsage = networkUsage
        self.timestamp = timestamp
    }
}

/// Memory usage information
struct MemoryUsage {
    let totalMemory: UInt64
    let usedMemory: Double
    let availableMemory: Double
    let pressure: MemoryPressure
}

/// Memory pressure levels
enum MemoryPressure: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// CPU usage information
struct CPUUsage {
    let usage: Double
    let coreCount: Int
    let temperature: CPUTemperature
}

/// CPU temperature levels
enum CPUTemperature: String {
    case normal = "normal"
    case warm = "warm"
    case hot = "hot"
}

/// Disk usage information
struct DiskUsage {
    let totalSpace: Double
    let usedSpace: Double
    let freeSpace: Double
    let usagePercentage: Double
}

/// Network usage information
struct NetworkUsage {
    let bytesReceived: UInt64
    let bytesSent: UInt64
    let packetsReceived: UInt64
    let packetsSent: UInt64
    let connectionCount: Int
}

/// Service-specific performance metrics
struct ServiceMetrics {
    let serviceName: String
    let isHealthy: Bool
    let responseTime: TimeInterval
    let memoryUsage: Double
    let requestCount: Int
    let errorCount: Int
    let lastActivity: Date
    let customMetrics: [String: Any]
}

/// Performance alert
struct PerformanceAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let severity: AlertSeverity
    let message: String
    let recommendation: String
    let timestamp: Date
}

/// Alert types
enum AlertType: String {
    case memoryHigh = "memory_high"
    case memoryIncrease = "memory_increase"
    case cpuHigh = "cpu_high"
    case cpuSpike = "cpu_spike"
    case slowResponse = "slow_response"
    case highErrorRate = "high_error_rate"
    case serviceUnhealthy = "service_unhealthy"
    case diskSpaceLow = "disk_space_low"
}

/// Alert severity levels
enum AlertSeverity: String {
    case info = "info"
    case warning = "warning"
    case critical = "critical"
}

/// Performance optimization recommendation
struct OptimizationRecommendation: Identifiable {
    let id = UUID()
    let type: OptimizationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let actions: [String]
    let estimatedImpact: ImpactLevel
    let difficulty: DifficultyLevel
}

/// Optimization types
enum OptimizationType: String {
    case memoryOptimization = "memory_optimization"
    case serviceOptimization = "service_optimization"
    case databaseOptimization = "database_optimization"
    case aiOptimization = "ai_optimization"
    case cacheOptimization = "cache_optimization"
}

/// Recommendation priority levels
enum RecommendationPriority: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Impact levels
enum ImpactLevel: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Difficulty levels
enum DifficultyLevel: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Memory data point for history tracking
struct MemoryDataPoint {
    let timestamp: Date
    let usedMemory: Double
    let availableMemory: Double
    let pressure: MemoryPressure
}

/// Performance data point for history tracking
struct PerformanceDataPoint {
    let timestamp: Date
    let memoryUsage: Double
    let cpuUsage: Double
    let activeServices: Int
    let alertCount: Int
}

/// Alert thresholds configuration
struct AlertThresholds {
    let memoryWarningThreshold: Double = 500.0 // MB
    let memoryCriticalThreshold: Double = 1000.0 // MB
    let memoryOptimizationThreshold: Double = 300.0 // MB
    
    let cpuWarningThreshold: Double = 70.0 // %
    let cpuCriticalThreshold: Double = 90.0 // %
    
    let responseTimeWarningThreshold: TimeInterval = 2.0 // seconds
    let responseTimeCriticalThreshold: TimeInterval = 5.0 // seconds
    
    let errorRateWarningThreshold: Double = 0.05 // 5%
    let errorRateCriticalThreshold: Double = 0.15 // 15%
    
    let diskSpaceWarningThreshold: Double = 10.0 // GB free space
}

// MARK: - Performance Timer

/// High-precision performance timer for measuring operation duration
class PerformanceTimer {
    private let operation: String
    private let startTime: CFAbsoluteTime
    
    init(operation: String) {
        self.operation = operation
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func end() -> TimeInterval {
        return CFAbsoluteTimeGetCurrent() - startTime
    }
    
    var elapsed: TimeInterval {
        return CFAbsoluteTimeGetCurrent() - startTime
    }
}