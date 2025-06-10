import SwiftUI

@main
struct LifeManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(DefaultWindowStyle())
        .commands {
            // Add menu commands for macOS
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    // Handle new note action
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Quick Capture") {
                    // Handle quick capture action
                }
                .keyboardShortcut("q", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .toolbar) {
                Button("Search") {
                    // Handle search action
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Divider()
                
                Button("Focus Mode") {
                    // Handle focus mode toggle
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
        }
    }
} 