import UIKit

enum CaptureError: LocalizedError {
    case decodeFailed, encodeFailed
    var errorDescription: String? {
        switch self {
        case .decodeFailed: return "Could not read the captured photo."
        case .encodeFailed: return "Could not encode the stamped photo."
        }
    }
}

/// The capture pipeline lives here: capture -> map -> text -> stamp -> encode -> save.
/// Each step is a separate service, so you can change one without touching the others.
@MainActor
final class CameraViewModel: ObservableObject {
    @Published var lastPhoto: UIImage?
    @Published var isCapturing = false
    @Published var cameraReady = true
    @Published var statusMessage: String?

    let camera: CameraService
    let location: LocationService
    let settings: SettingsStore
    private let mapService: MapSnapshotting
    private let stamper: ImageStamping
    private let saver: PhotoSaving

    init(camera: CameraService, location: LocationService, settings: SettingsStore,
         mapService: MapSnapshotting, stamper: ImageStamping, saver: PhotoSaving) {
        self.camera = camera
        self.location = location
        self.settings = settings
        self.mapService = mapService
        self.stamper = stamper
        self.saver = saver
    }

    func onAppear() async {
        cameraReady = await camera.requestAccessAndConfigure()
        camera.start()
        location.start()
    }

    func onDisappear() {
        camera.stop()
        location.stop()
    }

    func capture() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        let capturedAt = Date()
        let snapshot = location.snapshot
        let config = settings.config

        do {
            let data = try await camera.capturePhoto()
            guard let raw = UIImage(data: data) else { throw CaptureError.decodeFailed }

            var map: UIImage?
            if config.enabledFields.contains(.map), let snapshot {
                map = await mapService.snapshot(at: snapshot.coordinate, style: config.mapStyle)
            }

            let lines = StampTextBuilder.lines(snapshot: snapshot, config: config, now: capturedAt)
            let stamped = stamper.stamp(image: raw, lines: lines, map: map, config: config)

            let gpsLocation = config.writeGPSMetadata ? snapshot?.location : nil
            guard let jpeg = JPEGEncoder.encode(stamped, quality: config.jpegQuality, location: gpsLocation) else {
                throw CaptureError.encodeFailed
            }
            try await saver.save(jpeg: jpeg, location: gpsLocation)
            lastPhoto = stamped
            flash("Saved to Photos")
        } catch {
            flash(error.localizedDescription)
        }
    }

    private func flash(_ message: String) {
        statusMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if statusMessage == message { statusMessage = nil }
        }
    }
}
