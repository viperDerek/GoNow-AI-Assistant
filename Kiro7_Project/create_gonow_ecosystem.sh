#!/bin/bash

# GoNow Complete Ecosystem Creator
# Creates macOS, iOS, and watchOS apps for intelligent meeting alarms

set -e

PROJECT_DIR="/Users/I314306/AI/Kiro7"
cd "$PROJECT_DIR"

echo "🚀 Creating GoNow Complete Ecosystem..."

# Create main project structure
mkdir -p GoNow_Ecosystem/{macOS,iOS,watchOS,Shared}

# Create macOS App
echo "📱 Creating macOS App..."
cat > GoNow_Ecosystem/macOS/AppDelegate.swift << 'EOF'
import Cocoa
import EventKit
import CoreLocation
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var eventStore = EKEventStore()
    var locationManager = CLLocationManager()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusBar()
        requestPermissions()
        startMonitoring()
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "GoNow"
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Check Events", action: #selector(checkEvents), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    func requestPermissions() {
        // Request Calendar access
        eventStore.requestFullAccessToEvents { granted, error in
            if granted {
                print("Calendar access granted")
            }
        }
        
        // Request Notification access
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Notification access: \(granted)")
        }
        
        // Request Location access
        locationManager.requestWhenInUseAuthorization()
    }
    
    @objc func checkEvents() {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: tomorrow, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if event.notes?.contains("GoNow") == true || event.title.contains("GoNow") {
                processGoNowEvent(event)
            }
        }
    }
    
    func processGoNowEvent(_ event: EKEvent) {
        print("Processing GoNow event: \(event.title)")
        
        // Check if location exists
        if let location = event.location, !location.isEmpty {
            calculateTravelTime(to: location, for: event)
        } else {
            requestLocationFromUser(for: event)
        }
    }
    
    func requestLocationFromUser(for event: EKEvent) {
        let alert = NSAlert()
        alert.messageText = "Location Required"
        alert.informativeText = "Event '\(event.title)' needs a location. Please enter the destination:"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        alert.accessoryView = textField
        
        if alert.runModal() == .alertFirstButtonReturn {
            let location = textField.stringValue
            if !location.isEmpty {
                // Update event with location
                event.location = location
                try? eventStore.save(event, span: .thisEvent)
                calculateTravelTime(to: location, for: event)
            }
        }
    }
    
    func calculateTravelTime(to destination: String, for event: EKEvent) {
        // This would integrate with Maps/Navigation APIs
        // For now, simulate travel time calculation
        let estimatedTravelTime: TimeInterval = 30 * 60 // 30 minutes default
        let bufferTime: TimeInterval = 10 * 60 // 10 minutes buffer
        
        let departureTime = event.startDate.addingTimeInterval(-(estimatedTravelTime + bufferTime))
        
        scheduleAlarm(for: event, at: departureTime)
        notifyiOSApp(event: event, departureTime: departureTime)
    }
    
    func scheduleAlarm(for event: EKEvent, at departureTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Go!"
        content.body = "Leave now for: \(event.title)"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: departureTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: "gonow-\(event.eventIdentifier)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func notifyiOSApp(event: EKEvent, departureTime: Date) {
        // Send data to iOS app via CloudKit or shared container
        print("Notifying iOS app about event: \(event.title) at \(departureTime)")
    }
    
    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.checkEvents()
        }
    }
}
EOF

# Create iOS App
echo "📱 Creating iOS App..."
cat > GoNow_Ecosystem/iOS/ContentView.swift << 'EOF'
import SwiftUI
import EventKit
import CoreLocation
import MapKit
import UserNotifications

struct ContentView: View {
    @StateObject private var viewModel = GoNowViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("GoNow Events")
                    .font(.largeTitle)
                    .padding()
                
                List(viewModel.goNowEvents, id: \.eventIdentifier) { event in
                    EventRow(event: event, viewModel: viewModel)
                }
                
                Button("Refresh Events") {
                    viewModel.loadEvents()
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.requestPermissions()
            viewModel.loadEvents()
        }
    }
}

struct EventRow: View {
    let event: EKEvent
    let viewModel: GoNowViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(event.title)
                .font(.headline)
            Text(event.startDate, style: .date)
            if let location = event.location {
                Text("📍 \(location)")
                    .foregroundColor(.secondary)
            }
            
            Button("Calculate Travel Time") {
                viewModel.calculateTravelTime(for: event)
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

class GoNowViewModel: ObservableObject {
    @Published var goNowEvents: [EKEvent] = []
    
    private let eventStore = EKEventStore()
    private let locationManager = CLLocationManager()
    
    func requestPermissions() {
        eventStore.requestFullAccessToEvents { granted, error in
            if granted {
                DispatchQueue.main.async {
                    self.loadEvents()
                }
            }
        }
        
        locationManager.requestWhenInUseAuthorization()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func loadEvents() {
        let calendar = Calendar.current
        let now = Date()
        let endDate = calendar.date(byAdding: .day, value: 7, to: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async {
            self.goNowEvents = events.filter { event in
                event.notes?.contains("GoNow") == true || event.title.contains("GoNow")
            }
        }
    }
    
    func calculateTravelTime(for event: EKEvent) {
        guard let location = event.location else {
            // Request location input
            return
        }
        
        // Use MapKit to calculate travel time
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }
            
            let destination = MKMapItem(placemark: MKPlacemark(placemark: placemark))
            request.destination = destination
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                guard let route = response?.routes.first else { return }
                
                let travelTime = route.expectedTravelTime
                let bufferTime: TimeInterval = 10 * 60 // 10 minutes
                let departureTime = event.startDate.addingTimeInterval(-(travelTime + bufferTime))
                
                self.scheduleWatchAlarm(for: event, at: departureTime, travelTime: travelTime)
            }
        }
    }
    
    func scheduleWatchAlarm(for event: EKEvent, at departureTime: Date, travelTime: TimeInterval) {
        // Schedule local notification
        let content = UNMutableNotificationContent()
        content.title = "Time to Leave!"
        content.body = "Leave now for \(event.title) (Travel time: \(Int(travelTime/60)) min)"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: departureTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: "gonow-\(event.eventIdentifier)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        
        // Send to Watch
        sendToWatch(event: event, departureTime: departureTime, travelTime: travelTime)
    }
    
    func sendToWatch(event: EKEvent, departureTime: Date, travelTime: TimeInterval) {
        // WatchConnectivity integration would go here
        print("Sending to Watch: \(event.title) at \(departureTime)")
    }
}
EOF

# Create watchOS App
echo "⌚ Creating watchOS App..."
cat > GoNow_Ecosystem/watchOS/ContentView.swift << 'EOF'
import SwiftUI
import UserNotifications
import WatchConnectivity

struct ContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("GoNow")
                    .font(.headline)
                    .padding()
                
