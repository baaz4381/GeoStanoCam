import Photos
import CoreLocation

protocol PhotoSaving {
    func save(jpeg: Data, location: CLLocation?) async throws
}

enum SaveError: LocalizedError {
    case notAuthorized
    var errorDescription: String? { "Allow Photos access in Settings to save pictures." }
}

struct PhotoLibrarySaver: PhotoSaving {
    func save(jpeg: Data, location: CLLocation?) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.notAuthorized }
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: jpeg, options: nil)
            request.location = location
        }
    }
}
