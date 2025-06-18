//
// SidebarView.swift
// LifeManager
//
// Implements: v2.0 "Modular Architecture" - Navigation Component
// Roadmap Reference: v1.75 Calendar Revolution → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Dynamic Navigation, Context-Aware Menu Items
//

import SwiftUI

/// Main navigation sidebar for PARA methodology organization
/// Provides structured access to all LifeManager views and features
/// Clean, focused component extracted from monolithic ContentView
struct SidebarView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        List(selection: $viewModel.selectedView) {
            // Inbox - Universal input point
            NavigationLink(destination: InboxView().environmentObject(viewModel)) {
                Label("Inbox", systemImage: "tray")
            }
            .tag(PARAView.inbox)
            
            Section("PARA") {
                NavigationLink(destination: ProjectsView().environmentObject(viewModel)) {
                    Label("Projects", systemImage: "folder")
                }
                .tag(PARAView.projects)
                
                NavigationLink(destination: AreasView().environmentObject(viewModel)) {
                    Label("Areas", systemImage: "circles.hexagongrid")
                }
                .tag(PARAView.areas)
                
                NavigationLink(destination: ResourcesView().environmentObject(viewModel)) {
                    Label("Resources", systemImage: "books.vertical")
                }
                .tag(PARAView.resources)
                
                NavigationLink(destination: ArchivesView().environmentObject(viewModel)) {
                    Label("Archives", systemImage: "archivebox")
                }
                .tag(PARAView.archives)
            }
            
            Section("Views") {
                NavigationLink(destination: FocusView().environmentObject(viewModel)) {
                    Label("Focus", systemImage: "scope")
                }
                .tag(PARAView.focus)
                
                NavigationLink(destination: CalendarView().environmentObject(viewModel)) {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(PARAView.calendar)
                
                NavigationLink(destination: TimelineView().environmentObject(viewModel)) {
                    Label("Timeline", systemImage: "timeline.selection")
                }
                .tag(PARAView.timeline)
                
                NavigationLink(destination: MindMapView().environmentObject(viewModel)) {
                    Label("Mind Map", systemImage: "brain.head.profile")
                }
                .tag(PARAView.mindmap)
                
                NavigationLink(destination: TagsView().environmentObject(viewModel)) {
                    Label("Tags", systemImage: "tag")
                }
                .tag(PARAView.tags)
            }
            
            Section("Search & History") {
                NavigationLink(destination: SearchView().environmentObject(viewModel)) {
                    Label("Advanced Search", systemImage: "magnifyingglass")
                }
                .tag(PARAView.search)
                
                NavigationLink(destination: HistoryView().environmentObject(viewModel)) {
                    Label("History", systemImage: "clock")
                }
                .tag(PARAView.history)
            }
        }
        .navigationTitle("LifeManager")
    }
}

#Preview {
    SidebarView()
        .environmentObject(MainViewModel())
}