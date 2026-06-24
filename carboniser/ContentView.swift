import SwiftUI

struct ContentView: View {
    @ObservedObject var manager: CarbonIntensityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Core Carbon Readouts (Lines 1, 2, and 3)
            VStack(alignment: .leading, spacing: 4) {
                
                // Line 1: Main Output (Dark/Headline)
                Text(manager.currentIntensityDescription)
                    .font(.headline)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Line 2: Forecast (Grey)
                Text(manager.forecastTrendDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Line 3: Numeric Value (Grey)
                Text(manager.currentNumericDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Local Device Readouts (Lines 4 and 5)
            VStack(alignment: .leading, spacing: 4) {
                
                // Line 4: Power Status (Grey)
                Text("Power status: \(manager.isPluggedIn ? "Connected to grid power" : "Not connected to grid power")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                // Line 5: Battery Level (Grey)
                Text("Battery level: \(manager.batteryLevel)%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            Picker("Region", selection: $manager.selectedRegionID) {
                ForEach(manager.regions.keys.sorted(), id: \.self) { key in
                    Text(manager.regions[key] ?? "Unknown").tag(key)
                }
            }
            .pickerStyle(.menu)
            
            Divider()
            
            Toggle("Launch at Login", isOn: $manager.launchAtLogin)
                            .toggleStyle(.checkbox)
                        
            Button("Check for Updates...") {
                manager.checkForUpdates(manual: true)
            }
            
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
        .frame(width: 320)
    }
}
