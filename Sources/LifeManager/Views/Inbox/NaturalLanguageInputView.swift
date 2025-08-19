//
// NaturalLanguageInputView.swift
// LifeManager
//
// Natural language input component for brain dump
// Extracted from ContentView for modularity
//

import SwiftUI

/// Natural language input view for brain dump
struct NaturalLanguageInputView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @FocusState private var isInputFocused: Bool
    @State private var characterCount = 0
    @State private var showingClearConfirmation = false
    
    private let maxCharacters = 10000
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Input Header
            HStack {
                Label("What's on your mind?", systemImage: "bubble.left.and.bubble.right")
                    .font(.headline)
                
                Spacer()
                
                Text("\(characterCount)/\(maxCharacters)")
                    .font(.caption)
                    .foregroundColor(characterCount > maxCharacters * 0.9 ? .orange : .secondary)
            }
            
            // Text Editor
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isInputFocused ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                
                if viewModel.inboxInput.isEmpty {
                    Text("Type or paste your thoughts, tasks, ideas, notes...")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $viewModel.inboxInput)
                    .font(.system(.body, design: .default))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .focused($isInputFocused)
                    .onChange(of: viewModel.inboxInput) { newValue in
                        characterCount = newValue.count
                        
                        // Auto-save draft
                        if !newValue.isEmpty {
                            UserDefaults.standard.set(newValue, forKey: "brainDumpDraft")
                        }
                    }
                    .disabled(viewModel.isProcessingInbox)
            }
            .frame(minHeight: 150, maxHeight: 400)
            
            // Action Buttons
            HStack(spacing: 12) {
                // Clear Button
                Button(action: { showingClearConfirmation = true }) {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.inboxInput.isEmpty || viewModel.isProcessingInbox)
                .confirmationDialog("Clear Input?", isPresented: $showingClearConfirmation) {
                    Button("Clear", role: .destructive) {
                        viewModel.inboxInput = ""
                        characterCount = 0
                        UserDefaults.standard.removeObject(forKey: "brainDumpDraft")
                    }
                    Button("Cancel", role: .cancel) {}
                }
                
                // Load Draft Button
                if let draft = UserDefaults.standard.string(forKey: "brainDumpDraft"),
                   !draft.isEmpty && viewModel.inboxInput.isEmpty {
                    Button(action: loadDraft) {
                        Label("Load Draft", systemImage: "doc.text")
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                // Process Button
                Button(action: { viewModel.processInboxInput() }) {
                    Label(
                        viewModel.isProcessingInbox ? "Processing..." : "Process",
                        systemImage: viewModel.isProcessingInbox ? "gear" : "arrow.right.circle.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inboxInput.isEmpty || viewModel.isProcessingInbox)
                .keyboardShortcut(.return, modifiers: .command)
            }
            
            // Keyboard Shortcuts Help
            if isInputFocused {
                HStack(spacing: 16) {
                    Label("⌘↩ Process", systemImage: "keyboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("⌘D Clear", systemImage: "keyboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            loadDraftIfEmpty()
        }
        .onDrop(of: [.plainText], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadDraft() {
        if let draft = UserDefaults.standard.string(forKey: "brainDumpDraft") {
            viewModel.inboxInput = draft
            characterCount = draft.count
        }
    }
    
    private func loadDraftIfEmpty() {
        if viewModel.inboxInput.isEmpty {
            loadDraft()
        } else {
            characterCount = viewModel.inboxInput.count
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { data, _ in
            if let data = data as? Data,
               let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    if viewModel.inboxInput.isEmpty {
                        viewModel.inboxInput = text
                    } else {
                        viewModel.inboxInput += "\n\n" + text
                    }
                    characterCount = viewModel.inboxInput.count
                }
            }
        }
        
        return true
    }
}