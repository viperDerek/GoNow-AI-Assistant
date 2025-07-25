import SwiftUI
import EventKit

struct iOSContentView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var showingLocationInput = false
    @State private var selectedEvent: EKEvent?
    @State private var locationInput = ""
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            eventsTab
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .tag(0)
            
            alarmsTab
                .tabItem {
                    Image(systemName: "alarm")
                    Text("Alarms")
                }
                .tag(1)
            
            settingsTab
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RequestLocationForEvent"))) { notification in
            if let event = notification.object as? EKEvent {
                selectedEvent = event
                showingLocationInput = true
            }
        }
        .sheet(isPresented: $showingLocationInput) {
            NavigationView {
                LocationInputView(
                    event: selectedEvent,
                    locationInput: $locationInput,
                    onSave: { event, location in
                        calendarManager.addLocationToEvent(event, location: location)
                        showingLocationInput = false
                        locationInput = ""
                    },
                    onCancel: {
                        showingLocationInput = false
                        locationInput = ""
                    }
                )
            }
        }
    }
    
    private var eventsTab: some View {
        NavigationView {
            VStack {
                if calendarManager.authorizationStatus != .fullAccess {
                    permissionView
                } else {
                    eventsListView
                }
            }
            .navigationTitle("GoNow Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        calendarManager.loadGoNowEvents()
                    }
                }
            }
        }
    }
    
    private var alarmsTab: some View {
        NavigationView {
            List {
                if alarmManager.scheduledAlarms.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "alarm")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Alarms Scheduled")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Alarms will be automatically scheduled when GoNow events are detected.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(alarmManager.scheduledAlarms) { alarm in
                        AlarmRowView(alarm: alarm)
                    }
                }
            }
            .navigationTitle("Scheduled Alarms")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var settingsTab: some View {
        NavigationView {
            List {
                Section("Permissions") {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Calendar Access")
                        Spacer()
                        Text(calendarManager.authorizationStatus == .fullAccess ? "Granted" : "Not Granted")
                            .foregroundColor(calendarManager.authorizationStatus == .fullAccess ? .green : .red)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                        Text("Location Access")
                        Spacer()
                        Text(navigationManager.authorizationStatus == .authorizedWhenInUse ? "Granted" : "Not Granted")
                            .foregroundColor(navigationManager.authorizationStatus == .authorizedWhenInUse ? .green : .red)
                    }
                }
                
                Section("Navigation") {
                    Button("Open Apple Maps") {
                        // Test navigation
                        navigationManager.openInMaps(destination: "Apple Park, Cupertino, CA")
                    }
                    
                    Button("Open KakaoNavi") {
                        navigationManager.openInKakaoNavi(destination: "Apple Park, Cupertino, CA")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Events Monitored")
                        Spacer()
                        Text("\(calendarManager.goNowEvents.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("Calendar Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("GoNow needs access to your calendar to monitor events tagged with 'GoNow' and provide smart departure notifications.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Grant Calendar Access") {
                calendarManager.requestCalendarAccess()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    private var eventsListView: some View {
        List {
            if calendarManager.goNowEvents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No GoNow Events Found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add 'GoNow' to your calendar event titles or notes to enable smart departure notifications.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(calendarManager.goNowEvents, id: \.eventIdentifier) { event in
                    EventRowView(event: event)
                }
            }
        }
    }
}

struct EventRowView: View {
    let event: EKEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title ?? "Untitled Event")
                    .font(.headline)
                
                Spacer()
                
                if event.startDate.timeIntervalSinceNow < 24 * 60 * 60 && event.startDate.timeIntervalSinceNow > 0 {
                    Text("Tomorrow")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let location = event.location, !location.isEmpty {
                Label(location, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Label("No location set", systemImage: "location.slash")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if let calendar = event.calendar {
                Text(calendar.title)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(calendar.color))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AlarmRowView: View {
    let alarm: AlarmManager.ScheduledAlarm
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(alarm.title)
                .font(.headline)
            
            Text(alarm.date.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(alarm.message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct LocationInputView: View {
    let event: EKEvent?
    @Binding var locationInput: String
    let onSave: (EKEvent, String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Location")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let event = event {
                Text("Event: \(event.title ?? "Untitled")")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            TextField("Enter destination address", text: $locationInput)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    if let event = event, !locationInput.isEmpty {
                        onSave(event, locationInput)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationInput.isEmpty)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    onCancel()
                }
            }
        }
    }
}