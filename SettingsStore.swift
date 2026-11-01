import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private static let key = "stampConfig.v1"
    private let defaults: UserDefaults

    @Published var config: StampConfig {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        let loaded = defaults.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(StampConfig.self, from: $0) }
        self.defaults = defaults
        self.config = loaded ?? .default
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: Self.key)
        }
    }
}
