import SwiftUI

@main
struct carboniserApp: App {
    // Initialize our background manager once
    @StateObject private var manager = CarbonIntensityManager()
    
    var body: some Scene {
        // MenuBarExtra tells macOS to put this in the status bar instead of a dock icon/window
        MenuBarExtra(
            "Carboniser",
            systemImage: getIconName(for: manager.currentIndex)
        ) {
            ContentView(manager: manager)
        }
        .menuBarExtraStyle(.window) // Allows for the custom ContentView layout
    }
    
    // Helper to determine the SF Symbol based on intensity
    func getIconName(for index: String) -> String {
        switch index {
        case "very low", "low": return "leaf.fill"
        case "moderate": return "exclamationmark.circle.fill"
        case "high", "very high": return "bolt.trianglebadge.exclamationmark.fill"
        default: return "questionmark.circle"
        }
    }
}
