import MapKit
import UIKit

protocol MapSnapshotting {
    func snapshot(at coordinate: CLLocationCoordinate2D, style: MapStyleOption) async -> UIImage?
}

struct MapKitSnapshotService: MapSnapshotting {
    var regionMeters: CLLocationDistance = 300
    var side: CGFloat = 400

    func snapshot(at coordinate: CLLocationCoordinate2D, style: MapStyleOption) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: coordinate,
                                            latitudinalMeters: regionMeters,
                                            longitudinalMeters: regionMeters)
        options.size = CGSize(width: side, height: side)
        options.scale = 1
        switch style {
        case .standard: options.mapType = .standard
        case .satellite: options.mapType = .satellite
        case .hybrid: options.mapType = .hybrid
        }
        guard let snap = try? await MKMapSnapshotter(options: options).start() else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: options.size, format: format).image { _ in
            snap.image.draw(at: .zero)
            let p = snap.point(for: coordinate)
            let pin = UIBezierPath(ovalIn: CGRect(x: p.x - 12, y: p.y - 12, width: 24, height: 24))
            UIColor.systemRed.setFill(); pin.fill()
            UIColor.white.setStroke(); pin.lineWidth = 4; pin.stroke()
        }
    }
}
