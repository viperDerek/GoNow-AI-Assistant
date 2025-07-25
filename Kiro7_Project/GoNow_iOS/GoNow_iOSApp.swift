import SwiftUI

@main
struct GoNow_iOSApp: App {
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var alarmManager = AlarmManager.shared
    
    var body: some Scene {
        WindowGroup {
            iOSContentView()
                .environmentObject(calendarManager)
                .environmentObject(navigationManager)
                .environmentObject(alarmManager)
        }
    }
}