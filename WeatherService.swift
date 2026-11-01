import CoreLocation

protocol WeatherProviding {
    func current(for location: CLLocation) async -> WeatherInfo?
}

/// Free, key-less provider (https://open-meteo.com). Replace with WeatherKit
/// or any other API by implementing WeatherProviding.
struct OpenMeteoWeatherProvider: WeatherProviding {
    private struct Response: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let relative_humidity_2m: Double
            let surface_pressure: Double
            let wind_speed_10m: Double
        }
        let current: Current
    }

    func current(for location: CLLocation) async -> WeatherInfo? {
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m")
        ]
        guard let url = comps.url else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        guard let r = try? JSONDecoder().decode(Response.self, from: data) else { return nil }
        return WeatherInfo(temperatureC: r.current.temperature_2m,
                           windKph: r.current.wind_speed_10m,
                           humidity: r.current.relative_humidity_2m,
                           pressureHPa: r.current.surface_pressure)
    }
}
