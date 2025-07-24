import Combine
import Combine
import Combine
import Foundation
import EventKit

class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var upcomingEvents: [EKEvent] = []
    @Published var hasCalendarAccess = false
    @Published var selectedCalendars: [EKCalendar] = []
    @Published var isLoading = false
    
    func requestCalendarAccess() {
        if #available(watchOS 10.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasCalendarAccess = granted
                    if granted {
                        self?.loadCalendars()
                        self?.loadUpcomingEvents()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.hasCalendarAccess = granted
                    if granted {
                        self?.loadCalendars()
                        self?.loadUpcomingEvents()
                    }
                }
            }
        }
    }
    
    func loadCalendars() {
        let calendars = eventStore.calendars(for: .event)
        selectedCalendars = calendars
    }
    
    func loadUpcomingEvents() {
        guard hasCalendarAccess else {
            requestCalendarAccess()
            return
        }
        
        isLoading = true
        
        let now = Date()
        // Look for events in the next 14 days
        let endDate = Calendar.current.date(byAdding: .day, value: 14, to: now) ?? now
        
        let calendarsToUse = selectedCalendars.isEmpty ? nil : selectedCalendars
        
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: calendarsToUse
        )
        
        let events = eventStore.events(matching: predicate)
        
        // Filter events with locations and sort by start date
        let eventsWithLocation = events.filter { event in
            return event.location != nil && !event.location!.isEmpty
        }.sorted { $0.startDate < $1.startDate }
        
        DispatchQueue.main.async {
            self.upcomingEvents = eventsWithLocation
            self.isLoading = false
        }
    }
    
    // Get event details including location
    func getEventDetails(for event: EKEvent) -> (title: String, location: String?, startDate: Date, endDate: Date) {
        return (
            title: event.title ?? "No Title",
            location: event.location,
            startDate: event.startDate,
            endDate: event.endDate
        )
    }
    
    // Check if an event has a valid location that can be used for navigation
    func hasValidLocation(_ event: EKEvent) -> Bool {
        guard let location = event.location, !location.isEmpty else {
            return false
        }
        return true
    }
    
    // Refresh events (can be called manually)
    func refreshEvents() {
        loadUpcomingEvents()
    }}
