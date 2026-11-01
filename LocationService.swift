import CoreLocation
import Combine

/// Streams GPS + heading, reverse-geocodes the address (throttled) and
/// refreshes weather (every 10 min). Publishes a ready-to-use LocationSnapshot.
@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var snapshot: LocationSnapshot?
    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let weatherProvider: WeatherProviding

    private var latest: CLLocation?
    private var heading: Double?
    private var address: String?
    private var weather: WeatherInfo?
    private var lastGeocodeLocation: CLLocation?
    private var lastGeocodeDate = Date.distantPast
    private var lastWeatherDate = Date.distantPast

    init(weatherProvider: WeatherProviding) {
        self.weatherProvider = weatherProvider
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.headingFilter = 3
        authorization = manager.authorizationStatus
    }

    func start() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        startUpdates()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    fileprivate func startUpdates() {
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { manager.startUpdatingHeading() }
    }

    fileprivate func handle(location: CLLocation) {
        guard location.horizontalAccuracy >= 0 else { return }
        latest = location
        refreshAddressIfNeeded(for: location)
        refreshWeatherIfNeeded(for: location)
        publish()
    }

    fileprivate func handle(heading h: Double) {
        heading = h
        publish()
    }

    private func publish() {
        guard let latest else { return }
        snapshot = LocationSnapshot(location: latest, heading: heading, address: address, weather: weather)
    }

    private func refreshAddressIfNeeded(for loc: CLLocation) {
        let moved = lastGeocodeLocation.map { loc.distance(from: $0) > 30 } ?? true
        let stale = Date().timeIntervalSince(lastGeocodeDate) > 120
        guard (moved || stale), !geocoder.isGeocoding else { return }
        lastGeocodeLocation = loc
        lastGeocodeDate = Date()
        Task {
            let marks = try? await geocoder.reverseGeocodeLocation(loc)
            address = marks?.first.map(Self.format)
            publish()
        }
    }

    private func refreshWeatherIfNeeded(for loc: CLLocation) {
        guard Date().timeIntervalSince(lastWeatherDate) > 600 else { return }
        lastWeatherDate = Date()
        Task {
            if let w = await weatherProvider.current(for: loc) {
                weather = w
                publish()
            }
        }
    }

    private static func format(_ p: CLPlacemark) -> String {
        let street = [p.subThoroughfare, p.thoroughfare].compactMap { $0 }.joined(separator: " ")
        let parts = [street, p.subLocality, p.locality, p.administrativeArea, p.postalCode, p.country]
        return parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in self.handle(location: loc) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in self.handle(heading: h) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if status == .authorizedWhenInUse || status == .authorizedAlways { self.startUpdates() }
        }
    }
}
