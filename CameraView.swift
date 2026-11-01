import SwiftUI

struct CameraView: View {
    @ObservedObject var vm: CameraViewModel
    @State private var showSettings = false
    @State private var zoom: CGFloat = 1

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                CameraTopBar(camera: vm.camera) { showSettings = true }

                ZStack {
                    if vm.cameraReady {
                        CameraPreview(session: vm.camera.session)
                        LiveStampOverlay(location: vm.location, settings: vm.settings)
                    } else {
                        Text("Camera access is off.\nEnable it in Settings > Privacy.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    }
                }
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .clipped()

                Spacer(minLength: 0)
                shutterBar
            }

            if let message = vm.statusMessage {
                Text(message)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
            }
        }
        .gesture(
            MagnificationGesture()
                .onChanged { vm.camera.setZoom(zoom * $0) }
                .onEnded { zoom = max(1, min(zoom * $0, 10)) }
        )
        .task { await vm.onAppear() }
        .onDisappear { vm.onDisappear() }
        .sheet(isPresented: $showSettings) { StampSettingsView(store: vm.settings) }
    }

    private var shutterBar: some View {
        HStack {
            Group {
                if let img = vm.lastPhoto {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Color.white.opacity(0.1)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()
            Button {
                Task { await vm.capture() }
            } label: {
                ZStack {
                    Circle().stroke(Color.white, lineWidth: 4).frame(width: 78, height: 78)
                    Circle().fill(vm.isCapturing ? Color.gray : Color.white).frame(width: 64, height: 64)
                }
            }
            .disabled(vm.isCapturing)
            Spacer()
            Color.clear.frame(width: 56, height: 56)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
    }
}
