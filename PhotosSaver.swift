import Photos
import CoreLocation
import UIKit
import ImageIO
import AVFoundation

// MARK: - Save to the system Photos library

enum PhotosSaver {
    enum SaveError: Error { case denied, failed }

    /// Asks for "add photos" permission (shows the iOS prompt only the first time).
    static func authorize() async throws {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current == .authorized || current == .limited { return }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.denied }
    }

    static func save(jpeg: Data, location: CLLocation?, date: Date) async throws {
        try await authorize()
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.uniformTypeIdentifier = "public.jpeg"
            request.addResource(with: .photo, data: jpeg, options: options)
            request.location = location
            request.creationDate = date
        }
    }

    static func saveVideo(at url: URL, location: CLLocation?, date: Date) async throws {
        try await authorize()
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            request?.location = location
            request?.creationDate = date
        }
    }
}

// MARK: - Safety net

/// If the Photos library refuses (permission off, storage full), the file is kept here instead
/// so a capture is never lost. Visible in the Files app under On My iPhone > GeoStamp Cam.
enum BackupFolder {
    static var directory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GeoStampCam", isDirectory: true)
    }

    private static func filename(date: Date, ext: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd_HHmmss"
        return "GSC_\(f.string(from: date))_\(String(UUID().uuidString.prefix(4))).\(ext)"
    }

    private static func prepare() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    @discardableResult
    static func write(jpeg: Data, date: Date) -> Bool {
        prepare()
        do {
            try jpeg.write(to: directory.appendingPathComponent(filename(date: date, ext: "jpg")), options: .atomic)
            return true
        } catch { return false }
    }

    @discardableResult
    static func move(video url: URL, date: Date) -> Bool {
        prepare()
        do {
            try FileManager.default.moveItem(at: url, to: directory.appendingPathComponent(filename(date: date, ext: "mp4")))
            return true
        } catch { return false }
    }
}

// MARK: - Small thumbnail for the camera screen

enum Thumbnails {
    static func image(from data: Data, maxPixel: Int) -> UIImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }

    static func video(url: URL, maxPixel: Int) -> UIImage? {
        let gen = AVAssetImageGenerator(asset: AVAsset(url: url))
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: maxPixel, height: maxPixel)
        guard let cg = try? gen.copyCGImage(at: CMTime(seconds: 0.2, preferredTimescale: 600), actualTime: nil) else { return nil }
        return UIImage(cgImage: cg)
    }
}
