import UIKit

protocol ImageStamping {
    func stamp(image: UIImage, lines: [String], map: UIImage?, config: StampConfig) -> UIImage
}

/// Draws the banner (map thumbnail + text + optional logo) onto the photo.
/// All sizes scale with image width, so it looks the same at any resolution.
/// Edit this file to change the stamp's look.
struct StampRenderer: ImageStamping {
    func stamp(image: UIImage, lines: [String], map: UIImage?, config: StampConfig) -> UIImage {
        let size = image.size
        let w = size.width
        let pad = w * 0.025
        let fontSize = w * 0.03
        let mapSide: CGFloat = map != nil ? w * 0.22 : 0
        let textX = pad + (mapSide > 0 ? mapSide + pad : 0)
        let textWidth = w - textX - pad

        let text = attributedText(lines, fontSize: fontSize)
        let textBounds = text.boundingRect(with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
                                           options: [.usesLineFragmentOrigin, .usesFontLeading],
                                           context: nil)
        let textHeight = ceil(textBounds.height)
        let bannerH = max(textHeight, mapSide) + pad * 2
        let bannerY: CGFloat = config.position == .bottom ? size.height - bannerH : 0

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            image.draw(in: CGRect(origin: .zero, size: size))

            UIColor.black.withAlphaComponent(config.backgroundOpacity).setFill()
            ctx.fill(CGRect(x: 0, y: bannerY, width: w, height: bannerH))

            if let map {
                ctx.cgContext.saveGState()
                let r = CGRect(x: pad, y: bannerY + pad, width: mapSide, height: mapSide)
                UIBezierPath(roundedRect: r, cornerRadius: pad * 0.4).addClip()
                map.draw(in: r)
                ctx.cgContext.restoreGState()
            }

            let textY = bannerY + (bannerH - textHeight) / 2
            text.draw(in: CGRect(x: textX, y: textY, width: textWidth, height: textHeight + 2))

            if let data = config.logoData, let logo = UIImage(data: data) {
                let box = w * 0.14
                let scale = min(box / logo.size.width, box / logo.size.height)
                let ls = CGSize(width: logo.size.width * scale, height: logo.size.height * scale)
                let y = config.position == .bottom ? bannerY - ls.height - pad : bannerH + pad
                logo.draw(in: CGRect(x: w - pad - ls.width, y: y, width: ls.width, height: ls.height))
            }
        }
    }

    private func attributedText(_ lines: [String], fontSize: CGFloat) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        let result = NSMutableAttributedString()
        for (i, line) in lines.enumerated() {
            let font = UIFont.systemFont(ofSize: fontSize, weight: i == 0 ? .bold : .medium)
            result.append(NSAttributedString(string: line + (i < lines.count - 1 ? "\n" : ""),
                                             attributes: [.font: font,
                                                          .foregroundColor: UIColor.white,
                                                          .paragraphStyle: style]))
        }
        return result
    }
}