                if viewModel.upcomingAlarms.isEmpty {
                    Text("No upcoming alarms")
                        .foregroundColor(.secondary)
                } else {
                    List(viewModel.upcomingAlarms, id: \.id) { alarm in
                        VStack(alignment: .leading) {
                            Text(alarm.eventTitle)
                                .font(.caption)
                            Text("Leave at: \(alarm.departureTime, style: .time)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button("Refresh") {
                    viewModel.loadAlarms()
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            viewModel.setup()
        }
    }
}

struct GoNowAlarm: Identifiable {
    let id = UUID()
    let eventTitle: String
    let departureTime: Date
    let eventTime: Date
}

class WatchViewModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var upcomingAlarms: [GoNowAlarm] = []
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func setup() {
        requestNotificationPermission()
        loadAlarms()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Watch notification permission: \(granted)")
        }
    }
    
    func loadAlarms() {
        // Load from UserDefaults or received data
        // This would be populated by data from iPhone
    }
    
    func scheduleAlarm(for alarm: GoNowAlarm) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Go!"
        content.body = "Leave now for: \(alarm.eventTitle)"
        content.sound = .default
        content.categoryIdentifier = "GONOW_ALARM"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.departureTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: "gonow-\(alarm.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activated: \(activationState)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let eventTitle = message["eventTitle"] as? String,
           let departureTimeInterval = message["departureTime"] as? TimeInterval,
           let eventTimeInterval = message["eventTime"] as? TimeInterval {
            
            let alarm = GoNowAlarm(
                eventTitle: eventTitle,
                departureTime: Date(timeIntervalSince1970: departureTimeInterval),
                eventTime: Date(timeIntervalSince1970: eventTimeInterval)
            )
            
            DispatchQueue.main.async {
                self.upcomingAlarms.append(alarm)
                self.scheduleAlarm(for: alarm)
            }
        }
    }
}
EOF

# Create Shared Components
echo "🔗 Creating Shared Components..."
cat > GoNow_Ecosystem/Shared/GoNowManager.swift << 'EOF'
import Foundation
import EventKit
import CoreLocation

class GoNowManager: ObservableObject {
    static let shared = GoNowManager()
    
    private let eventStore = EKEventStore()
    private let locationManager = CLLocationManager()
    
    private init() {}
    
    func findGoNowEvents() -> [EKEvent] {
        let calendar = Calendar.current
        let now = Date()
        let endDate = calendar.date(byAdding: .day, value: 7, to: now)!
        
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        return events.filter { event in
            event.notes?.contains("GoNow") == true || 
            event.title.contains("GoNow") ||
            event.notes?.lowercased().contains("gonow") == true
        }
    }
    
    func requestAllPermissions() async {
        // Calendar permission
        let calendarGranted = try? await eventStore.requestFullAccessToEvents()
        print("Calendar access: \(calendarGranted ?? false)")
        
        // Location permission
        locationManager.requestWhenInUseAuthorization()
    }
}
EOF

# Create Xcode project files
echo "🔨 Creating Xcode Projects..."

# macOS Project
cat > GoNow_Ecosystem/macOS/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>GoNow</string>
    <key>CFBundleIdentifier</key>
    <string>com.gonow.macos</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GoNow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSCalendarsUsageDescription</key>
    <string>GoNow needs access to your calendar to find events tagged with GoNow</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>GoNow needs your location to calculate travel time to your meetings</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# iOS Project
cat > GoNow_Ecosystem/iOS/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>GoNow</string>
    <key>CFBundleIdentifier</key>
    <string>com.gonow.ios</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GoNow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>NSCalendarsUsageDescription</key>
    <string>GoNow needs access to your calendar to find events tagged with GoNow</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>GoNow needs your location to calculate travel time to your meetings</string>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
EOF

# watchOS Project
cat > GoNow_Ecosystem/watchOS/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>GoNow Watch App</string>
    <key>CFBundleIdentifier</key>
    <string>com.gonow.ios.watchkitapp</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>GoNow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>WKApplication</key>
    <true/>
    <key>WKWatchOnly</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ GoNow Ecosystem Created Successfully!"
echo "📁 Location: $PROJECT_DIR/GoNow_Ecosystem"
echo ""
echo "Next steps:"
echo "1. Open Xcode and create new projects using these files"
echo "2. Set up proper bundle identifiers and signing"
echo "3. Test on simulators first"
echo "4. Deploy to your devices"
EOF