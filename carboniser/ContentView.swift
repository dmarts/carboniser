import SwiftUI

struct ContentView: View {
    @ObservedObject var manager: CarbonIntensityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                    Text("Carbon Intensity: \(manager.currentIndex.capitalized)")
                        .font(.headline)
                    
                    Divider()
                    
                    Picker("Region", selection: $manager.selectedRegionID) {
                        ForEach(manager.regions.keys.sorted(), id: \.self) { key in
                            Text(manager.regions[key] ?? "Unknown").tag(key)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Divider()
                    
                    // --- NEW DEBUG BUTTON ---
                    Button("Debug: Force Test Conditions") {
                        manager.forceTestConditions()
                    }
                    // ------------------------
                    
                    Button("Refresh Now") {
                        manager.fetchIntensity()
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                }
        .padding()
        // Sets a fixed width for the menu dropdown
        .frame(width: 260)
    }
}
