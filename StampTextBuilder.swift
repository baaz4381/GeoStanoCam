import Foundation

/// Turns a snapshot + config into the text lines shown in the stamp.
/// Used by BOTH the live preview and the final renderer, so they always match.
enum StampTextBuilder {
    static func lines(snapshot: LocationSnapshot?, config: StampConfig, now: Date = Date()) -> [String] {
        let f = config.enabledFields
        var out: [String] = []

        guard let s = snapshot else {
            out.append("Locating…")
            if f.contains(.dateTime) { out.append(format(now, config.dateFormat)) }
            return out
        }

        if f.contains(.address), let a = s.address, !a.isEmpty { out.append(a) }

        if f.contains(.coordinates) {
            out.append(CoordinateFormatter.string(latitude: s.coordinate.latitude,
                                                  longitude: s.coordinate.longitude,
                                                  format: config.coordinateFormat))
        }

        var geo: [String] = []
        if f.contains(.altitude) { geo.append(String(format: "Alt %.0f m", s.location.altitude)) }
        if f.contains(.accuracy) { geo.append(String(format: "Acc ±%.0f m", s.location.horizontalAccuracy)) }
        if f.contains(.compass), let h = s.heading { geo.append(String(format: "%.0f° %@", h, cardinal(h))) }
        if !geo.isEmpty { out.append(geo.joined(separator: "  •  ")) }

        if f.contains(.weather), let w = s.weather {
            let isC = config.temperatureUnit == .celsius
            let t = isC ? w.temperatureC : w.temperatureC * 9 / 5 + 32
            out.append(String(format: "%.0f°%@  Wind %.0f km/h  Hum %.0f%%  %.0f hPa",
                              t, isC ? "C" : "F", w.windKph, w.humidity, w.pressureHPa))
        }

        if f.contains(.dateTime) { out.append(format(now, config.dateFormat)) }
        if f.contains(.note), !config.note.isEmpty { out.append(config.note) }
        return out
    }

    static func format(_ date: Date, _ pattern: String) -> String {
        let df = DateFormatter()
        df.dateFormat = pattern
        return df.string(from: date)
    }

    static func cardinal(_ degrees: Double) -> String {
        let names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        return names[Int((degrees + 22.5) / 45) % 8]
    }
}
