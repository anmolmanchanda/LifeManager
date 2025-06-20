//
// NaturalLanguageInputView.swift
// LifeManager
//
// Implements: v1.0 "Natural Language Input", v1.25 "Enhanced UI", v1.85 "UI/UX Polish"
// Roadmap Reference: v1.0 Foundation → v1.25 Intelligence & UI → v1.85 UI/UX Polish
// Status: ✅ COMPLETE as of June 18, 2025 (extracted from ContentView.swift)
// Future: v2.5 Voice Input, Real-time Suggestions, Smart Completions
//

import SwiftUI

/// Advanced natural language input interface with AI processing capabilities
/// Features personalized greeting, smart placeholders, and real-time processing feedback
/// Core component of LifeManager's brain dump workflow
struct NaturalLanguageInputView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var inputText = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 16) {
                // Centered greeting
                HStack {
                    Spacer()
                    Text("Good to see you, Anmol.")
                        .font(.title)
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            
            // Large text editor taking up significant vertical space
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .font(.body)
                    .padding(12)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .frame(minHeight: 200, maxHeight: .infinity)
                    .disabled(isProcessing)
                
                // Placeholder text
                if inputText.isEmpty {
                    Text("What's on your mind?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            
            // Button area below input with centered thinking text
            HStack {
                // Show thinking text in center when processing
                if viewModel.isProcessingInbox || isProcessing {
                    HStack {
                        Spacer()
                        if !viewModel.brainDumpProgressMessage.isEmpty {
                            Text(viewModel.brainDumpProgressMessage)
                                .font(.title)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        } else {
                            Text("Thinking")
                                .font(.title)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                } else {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("ChatGPT 4.1")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            submitInput()
                        }) {
                            Image(systemName: "arrow.up")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .disabled(inputText.isEmpty || isProcessing)
                        .buttonStyle(.plain)
                        .frame(width: 28, height: 28)
                        .background(inputText.isEmpty || isProcessing ? Color.gray : Color.blue)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.top, 8)
            
            // Show elapsed time if available (separate row)
            if viewModel.brainDumpElapsedTime > 0 {
                let minutes = viewModel.brainDumpElapsedTime / 60
                let seconds = viewModel.brainDumpElapsedTime % 60
                let timeString = minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
                
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Processing time: \(timeString)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
            
            // History section
            if !viewModel.inboxHistory.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Processing History")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(viewModel.inboxHistory.enumerated()), id: \.offset) { index, item in
                        InboxHistoryRow(item: item)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .sheet(isPresented: $viewModel.showingBrainDumpReview) {
            if let result = viewModel.brainDumpResult {
                BrainDumpReviewView(
                    result: result,
                    onComplete: { summary in
                        viewModel.completeBrainDump(summary)
                    },
                    onCancel: {
                        viewModel.cancelBrainDump()
                    }
                )
                .environmentObject(viewModel)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Submit input for AI processing through brain dump workflow
    private func submitInput() {
        guard !inputText.isEmpty else { return }
        
        isProcessing = true
        
        // Set the input in the view model and trigger brain dump processing
        viewModel.inboxInput = inputText
        
        // Clear input immediately for better UX
        inputText = ""
        
        // Process using brain dump processor
        viewModel.processInboxInput()
        
        // Reset local processing state quickly, but keep viewModel.isProcessingInbox for persistent updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
        }
    }
}

/* #Preview // DISABLED FOR STABILIZATION
    NaturalLanguageInputView()
        .environmentObject(MainViewModel())
        .frame(width: 600, height: 400)
}*/
