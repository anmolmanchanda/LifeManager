//
// AreasView.swift
// LifeManager
//
// Implements: v1.5 "Complete PARA Views", v1.85 "Areas Functionality Overhaul", v2.0 "Modular Architecture"
// Roadmap Reference: v1.5 Advanced Features → v1.85 UI/UX Polish → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Enhanced Area Analytics, Smart Grouping
//

import SwiftUI

/// Areas view for PARA methodology - Ongoing responsibilities and spheres of activity
/// Features expandable sections with consistent architecture matching Projects/Resources
/// Clean, focused component extracted from monolithic ContentView
struct AreasView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var workPersonalFilter: WorkPersonalType? = nil
    
    private var filteredAreas: [Area] {
        guard let filter = workPersonalFilter else { return viewModel.areas }
        return viewModel.areas.filter { $0.workPersonal == filter }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Work/Personal toggle
            HStack {
                Text("Areas")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Work/Personal filter toggle
                HStack(spacing: 4) {
                    FilterToggleButton(
                        title: "Personal",
                        isSelected: workPersonalFilter == .personal,
                        action: {
                            workPersonalFilter = workPersonalFilter == .personal ? nil : .personal
                        }
                    )
                    
                    FilterToggleButton(
                        title: "Work",
                        isSelected: workPersonalFilter == .work,
                        action: {
                            workPersonalFilter = workPersonalFilter == .work ? nil : .work
                        }
                    )
                }
            }
            .padding()
            
            // Areas list with expandable sections (consistent with Projects/Resources)
            if filteredAreas.isEmpty {
                EmptyStateView(
                    title: "No areas yet",
                    systemImage: "square.grid.2x2",
                    description: "AI will create areas from your notes automatically"
                )
            } else {
                List {
                    ForEach(filteredAreas) { area in
                        AreaSectionView(area: area)
                            .environmentObject(viewModel)
                    }
                }
            }
        }
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    AreasView()
        .environmentObject(MainViewModel())
        .frame(width: 800, height: 600)
}*/
