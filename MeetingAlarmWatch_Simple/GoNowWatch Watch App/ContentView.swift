import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var alarmCount = 2
    @State private var showingAlert = false
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Header
                HStack {
                    Image(systemName: "alarm.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    Text("GoNow")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                // Status
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Divider()
                
                // Alarm 1
                VStack(alignment: .leading, spacing: 4) {
                    Text("Client Meeting")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Apple Park")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Leave: 2:30 PM")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Spacer()
                        Text("35 min")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // Alarm 2
                VStack(alignment: .leading, spacing: 4) {
                    Text("Team Standup")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Office Building A")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Leave: 3:45 PM")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Spacer()
                        Text("15 min")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // Test buttons
                VStack(spacing: 6) {
                    Button("Test Notification") {
                        testNotification()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                    
                    Button("Add Alarm") {
                        addAlarm()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                
                // Status info
                Text("Time: \(currentTime, formatter: timeFormatter)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(alarmCount) alarms")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            requestNotificationPermissions()
            scheduleAutoNotification()
        }
        .alert("Alarm Added!", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text("New meeting alarm has been added to your schedule.")
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notification permission granted: \(granted)")
        }
    }
    
    private func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🚗 Time to Leave!"
        content.body = "Your meeting starts soon - GoNow alert!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error)")
            } else {
                print("✅ Test notification scheduled")
            }
        }
    }
    
    private func addAlarm() {
        alarmCount += 1
        showingAlert = true
        
        // Also trigger a notification
        let content = UNMutableNotificationContent()
        content.title = "New Alarm Added"
        content.body = "Meeting alarm #\(alarmCount) has been created"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "alarm-added-\(alarmCount)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleAutoNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🚗 GoNow Active"
        content.body = "Monitoring your meetings for departure alerts"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "auto-notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling auto notification: \(error)")
            } else {
                print("✅ Auto notification scheduled for 3 seconds")
            }
        }
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    ContentView()
}