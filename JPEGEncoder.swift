import UIKit
import ImageIO
import CoreLocation
import UniformTypeIdentifiers

/// Encodes the stamped image as JPEG and (optionally) embeds real EXIF GPS tags.
enum JPEGEncoder {
    static func encode(_ image: UIImage, quality: Double, location: CLLocation?) -> Data? {
        guard let cg = image.cgImage else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        var props: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        if let location { props[kCGImagePropertyGPSDictionary] = gps(location) }
        CGImageDestinationAddImage(dest, cg, props as CFDictionary)
        return CGImageDestinationFinalize(dest) ? data as Data : nil
    }

    private static func gps(_ loc: CLLocation) -> [CFString: Any] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        var d: [CFString: Any] = [:]
        d[kCGImagePropertyGPSLatitude] = abs(loc.coordinate.latitude)
        d[kCGImagePropertyGPSLatitudeRef] = loc.coordinate.latitude >= 0 ? "N" : "S"
        d[kCGImagePropertyGPSLongitude] = abs(loc.coordinate.longitude)
        d[kCGImagePropertyGPSLongitudeRef] = loc.coordinate.longitude >= 0 ? "E" : "W"
        d[kCGImagePropertyGPSAltitude] = abs(loc.altitude)
        d[kCGImagePropertyGPSAltitudeRef] = loc.altitude >= 0 ? 0 : 1
        df.dateFormat = "HH:mm:ss.SS"
        d[kCGImagePropertyGPSTimeStamp] = df.string(from: loc.timestamp)
        df.dateFormat = "yyyy:MM:dd"
        d[kCGImagePropertyGPSDateStamp] = df.string(from: loc.timestamp)
        return d
    }
}
