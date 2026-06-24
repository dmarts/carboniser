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
struct ForecastResponse: Codable { let data: ForecastRegionData }
struct ForecastRegionData: Codable { let regionid: Int; let shortname: String; let data: [ForecastPeriod] }
struct ForecastPeriod: Codable { let from: String; let to: String; let intensity: IntensityDetail }
struct IntensityDetail: Codable { let forecast: Int; let index: String }

// MARK: - Main Manager
class CarbonIntensityManager: ObservableObject {
    @Published var currentIndex: String = "unknown"
    
    // Updated strings
    @Published var currentIntensityDescription: String = "Grid Carbon output: Fetching..."
    @Published var currentNumericDescription: String = ""
    @Published var forecastTrendDescription: String = "Forecast: Fetching..."
    
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
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }

    @Published var selectedRegionID: Int = UserDefaults.standard.integer(forKey: "SavedRegion") == 0 ? 12 : UserDefaults.standard.integer(forKey: "SavedRegion") {
        didSet {
            UserDefaults.standard.set(selectedRegionID, forKey: "SavedRegion")
            refreshData()
        }
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let now = Date()
        let startFetchTime = Calendar.current.date(byAdding: .minute, value: -30, to: now)!
        let toDate = Calendar.current.date(byAdding: .hour, value: 6, to: now)!
        
        let fromString = formatter.string(from: startFetchTime)
        let toString = formatter.string(from: toDate)
        
        let urlString = "https://api.carbonintensity.org.uk/regional/intensity/\(fromString)/\(toString)/regionid/\(selectedRegionID)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
                let periods = decoded.data.data
                
                if let current = periods.first {
                    DispatchQueue.main.async {
                        self.currentIndex = current.intensity.index
                        self.generateForecastDescriptions(periods: periods)
                        self.evaluateConditionsForNotification()
                    }
                }
            } catch {
                print("Failed to decode: \(error)")
            }
        }.resume()
    }

    func generateForecastDescriptions(periods: [ForecastPeriod]) {
        guard let current = periods.first else { return }
        let currentIndexStr = current.intensity.index
        let currentValue = current.intensity.forecast
        
        let levelMap = ["very low": 1, "low": 2, "moderate": 3, "high": 4, "very high": 5]
        let currentLevel = levelMap[currentIndexStr] ?? 3
        
        var nextChange: ForecastPeriod? = nil
        
        for period in periods {
            if period.intensity.index != currentIndexStr {
                nextChange = period
                break
            }
        }
        
        // Lines 1 & 3 Updates
        self.currentIntensityDescription = "Grid Carbon output: \(currentIndexStr)"
        self.currentNumericDescription = "Current carbon intensity: \(currentValue) gCO₂/kWh"
        
        // Line 2 Update (Forecast)
        if let change = nextChange {
            let nextLevel = levelMap[change.intensity.index] ?? 3
            let direction = nextLevel > currentLevel ? "rising" : "dropping" // Updated "falling" to "dropping" based on your example
            
            let parser = DateFormatter()
            parser.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
            parser.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let changeDate = parser.date(from: change.from) {
                let diffSeconds = max(0, changeDate.timeIntervalSince(Date()))
                let hours = max(1, Int(ceil(diffSeconds / 3600.0)))
                
                self.forecastTrendDescription = "Forecast: \(direction.capitalized) to \(change.intensity.index) in \(hours) \((hours == 1) ? "hour" : "hours")"
            } else {
                self.forecastTrendDescription = "Forecast: Changing to \(change.intensity.index) later"
            }
        } else {
            self.forecastTrendDescription = "Forecast: Staying the same for the next 6 hours"
        }
    }

    func evaluateConditionsForNotification() {
        let isHighCarbon = (currentIndex == "high" || currentIndex == "very high")
        if isHighCarbon && isPluggedIn && batteryLevel > 60 {
            sendNotification()
        }
    }

    func forceTestConditions() {
        self.currentIndex = "high"
        self.currentIntensityDescription = "Grid Carbon output: high"
        self.currentNumericDescription = "Current carbon intensity: 250 gCO₂/kWh"
        self.forecastTrendDescription = "Forecast: Dropping to very low in 3 hours"
        self.batteryLevel = 100
        self.isPluggedIn = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sendNotification()
        }
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "High Carbon Intensity"
        content.body = "Consider running on battery for a while, carbon intensity is high for grid power."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
