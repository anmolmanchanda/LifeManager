import SwiftUI
import AppKit

@main
struct LifeManagerApp: App {
    @StateObject private var urlHandler = URLHandler()
    @StateObject private var appDelegate = AppDelegate()
    
    init() {
        NSLog("🔧 DEBUG: LifeManagerApp init() started")
        
        // Simplified instance management - just use lock file check
        let lockResult = InstanceManager.shared.acquireInstanceLock()
        NSLog("🔧 DEBUG: Instance lock result: \(lockResult)")
        
        if !lockResult {
            NSLog("🚫 LifeManager instance lock already exists. Exiting immediately.")
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
            return
        }
        
        NSLog("🔧 DEBUG: Instance lock acquired successfully")
        
        // Ensure app comes to foreground when launched
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        NSLog("🔧 DEBUG: LifeManagerApp init() completed successfully")
    }
    
    var body: some Scene {
        NSLog("🔧 DEBUG: LifeManagerApp body computed property accessed")
        return         WindowGroup {
            ContentView()
                .environmentObject(urlHandler)
                .onOpenURL { url in
                    Task {
                        await urlHandler.handleIncomingURL(url)
                    }
                }
                .onAppear {
                    // DISABLED: Skip full screen toggle to prevent permission dialogs
                    print("🔧 DEBUG: App appeared - skipping full screen toggle")
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

// MARK: - App Delegate for Cleanup
class AppDelegate: NSObject, ObservableObject {
    override init() {
        super.init()
        // Register for app termination
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: .init("NSApplicationWillTerminateNotification"),
            object: nil
        )
    }
    
    @objc private func appWillTerminate() {
        InstanceManager.shared.releaseInstanceLock()
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
        InstanceManager.shared.releaseInstanceLock()
    }
}

// MARK: - Instance Manager
class InstanceManager {
    static let shared = InstanceManager()
    private init() {}
    
    func acquireInstanceLock() -> Bool {
        let lockFileURL = getLockFileURL()
        let currentPID = getpid()
        
        NSLog("🔧 DEBUG: Checking lock file at: \(lockFileURL.path)")
        NSLog("🔧 DEBUG: Current PID: \(currentPID)")
        
        // Check if lock file exists
        if FileManager.default.fileExists(atPath: lockFileURL.path) {
            NSLog("🔧 DEBUG: Lock file exists, checking if process is still running")
            
            // Try to read the PID from lock file
            if let pidString = try? String(contentsOf: lockFileURL),
               let pid = Int32(pidString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                NSLog("🔧 DEBUG: Found PID in lock file: \(pid)")
                
                // Check if the process is still running
                if kill(pid, 0) == 0 {
                    NSLog("🔧 DEBUG: Process \(pid) is still running, denying lock")
                    return false
                } else {
                    NSLog("🔧 DEBUG: Process \(pid) is no longer running, removing stale lock")
                    try? FileManager.default.removeItem(at: lockFileURL)
                }
            } else {
                NSLog("🔧 DEBUG: Invalid lock file content, removing it")
                try? FileManager.default.removeItem(at: lockFileURL)
            }
        } else {
            NSLog("🔧 DEBUG: No existing lock file found")
        }
        
        // Create lock file with current PID
        do {
            // Create directory if it doesn't exist
            let lockDir = lockFileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: lockDir, withIntermediateDirectories: true)
            
            // Write PID to lock file
            try String(currentPID).write(to: lockFileURL, atomically: true, encoding: .utf8)
            NSLog("🔧 DEBUG: Successfully created lock file with PID \(currentPID)")
            return true
        } catch {
            NSLog("🚫 DEBUG: Failed to create instance lock: \(error)")
            return false
        }
    }
    
    func releaseInstanceLock() {
        let lockFileURL = getLockFileURL()
        try? FileManager.default.removeItem(at: lockFileURL)
    }
    
    private func getLockFileURL() -> URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return supportDir.appendingPathComponent("LifeManager").appendingPathComponent("instance.lock")
    }
    
    func isAppAlreadyRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        let lifeManagerApps = runningApps.filter { app in
            (app.bundleIdentifier?.contains("LifeManager") == true ||
             app.localizedName?.contains("LifeManager") == true) &&
            app.processIdentifier != getpid() // Exclude current process
        }
        
        return !lifeManagerApps.isEmpty
    }
    
    func hasRunningLifeManagerProcesses() -> Bool {
        let task = Process()
        let pipe = Pipe()
        
        task.launchPath = "/bin/ps"
        task.arguments = ["aux"]
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let currentPID = getpid()
            let lines = output.components(separatedBy: .newlines)
            
            for line in lines {
                if line.lowercased().contains("lifemanager") && !line.contains("grep") {
                    // Extract PID (second column)
                    let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if components.count > 1,
                       let pid = Int32(components[1]),
                       pid != currentPID {
                        return true
                    }
                }
            }
        } catch {
            print("🚫 Failed to check running processes: \(error)")
        }
        
        return false
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
            // DISABLED: Skip Supabase callback to prevent keychain access
            print("🔗 URL HANDLER: Supabase callback disabled to prevent keychain access")
        } else {
            print("🔗 URL HANDLER: Not a valid magic link callback")
            print("🔗 URL HANDLER: Expected scheme: lifemanager, host: auth, path: /callback")
        }
    }
} 