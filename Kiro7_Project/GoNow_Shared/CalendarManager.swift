import Foundation
import EventKit
import CoreLocation

@MainActor
class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var goNowEvents: [EKEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    init() {
        requestCalendarAccess()
        startMonitoring()
    }
    
    func requestCalendarAccess() {
        Task {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                authorizationStatus = granted ? .fullAccess : .denied
                if granted {
                    loadGoNowEvents()
                }
            } catch {
                print("Calendar access error: \(error)")
                authorizationStatus = .denied
            }
        }
    }
    
    func loadGoNowEvents() {
        let calendar = Calendar.current
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // Filter events with "GoNow" tag in title or notes
        goNowEvents = events.filter { event in
            let hasGoNowTag = event.title?.contains("GoNow") == true || 
                             event.notes?.contains("GoNow") == true ||
                             event.title?.lowercased().contains("gonow") == true
            return hasGoNowTag
        }
        
        // Check for events tomorrow and process them
        checkUpcomingEvents()
    }
    
    private func checkUpcomingEvents() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        
        for event in goNowEvents {
            if calendar.isDate(event.startDate, inSameDayAs: tomorrow) {
                processGoNowEvent(event)
            }
        }
    }
    
    private func processGoNowEvent(_ event: EKEvent) {
        // Check if event has location
        if let location = event.location, !location.isEmpty {
            // Calculate travel time 3 hours before event
            let threeHoursBefore = event.startDate.addingTimeInterval(-3 * 60 * 60)
            
            if Date() >= threeHoursBefore {
                NavigationManager.shared.calculateTravelTime(to: location) { [weak self] travelTime in
                    DispatchQueue.main.async {
                        self?.scheduleAlarm(for: event, travelTime: travelTime)
                    }
                }
            }
        } else {
            // Request location from user
            requestLocationForEvent(event)
        }
    }
    
    private func requestLocationForEvent(_ event: EKEvent) {
        // This would trigger a notification or UI prompt for location
        NotificationCenter.default.post(
            name: NSNotification.Name("RequestLocationForEvent"),
            object: event
        )
    }
    
    private func scheduleAlarm(for event: EKEvent, travelTime: TimeInterval) {
        // Calculate departure time (event time - travel time - 10 minutes buffer)
        let bufferTime: TimeInterval = 10 * 60 // 10 minutes
        let departureTime = event.startDate.addingTimeInterval(-(travelTime + bufferTime))
        
        AlarmManager.shared.scheduleAlarm(
            at: departureTime,
            title: "Time to leave for \(event.title ?? "Event")",
            message: "You should leave now to arrive on time"
        )
    }
    
    private func startMonitoring() {
        // Monitor calendar changes
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            self?.loadGoNowEvents()
        }
        
        // Check every hour for upcoming events
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.loadGoNowEvents()
        }
    }
    
    func addLocationToEvent(_ event: EKEvent, location: String) {
        do {
            event.location = location
            try eventStore.save(event, span: .thisEvent)
            loadGoNowEvents() // Refresh events
        } catch {
            print("Failed to update event location: \(error)")
        }
    }
}