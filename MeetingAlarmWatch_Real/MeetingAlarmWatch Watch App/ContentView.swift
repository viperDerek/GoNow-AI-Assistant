import SwiftUI
import UserNotifications

struct ContentView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Header
                    HStack {
                        Image(systemName: "alarm.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("GoNow")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    // Status
                    HStack {
                        Circle()
                            .fill(alarmManager.isActive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(alarmManager.isActive ? "Active" : "Inactive")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text(alarmManager.notificationStatus)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Alarms list
                    if alarmManager.alarms.isEmpty {
                        EmptyAlarmView()
                    } else {
                        ForEach(alarmManager.alarms) { alarm in
                            AlarmCardView(alarm: alarm, currentTime: currentTime)
                        }
                    }
                    
                    // Test buttons
                    VStack(spacing: 8) {
                        Button("Add Test Alarm") {
                            alarmManager.addTestAlarm()
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.caption)
                        
                        Button("Trigger Notification") {
                            alarmManager.triggerImmediateNotification()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                    
                    // Current time and alarm count
                    VStack(spacing: 4) {
                        Text("Current: \(currentTime, formatter: timeFormatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(alarmManager.alarms.count) alarms active")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

struct AlarmCardView: View {
    let alarm: AlarmData
    let currentTime: Date
    
    private var timeUntilDeparture: TimeInterval {
        alarm.departureTime.timeIntervalSince(currentTime)
    }
    
    private var shouldAlert: Bool {
        timeUntilDeparture <= 60 && timeUntilDeparture > -300 // Alert 1 minute before
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Meeting #\(alarm.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if shouldAlert {
                    Text("LEAVE NOW!")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            
            Text(alarm.title)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Text(alarm.location)
                    .font(.caption)
                    .lineLimit(1)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Meeting: \(alarm.meetingTime, formatter: timeFormatter)")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(shouldAlert ? .red : .green)
                            .font(.caption)
                        Text("Leave: \(alarm.departureTime, formatter: timeFormatter)")
                            .font(.caption)
                            .foregroundColor(shouldAlert ? .red : .primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(alarm.travelTime) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if timeUntilDeparture > 0 {
                        Text("\(Int(timeUntilDeparture/60))m left")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else if timeUntilDeparture > -300 {
                        Text("GO!")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(12)
        .background(shouldAlert ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(shouldAlert ? Color.red : Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct EmptyAlarmView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("No upcoming meetings")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    ContentView()
        .environmentObject(AlarmManager())
}