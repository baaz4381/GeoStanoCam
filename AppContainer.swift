import Foundation

/// Composition root: the ONLY place where concrete services are chosen.
/// Swap any implementation here (e.g. a different weather or map provider).
@MainActor
final class AppContainer: ObservableObject {
    let settings = SettingsStore()
    let weather: WeatherProviding = OpenMeteoWeatherProvider()
    let camera = CameraService()
    lazy var location = LocationService(weatherProvider: weather)

    lazy var cameraViewModel = CameraViewModel(
        camera: camera,
        location: location,
        settings: settings,
        mapService: MapKitSnapshotService(),
        stamper: StampRenderer(),
        saver: PhotoLibrarySaver()
    )
}
