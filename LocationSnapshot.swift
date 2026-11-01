import CoreLocation

struct WeatherInfo: Equatable {
    var temperatureC: Double
    var windKph: Double
    var humidity: Double
    var pressureHPa: Double
}

/// A point-in-time bundle of everything the stamp can show.
struct LocationSnapshot {
    var location: CLLocation
    var heading: Double?
    var address: String?
    var weather: WeatherInfo?

    var coordinate: CLLocationCoordinate2D { location.coordinate }
}
