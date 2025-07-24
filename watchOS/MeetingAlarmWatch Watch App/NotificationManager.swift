import Combine
import Combine
import Combine
import Foundation
import UserNotifications
import EventKit
import WatchKit

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var hasNotificationPermission = false
    @Published var scheduledNotifications: [String: Date] = [:]
    var lastError: String?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermissionStatus()
        loadScheduledNotifications()
    }
    
    func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasNotificationPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasNotificationPermission = granted
                if let error = error {
                    self?.lastError = error.localizedDescription
                }
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, date: Date, eventId: String? = nil) {
        guard hasNotificationPermission else {
            requestPermission()
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "MEETING_ALARM"
        
        // Add haptic feedback
        WKInterfaceDevice.current().play(.notification)
        
        // Add event ID as user info if available
        if let eventId = eventId {
            content.userInfo = ["eventId": eventId]
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = eventId ?? UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Notification scheduling error: \(error.localizedDescription)"
                    print("Notification scheduling error: \(error.localizedDescription)")
                } else {
                    print("Notification scheduled for: \(date)")
                    self?.scheduledNotifications[identifier] = date
                }
            }
        }
    }
    
    func scheduleLeaveNowNotification(for event: EKEvent, travelTime: TimeInterval, address: String?) {
        let departureTime = event.startDate.addingTimeInterval(-travelTime - Double(300)) // 5 min buffer
        
        var body = "Leave now for: \(event.title ?? "Meeting")\n"
        body += "Travel time: \(formatTravelTime(travelTime))"
        
        if let address = address {
            body += "\nDestination: \(address)"
        }
        
        scheduleNotification(
            title: "Time to Go!",
            body: body,
            date: departureTime,
            eventId: event.eventIdentifier
        )
    }
    
    func scheduleReminderNotification(for event: EKEvent, minutesBefore: Int) {
        let reminderTime = event.startDate.addingTimeInterval(-Double(minutesBefore * 60))
        
        let body = "\(event.title ?? "Meeting") starts in \(minutesBefore) minutes"
        
        scheduleNotification(
            title: "Meeting Reminder",
            body: body,
            date: reminderTime,
            eventId: "reminder-\(event.eventIdentifier ?? "unknown")"
        )
    }
    
    func cancelNotification(for eventId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [eventId])
        scheduledNotifications.removeValue(forKey: eventId)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduledNotifications.removeAll()
    }
    
    private func loadScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            var notifications: [String: Date] = [:]
            
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextTriggerDate = trigger.nextTriggerDate() {
                    notifications[request.identifier] = nextTriggerDate
                }
            }
            
            DispatchQueue.main.async {
                self?.scheduledNotifications = notifications
            }
        }
    }
    
    private func formatTravelTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            } else {
                return "\(hours) hour\(hours > 1 ? "s" : "") \(remainingMinutes) min"
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.sound, .alert])
    }
}