import Foundation

enum CoordinateFormatter {
    static func string(latitude: Double, longitude: Double, format: CoordinateFormat) -> String {
        switch format {
        case .decimal:
            return String(format: "Lat %.6f°  Long %.6f°", latitude, longitude)
        case .dms:
            return "\(dms(latitude, pos: "N", neg: "S"))  \(dms(longitude, pos: "E", neg: "W"))"
        }
    }

    private static func dms(_ value: Double, pos: String, neg: String) -> String {
        let a = abs(value)
        let d = Int(a)
        let mFull = (a - Double(d)) * 60
        let m = Int(mFull)
        let s = (mFull - Double(m)) * 60
        return String(format: "%d°%02d'%05.2f\"%@", d, m, s, value >= 0 ? pos : neg)
    }
}
