import Foundation
import CoreLocation
import MapKit

class NavigationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = NavigationManager()
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            authorizationStatus = .denied
        case .authorizedWhenInUse, .authorizedAlways:
            authorizationStatus = .authorizedWhenInUse
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func calculateTravelTime(to destination: String, completion: @escaping (TimeInterval) -> Void) {
        guard let currentLocation = currentLocation else {
            // If no current location, request it and retry
            locationManager.requestLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.calculateTravelTime(to: destination, completion: completion)
            }
            return
        }
        
        // Geocode destination
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(destination) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first,
                  let destinationLocation = placemark.location else {
                print("Failed to geocode destination: \(error?.localizedDescription ?? "Unknown error")")
                completion(30 * 60) // Default 30 minutes
                return
            }
            
            self?.calculateRouteTime(from: currentLocation, to: destinationLocation, completion: completion)
        }
    }
    
    private func calculateRouteTime(from source: CLLocation, to destination: CLLocation, completion: @escaping (TimeInterval) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                completion(route.expectedTravelTime)
            } else {
                print("Failed to calculate route: \(error?.localizedDescription ?? "Unknown error")")
                // Fallback: calculate straight-line distance and estimate
                let distance = source.distance(from: destination)
                let estimatedTime = distance / 13.4 // Assume average 30 mph (13.4 m/s)
                completion(estimatedTime)
            }
        }
    }
    
    func openInMaps(destination: String) {
        let encodedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Try to open in Apple Maps first
        if let url = URL(string: "maps://?daddr=\(encodedDestination)&dirflg=d") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to web maps
        if let url = URL(string: "https://maps.apple.com/?daddr=\(encodedDestination)&dirflg=d") {
            UIApplication.shared.open(url)
        }
    }
    
    func openInKakaoNavi(destination: String) {
        // KakaoNavi URL scheme
        let encodedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "kakaonavi://navigate?destination=\(encodedDestination)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to App Store if KakaoNavi not installed
                if let appStoreURL = URL(string: "https://apps.apple.com/app/kakaonavi/id417698849") {
                    UIApplication.shared.open(appStoreURL)
                }
            }
        }
    }
}