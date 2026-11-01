import AVFoundation

enum CameraError: LocalizedError {
    case captureFailed
    var errorDescription: String? { "Could not capture the photo." }
}

/// Owns the AVCaptureSession. Knows nothing about stamps or location.
final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published private(set) var position: AVCaptureDevice.Position = .back
    @Published var flashMode: AVCaptureDevice.FlashMode = .off

    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "geostamp.camera.session")
    private var currentInput: AVCaptureDeviceInput?
    private var continuation: CheckedContinuation<Data, Error>?

    /// Returns false if the user denied camera access.
    func requestAccessAndConfigure() async -> Bool {
        var granted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            granted = await AVCaptureDevice.requestAccess(for: .video)
        }
        guard granted else { return false }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                self.configure(position: .back)
                c.resume()
            }
        }
        return true
    }

    func start() { sessionQueue.async { if !self.session.isRunning { self.session.startRunning() } } }
    func stop() { sessionQueue.async { if self.session.isRunning { self.session.stopRunning() } } }

    func switchCamera() {
        let next: AVCaptureDevice.Position = position == .back ? .front : .back
        sessionQueue.async {
            self.configure(position: next)
            DispatchQueue.main.async { self.position = next }
        }
    }

    func cycleFlash() {
        switch flashMode {
        case .off: flashMode = .auto
        case .auto: flashMode = .on
        default: flashMode = .off
        }
    }

    func setZoom(_ factor: CGFloat) {
        sessionQueue.async {
            guard let device = self.currentInput?.device else { return }
            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 10)
            try? device.lockForConfiguration()
            device.videoZoomFactor = max(1, min(factor, maxZoom))
            device.unlockForConfiguration()
        }
    }

    func capturePhoto() async throws -> Data {
        let flash = flashMode
        return try await withCheckedThrowingContinuation { cont in
            sessionQueue.async {
                guard self.continuation == nil else {
                    cont.resume(throwing: CameraError.captureFailed)
                    return
                }
                self.continuation = cont
                let settings = AVCapturePhotoSettings()
                if self.output.supportedFlashModes.contains(flash) { settings.flashMode = flash }
                self.output.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    private func configure(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let old = currentInput { session.removeInput(old) }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }
        if !session.outputs.contains(output), session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        sessionQueue.async {
            let cont = self.continuation
            self.continuation = nil
            if let error { cont?.resume(throwing: error) }
            else if let data = photo.fileDataRepresentation() { cont?.resume(returning: data) }
            else { cont?.resume(throwing: CameraError.captureFailed) }
        }
    }
}
