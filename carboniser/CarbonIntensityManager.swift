import Foundation
import UserNotifications
import Combine
import ServiceManagement

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - API Data Models
struct CarbonResponse: Codable { let data: [RegionData] }
struct RegionData: Codable { let regionid: Int; let shortname: String; let data: [IntensityData] }
struct IntensityData: Codable { let intensity: IntensityDetail }
struct IntensityDetail: Codable { let forecast: Int; let index: String }

// MARK: - Main Manager
class CarbonIntensityManager: ObservableObject {
    @Published var currentIndex: String = "unknown"
    @Published var batteryLevel: Int = 0
    @Published var isPluggedIn: Bool = false
    @Published var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled {
            didSet {
                do {
                    if launchAtLogin {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Failed to toggle launch at login: \(error)")
                    // Revert the toggle if the OS blocks it
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }
            }
        }
    @Published var selectedRegionID: Int = 12 {
        didSet { refreshData() }
    }
    
    let regions = [
        1: "North Scotland", 2: "South Scotland", 3: "North West England",
        4: "North East England", 5: "Yorkshire", 6: "North Wales & Merseyside",
        7: "South Wales", 8: "West Midlands", 9: "East Midlands",
        10: "East England", 11: "South West England", 12: "South England",
        13: "London", 14: "South East England"
    ]

    private var timer: Timer?
    private var notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        startTimer()
    }

    func startTimer() {
        refreshData()
        timer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.refreshData()
        }
    }
    
    func refreshData() {
        updateBatteryStatus()
        fetchIntensity()
    }

    func updateBatteryStatus() {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-g", "batt"]
        task.standardOutput = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.isPluggedIn = output.contains("AC Power")
                    
                    if let regex = try? NSRegularExpression(pattern: "(\\d+)%"),
                       let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
                       let range = Range(match.range(at: 1), in: output),
                       let level = Int(output[range]) {
                        self.batteryLevel = level
                    }
                }
            }
        } catch {
            print("Failed to check battery: \(error)")
        }
    }

    func fetchIntensity() {
        let urlString = "https://api.carbonintensity.org.uk/regional/regionid/\(selectedRegionID)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(CarbonResponse.self, from: data)
                if let index = decoded.data.first?.data.first?.intensity.index {
                    DispatchQueue.main.async {
                        self.currentIndex = index
                        self.evaluateConditionsForNotification()
                    }
                }
            } catch {
                print("Failed to decode: \(error)")
            }
        }.resume()
    }

    func evaluateConditionsForNotification() {
        let isHighCarbon = (currentIndex == "high" || currentIndex == "very high")
        if isHighCarbon && isPluggedIn && batteryLevel > 60 {
            sendNotification()
        }
    }

    func forceTestConditions() {
        self.currentIndex = "high"
        self.batteryLevel = 100
        self.isPluggedIn = true
        sendNotification()
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "High Carbon Intensity"
        content.body = "Consider unplugging and running on battery for a while, your laptop is running on grid power which has a high 'carbon intensity' at the moment"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
