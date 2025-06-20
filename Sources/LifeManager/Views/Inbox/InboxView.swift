//
// InboxView.swift
// LifeManager
//
// Implements: v1.0 "Natural Language Input", v1.25 "Enhanced UI", v2.0 "Modular Architecture"
// Roadmap Reference: v1.0 Foundation → v1.25 Intelligence & UI → v2.0 Intelligence Expansion
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Advanced Input Methods, Voice Input, Image Processing
//

import SwiftUI

/// Universal inbox for all natural language input processing
/// Central entry point for PARA methodology content creation
/// Clean, focused interface extracted from monolithic ContentView
struct InboxView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Natural Language Input Area - Takes up significant space
            VStack(spacing: 20) {
                NaturalLanguageInputView()
                    .environmentObject(viewModel)
                    .frame(maxHeight: .infinity) // Let input take up as much space as possible
                
                // No bulk actions toolbar - removed notes from inbox
            }
            .frame(minHeight: 300) // Minimum height for input area
            .padding()
            
            Divider()
            
            // Empty space - no notes list, just history in input area
            Spacer()
                .frame(maxHeight: .infinity)
            
            // Show loading state
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing notes with AI...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $viewModel.showingConfirmationDialog) {
            ProcessingConfirmationView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showingProcessingSummary) {
            ProcessingSummaryView()
                .environmentObject(viewModel)
        }
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    InboxView()
        .environmentObject(MainViewModel())
        .frame(width: 800, height: 600)
}*/
