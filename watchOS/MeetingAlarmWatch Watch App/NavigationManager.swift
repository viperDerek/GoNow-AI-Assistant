import Combine
import Combine
import Combine
import Foundation
import CoreLocation
import SwiftUI

class NavigationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastCalculatedDistance: CLLocationDistance?
    var isCalculatingRoute = false
    var lastError: String?
    
    // Buffer time in seconds (default 10 minutes)
    @Published var bufferTimeInMinutes: Int = 10
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationAuthStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func calculateTravelTime(to destination: String, completion: @escaping (TimeInterval, String?) -> Void) {
        guard let currentLocation = currentLocation else {
            self.lastError = "Current location unavailable"
            // Default to 30 minutes if location unavailable
            completion(1800, nil)
            return
        }
        
        isCalculatingRoute = true
        self.lastError = nil
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(destination) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                self.lastError = "Geocoding error: \(error.localizedDescription)"
                completion(1800, nil)
                self.isCalculatingRoute = false
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                self.lastError = "Could not find location for address"
                // Default to 30 minutes if geocoding fails
                completion(1800, nil)
                self.isCalculatingRoute = false
                return
            }
            
            let formattedAddress = [
                placemark.thoroughfare,
                placemark.locality,
                placemark.administrativeArea,
                placemark.postalCode,
                placemark.country
            ].compactMap { $0 }.joined(separator: ", ")
            
            self.calculateRoute(from: currentLocation, to: location) { travelTime, distance in
                self.isCalculatingRoute = false
                if let distance = distance {
                    self.lastCalculatedDistance = distance
                    completion(travelTime, formattedAddress)
                } else {
                    completion(travelTime, nil)
                }
            }
        }
    }
    
    private func calculateRoute(from source: CLLocation, to destination: CLLocation, completion: @escaping (TimeInterval, CLLocationDistance?) -> Void) {
        // Since MKRoute is not available on watchOS, we'll calculate based on distance
        let distance = source.distance(from: destination)
        self.lastCalculatedDistance = distance
        
        // Estimate travel time based on distance
        // Assume average speed of 50 km/h in city, 80 km/h on highway
        let distanceInKm = distance / 1000
        var estimatedTime: TimeInterval
        
        if distanceInKm < 5 {
            // City driving - 30 km/h average
            estimatedTime = (distanceInKm / 30) * 3600
        } else if distanceInKm < 20 {
            // Mixed driving - 50 km/h average
            estimatedTime = (distanceInKm / 50) * 3600
        } else {
            // Highway driving - 80 km/h average
            estimatedTime = (distanceInKm / 80) * 3600
        }
        
        // Add 20% buffer for traffic and stops
        estimatedTime *= 1.2
        
        // Minimum 5 minutes, maximum 3 hours
        estimatedTime = max(300, min(estimatedTime, 10800))
        
        completion(estimatedTime, distance)
    }
    
    func getFormattedTravelTime(seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours) hr \(remainingMinutes) min"
        }
    }
    
    func getFormattedDistance(meters: CLLocationDistance) -> String {
        let kilometers = meters / 1000
        if kilometers < 1 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", kilometers)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = "Location error: \(error.localizedDescription)"
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.locationAuthStatus = status
        }
    }
}