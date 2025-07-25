import SwiftUI
import EventKit

struct ContentView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var alarmManager: AlarmManager
    @State private var showingLocationInput = false
    @State private var selectedEvent: EKEvent?
    @State private var locationInput = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerView
                
                if calendarManager.authorizationStatus != .fullAccess {
                    permissionView
                } else {
                    eventsListView
                }
                
                Spacer()
                
                statusView
            }
            .padding()
            .frame(minWidth: 600, minHeight: 400)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RequestLocationForEvent"))) { notification in
                if let event = notification.object as? EKEvent {
                    selectedEvent = event
                    showingLocationInput = true
                }
            }
            .sheet(isPresented: $showingLocationInput) {
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
        .navigationTitle("GoNow - Smart Departure Notifications")
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("GoNow")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Smart departure notifications for your calendar events")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var permissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("Calendar Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("GoNow needs access to your calendar to monitor events tagged with 'GoNow' and provide smart departure notifications.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Grant Calendar Access") {
                calendarManager.requestCalendarAccess()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var eventsListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("GoNow Events")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh") {
                    calendarManager.loadGoNowEvents()
                }
                .buttonStyle(.bordered)
            }
            
            if calendarManager.goNowEvents.isEmpty {
                VStack(spacing: 12) {
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
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(calendarManager.goNowEvents, id: \.eventIdentifier) { event in
                            EventRowView(event: event)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
    
    private var statusView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Label("Calendar: \(calendarManager.authorizationStatus == .fullAccess ? "Connected" : "Not Connected")",
                          systemImage: calendarManager.authorizationStatus == .fullAccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(calendarManager.authorizationStatus == .fullAccess ? .green : .red)
                    .font(.caption)
                    
                    Label("Location: \(navigationManager.authorizationStatus == .authorizedWhenInUse ? "Enabled" : "Disabled")",
                          systemImage: navigationManager.authorizationStatus == .authorizedWhenInUse ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(navigationManager.authorizationStatus == .authorizedWhenInUse ? .green : .red)
                    .font(.caption)
                }
            }
            
            Spacer()
            
            Text("Alarms: \(alarmManager.scheduledAlarms.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct EventRowView: View {
    let event: EKEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Untitled Event")
                    .font(.headline)
                
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
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let calendar = event.calendar {
                    Text(calendar.title)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(calendar.color))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                if event.startDate.timeIntervalSinceNow < 24 * 60 * 60 && event.startDate.timeIntervalSinceNow > 0 {
                    Text("Tomorrow")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
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
                .frame(width: 300)
            
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
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}