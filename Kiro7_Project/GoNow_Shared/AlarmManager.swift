import Foundation
import UserNotifications
import WatchConnectivity

class AlarmManager: NSObject, ObservableObject {
    static let shared = AlarmManager()
    
    @Published var scheduledAlarms: [ScheduledAlarm] = []
    
    struct ScheduledAlarm: Identifiable, Codable {
        let id = UUID()
        let date: Date
        let title: String
        let message: String
        let eventName: String
    }
    
    override init() {
        super.init()
        requestNotificationPermission()
        setupWatchConnectivity()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func scheduleAlarm(at date: Date, title: String, message: String) {
        let alarm = ScheduledAlarm(date: date, title: title, message: message, eventName: title)
        scheduledAlarms.append(alarm)
        
        // Schedule local notification
        scheduleLocalNotification(for: alarm)
        
        // Send to Apple Watch
        sendAlarmToWatch(alarm)
        
        print("Alarm scheduled for \(date): \(title)")
    }
    
    private func scheduleLocalNotification(for alarm: ScheduledAlarm) {
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = alarm.message
        content.sound = .default
        content.categoryIdentifier = "GONOW_ALARM"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func sendAlarmToWatch(_ alarm: ScheduledAlarm) {
        guard WCSession.default.isReachable else {
            // Store for later transmission
            storeAlarmForWatch(alarm)
            return
        }
        
        let alarmData: [String: Any] = [
            "type": "alarm",
            "id": alarm.id.uuidString,
            "date": alarm.date.timeIntervalSince1970,
            "title": alarm.title,
            "message": alarm.message,
            "eventName": alarm.eventName
        ]
        
        WCSession.default.sendMessage(alarmData) { response in
            print("Alarm sent to watch successfully")
        } errorHandler: { error in
            print("Failed to send alarm to watch: \(error)")
            self.storeAlarmForWatch(alarm)
        }
    }
    
    private func storeAlarmForWatch(_ alarm: ScheduledAlarm) {
        // Store in UserDefaults for later transmission when watch is available
        var pendingAlarms = UserDefaults.standard.array(forKey: "PendingWatchAlarms") as? [[String: Any]] ?? []
        
        let alarmDict: [String: Any] = [
            "id": alarm.id.uuidString,
            "date": alarm.date.timeIntervalSince1970,
            "title": alarm.title,
            "message": alarm.message,
            "eventName": alarm.eventName
        ]
        
        pendingAlarms.append(alarmDict)
        UserDefaults.standard.set(pendingAlarms, forKey: "PendingWatchAlarms")
    }
    
    func cancelAlarm(id: UUID) {
        scheduledAlarms.removeAll { $0.id == id }
        
        // Cancel local notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        
        // Cancel on watch
        if WCSession.default.isReachable {
            let cancelData = ["type": "cancelAlarm", "id": id.uuidString]
            WCSession.default.sendMessage(cancelData, replyHandler: nil, errorHandler: nil)
        }
    }
    
    private func sendPendingAlarmsToWatch() {
        guard let pendingAlarms = UserDefaults.standard.array(forKey: "PendingWatchAlarms") as? [[String: Any]] else {
            return
        }
        
        for alarmDict in pendingAlarms {
            let alarmData = ["type": "alarm"] + alarmDict
            WCSession.default.sendMessage(alarmData as [String : Any], replyHandler: nil, errorHandler: nil)
        }
        
        // Clear pending alarms
        UserDefaults.standard.removeObject(forKey: "PendingWatchAlarms")
    }
}

// MARK: - WCSessionDelegate
extension AlarmManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            sendPendingAlarmsToWatch()
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle messages from watch if needed
        print("Received message from watch: \(message)")
    }
}