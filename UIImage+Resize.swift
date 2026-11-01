import UIKit

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let scale = min(1, maxDimension / max(size.width, size.height))
        guard scale < 1 else { return self }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
