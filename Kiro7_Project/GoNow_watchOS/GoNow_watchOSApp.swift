import SwiftUI
import WatchConnectivity

@main
struct GoNow_watchOSApp: App {
    @StateObject private var watchAlarmManager = WatchAlarmManager()
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(watchAlarmManager)
        }
    }
}

class WatchAlarmManager: NSObject, ObservableObject {
    @Published var alarms: [WatchAlarm] = []
    
    struct WatchAlarm: Identifiable, Codable {
        let id: String
        let date: Date
        let title: String
        let message: String
        let eventName: String
    }
    
    override init() {
        super.init()
        setupWatchConnectivity()
        loadStoredAlarms()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    private func loadStoredAlarms() {
        if let data = UserDefaults.standard.data(forKey: "WatchAlarms"),
           let storedAlarms = try? JSONDecoder().decode([WatchAlarm].self, from: data) {
            alarms = storedAlarms
        }
    }
    
    private func saveAlarms() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: "WatchAlarms")
        }
    }
    
    func addAlarm(_ alarm: WatchAlarm) {
        alarms.append(alarm)
        saveAlarms()
        scheduleWatchNotification(for: alarm)
    }
    
    func removeAlarm(id: String) {
        alarms.removeAll { $0.id == id }
        saveAlarms()
        // Cancel notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    private func scheduleWatchNotification(for alarm: WatchAlarm) {
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = alarm.message
        content.sound = .default
        content.categoryIdentifier = "GONOW_WATCH_ALARM"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: alarm.id,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule watch notification: \(error)")
            }
        }
    }
}

extension WatchAlarmManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activated: \(activationState)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let type = message["type"] as? String {
                switch type {
                case "alarm":
                    if let id = message["id"] as? String,
                       let timestamp = message["date"] as? TimeInterval,
                       let title = message["title"] as? String,
                       let messageText = message["message"] as? String,
                       let eventName = message["eventName"] as? String {
                        
                        let alarm = WatchAlarm(
                            id: id,
                            date: Date(timeIntervalSince1970: timestamp),
                            title: title,
                            message: messageText,
                            eventName: eventName
                        )
                        self.addAlarm(alarm)
                    }
                    
                case "cancelAlarm":
                    if let id = message["id"] as? String {
                        self.removeAlarm(id: id)
                    }
                    
                default:
                    break
                }
            }
        }
    }
}