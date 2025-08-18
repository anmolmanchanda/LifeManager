//
// InboxView.swift
// LifeManager
//
// Extracted from ContentView for better modularity
// Handles inbox/brain dump functionality
//

import SwiftUI

/// Main inbox view for brain dump and natural language input
struct InboxView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingHistory = false
    @State private var showingProcessingDetails = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            InboxHeaderView(
                showingHistory: $showingHistory,
                showingProcessingDetails: $showingProcessingDetails
            )
            
            // Natural Language Input
            NaturalLanguageInputView()
                .environmentObject(viewModel)
            
            // Processing State
            if viewModel.isProcessingInbox {
                ProcessingStateView()
                    .environmentObject(viewModel)
            }
            
            // Recent Items
            if !viewModel.recentBlobs.isEmpty {
                RecentItemsSection()
                    .environmentObject(viewModel)
            }
        }
        .padding()
        .sheet(isPresented: $showingHistory) {
            HistoryView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingProcessingDetails) {
            ProcessingDetailsView()
                .environmentObject(viewModel)
        }
    }
}

/// Header for inbox view with action buttons
struct InboxHeaderView: View {
    @Binding var showingHistory: Bool
    @Binding var showingProcessingDetails: Bool
    
    var body: some View {
        HStack {
            Label("Brain Dump", systemImage: "brain")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { showingHistory.toggle() }) {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(.bordered)
                
                Button(action: { showingProcessingDetails.toggle() }) {
                    Label("Details", systemImage: "info.circle")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

/// Section showing recently processed items
struct RecentItemsSection: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Items", systemImage: "clock.fill")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.recentBlobs.prefix(10)) { blob in
                        BlobRowView(blob: blob)
                            .environmentObject(viewModel)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
}