import SwiftUI
import AVFoundation

struct CameraTopBar: View {
    @ObservedObject var camera: CameraService
    var onSettings: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            Button { camera.cycleFlash() } label: { Image(systemName: flashIcon) }
            Spacer()
            Button { camera.switchCamera() } label: { Image(systemName: "arrow.triangle.2.circlepath.camera") }
            Button(action: onSettings) { Image(systemName: "slider.horizontal.3") }
        }
        .font(.title3)
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var flashIcon: String {
        switch camera.flashMode {
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic.fill"
        default: return "bolt.slash.fill"
        }
    }
}
