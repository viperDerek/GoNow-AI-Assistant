import SwiftUI
import UserNotifications
import WatchKit

@main
struct MeetingAlarmWatchApp: App {
    @StateObject private var alarmManager = AlarmManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmManager)
                .onAppear {
                    alarmManager.setup()
                }
        }
    }
}

class AlarmManager: NSObject, ObservableObject {
    @Published var alarms: [AlarmData] = []
    @Published var isActive = false
    @Published var notificationStatus = "Requesting..."
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    func setup() {
        isActive = true
        loadTestAlarms()
    }
    
    func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationStatus = granted ? "Granted" : "Denied"
                print("Notification permission: \(granted)")
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
    }
    
    func loadTestAlarms() {
        // Create test alarm data
        alarms = [
            AlarmData(
                id: 1,
                title: "Important Client Meeting",
                location: "Apple Park, Cupertino",
                meetingTime: Date().addingTimeInterval(3600), // 1 hour from now
                departureTime: Date().addingTimeInterval(1800), // 30 minutes from now
                travelTime: 35
            ),
            AlarmData(
                id: 2,
                title: "Team Standup",
                location: "Office Building A",
                meetingTime: Date().addingTimeInterval(7200), // 2 hours from now
                departureTime: Date().addingTimeInterval(5400), // 1.5 hours from now
                travelTime: 15
            )
        ]
        
        scheduleTestNotification()
    }
    
    func addTestAlarm() {
        let newAlarm = AlarmData(
            id: alarms.count + 1,
            title: "New Test Meeting",
            location: "Conference Room B",
            meetingTime: Date().addingTimeInterval(1800), // 30 minutes from now
            departureTime: Date().addingTimeInterval(900), // 15 minutes from now
            travelTime: 10
        )
        
        alarms.append(newAlarm)
        scheduleTestNotification()
    }
    
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🚗 GoNow - Time to Leave!"
        content.body = "Your meeting starts soon - time to go!"
        content.sound = .default
        content.categoryIdentifier = "DEPARTURE_ALERT"
        
        // Schedule for 5 seconds from now for immediate testing
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "departure-alert", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("✅ Notification scheduled for 5 seconds")
            }
        }
    }
    
    func triggerImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🚗 GoNow Alert!"
        content.body = "Test departure notification - This is working!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "immediate-test", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to trigger notification: \(error)")
            } else {
                print("✅ Immediate notification triggered")
            }
        }
    }
}

extension AlarmManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }
}

struct AlarmData: Identifiable {
    let id: Int
    let title: String
    let location: String
    let meetingTime: Date
    let departureTime: Date
    let travelTime: Int
}