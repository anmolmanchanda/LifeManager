import SwiftUI
import AppKit

@main
struct LifeManagerApp: App {
    @StateObject private var urlHandler = URLHandler()
    
    init() {
        // Ensure app comes to foreground when launched
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(urlHandler)
                .onOpenURL { url in
                    Task {
                        await urlHandler.handleIncomingURL(url)
                    }
                }
        }
        .windowStyle(DefaultWindowStyle())
        .defaultSize(width: 1200, height: 800)
        .windowResizability(.contentSize)
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

// URL Handler class to manage incoming URLs
class URLHandler: ObservableObject {
    func handleIncomingURL(_ url: URL) async {
        print("🔗 URL HANDLER: Received URL: \(url)")
        print("🔗 URL HANDLER: Scheme: \(url.scheme ?? "nil")")
        print("🔗 URL HANDLER: Host: \(url.host ?? "nil")")
        print("🔗 URL HANDLER: Path: \(url.path)")
        print("🔗 URL HANDLER: Query: \(url.query ?? "nil")")
        
        // Check if this is a magic link callback
        if url.scheme == "lifemanager" && url.host == "auth" && url.path == "/callback" {
            print("🔗 URL HANDLER: Valid magic link callback detected")
            do {
                try await SupabaseService.shared.handleMagicLinkCallback(url: url)
                print("🔗 URL HANDLER: Successfully handled magic link callback")
            } catch {
                print("🔗 URL HANDLER: Error handling magic link callback: \(error)")
            }
        } else {
            print("🔗 URL HANDLER: Not a valid magic link callback")
            print("🔗 URL HANDLER: Expected scheme: lifemanager, host: auth, path: /callback")
        }
    }
} 