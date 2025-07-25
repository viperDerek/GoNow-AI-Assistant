import SwiftUI

@main
struct GoNow_macOSApp: App {
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var alarmManager = AlarmManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calendarManager)
                .environmentObject(navigationManager)
                .environmentObject(alarmManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        MenuBarExtra("GoNow", systemImage: "clock.arrow.circlepath") {
            MenuBarView()
                .environmentObject(calendarManager)
                .environmentObject(alarmManager)
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var alarmManager: AlarmManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GoNow Events")
                .font(.headline)
                .padding(.horizontal)
            
            if calendarManager.goNowEvents.isEmpty {
                Text("No GoNow events found")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(calendarManager.goNowEvents, id: \.eventIdentifier) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title ?? "Untitled Event")
                            .font(.system(size: 12, weight: .medium))
                        Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        if let location = event.location {
                            Text("📍 \(location)")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            
            Divider()
            
            Text("Scheduled Alarms: \(alarmManager.scheduledAlarms.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Refresh Events") {
                calendarManager.loadGoNowEvents()
            }
            .padding(.horizontal)
            
            Button("Quit GoNow") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(width: 250)
    }
}