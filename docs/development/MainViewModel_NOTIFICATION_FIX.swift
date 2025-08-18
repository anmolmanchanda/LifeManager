// MainViewModel.swift - NOTIFICATION SYSTEM FIX
// Add to existing MainViewModel to listen for data changes

import Foundation
import SwiftUI

// MARK: - Data Change Notification Extension
extension MainViewModel {
    
    /// Setup notifications to listen for data changes from brain dump processor
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .dataDidChange,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.refreshData()
                Logger.shared.info("MAIN_VIEW_MODEL: Data refreshed after brain dump creation")
            }
        }
        
        Logger.shared.info("MAIN_VIEW_MODEL: Notification listeners setup complete")
    }
    
    /// Remove notification observers when view model is deinitialized
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .dataDidChange, object: nil)
        Logger.shared.info("MAIN_VIEW_MODEL: Notification listeners removed")
    }
}

// MARK: - Integration Instructions
/*
To integrate this fix:

1. Add to MainViewModel.init():
   setupNotifications()

2. Add to MainViewModel.deinit():
   removeNotifications()

3. Ensure refreshData() method actually reloads all PARA data:
   - areas = try await areaRepository.fetchAllAreas()
   - projects = try await projectRepository.fetchAllProjects()  
   - resources = try await resourceRepository.fetchAllResources()
   - tasks from taskRepository.fetchAllTasks()

This will ensure that when brain dump items are created, the PARA tabs immediately show the new content.
*/