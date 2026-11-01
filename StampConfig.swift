import Foundation

/// Everything the user can customise about a stamp. Add new options here,
/// then use them in StampTextBuilder / StampRenderer / StampSettingsView.
/// NOTE: if you rename or remove a property, old saved settings fail to decode
/// and SettingsStore falls back to defaults.
enum StampField: String, Codable, CaseIterable, Identifiable {
    case map, address, coordinates, dateTime, altitude, accuracy, compass, weather, note
    var id: String { rawValue }
    var title: String {
        switch self {
        case .map: return "Map"
        case .address: return "Address"
        case .coordinates: return "Latitude / Longitude"
        case .dateTime: return "Date & Time"
        case .altitude: return "Altitude"
        case .accuracy: return "GPS Accuracy"
        case .compass: return "Compass"
        case .weather: return "Weather"
        case .note: return "Note"
        }
    }
}

enum CoordinateFormat: String, Codable, CaseIterable, Identifiable {
    case decimal, dms
    var id: String { rawValue }
    var title: String { self == .decimal ? "Decimal" : "DMS" }
}

enum StampPosition: String, Codable, CaseIterable, Identifiable {
    case bottom, top
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum TemperatureUnit: String, Codable, CaseIterable, Identifiable {
    case celsius, fahrenheit
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum MapStyleOption: String, Codable, CaseIterable, Identifiable {
    case standard, satellite, hybrid
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct StampConfig: Codable, Equatable {
    var enabledFields: Set<StampField> = [.map, .address, .coordinates, .dateTime]
    var coordinateFormat: CoordinateFormat = .decimal
    var dateFormat: String = "dd MMM yyyy, hh:mm:ss a"
    var position: StampPosition = .bottom
    var temperatureUnit: TemperatureUnit = .celsius
    var mapStyle: MapStyleOption = .standard
    var note: String = ""
    var backgroundOpacity: Double = 0.55
    var writeGPSMetadata: Bool = true
    var jpegQuality: Double = 0.9
    var logoData: Data? = nil

    static let `default` = StampConfig()
    static let dateFormatPresets = [
        "dd MMM yyyy, hh:mm:ss a",
        "yyyy-MM-dd HH:mm:ss",
        "EEE, dd MMM yyyy HH:mm",
        "dd/MM/yyyy HH:mm"
    ]
}
