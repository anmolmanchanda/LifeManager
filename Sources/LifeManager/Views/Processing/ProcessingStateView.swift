//
// ProcessingStateView.swift
// LifeManager
//
// Views for displaying processing state and progress
// Extracted from ContentView for modularity
//

import SwiftUI

/// View showing processing state during brain dump analysis
struct ProcessingStateView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var animationPhase = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated Processing Indicator
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(animationPhase))
                    .animation(
                        .linear(duration: 2)
                        .repeatForever(autoreverses: false),
                        value: animationPhase
                    )
                
                Image(systemName: "brain")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                    .scaleEffect(1 + sin(animationPhase * .pi / 180) * 0.1)
            }
            
            // Progress Message
            VStack(spacing: 8) {
                Text("Processing your input...")
                    .font(.headline)
                
                if !viewModel.brainDumpProgressMessage.isEmpty {
                    Text(viewModel.brainDumpProgressMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Elapsed Time
                if viewModel.brainDumpElapsedTime > 0 {
                    Text("\(viewModel.brainDumpElapsedTime)s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            ProgressView()
                .progressViewStyle(.linear)
                .frame(width: 200)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            animationPhase = 360
        }
    }
}