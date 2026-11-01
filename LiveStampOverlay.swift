import SwiftUI

/// Approximate live preview of the stamp (final look is drawn by StampRenderer).
struct LiveStampOverlay: View {
    @ObservedObject var location: LocationService
    @ObservedObject var settings: SettingsStore

    var body: some View {
        let config = settings.config
        let lines = StampTextBuilder.lines(snapshot: location.snapshot, config: config)
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(.system(size: 11, weight: index == 0 ? .bold : .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(config.backgroundOpacity))
        .frame(maxHeight: .infinity, alignment: config.position == .bottom ? .bottom : .top)
        .allowsHitTesting(false)
    }
}
