import SwiftUI

@main
struct GeoStampCamApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            CameraView(vm: container.cameraViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
