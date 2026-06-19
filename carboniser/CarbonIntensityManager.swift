import SwiftUI

struct ContentView: View {
    @ObservedObject var manager: CarbonIntensityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Carbon Intensity: \(manager.currentIndex.capitalized)")
                .font(.headline)
            
            // New Power & Battery UI
            Text("Power status: \(manager.isPluggedIn ? "Connected to grid power" : "Not connected to grid power")")
                .font(.subheadline)
                .foregroundColor(.secondary)
                
            Text("Battery level: \(manager.batteryLevel)%")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Picker("Region", selection: $manager.selectedRegionID) {
                ForEach(manager.regions.keys.sorted(), id: \.self) { key in
                    Text(manager.regions[key] ?? "Unknown").tag(key)
                }
            }
            .pickerStyle(.menu)
            
            Divider()
            
            Button("Debug: Force Test Conditions") {
                manager.forceTestConditions()
            }
            
            Button("Refresh Now") {
                manager.refreshData()
            }
            .keyboardShortcut("r", modifiers: .command)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 290) // Slightly wider to accommodate the new text
    }
}
