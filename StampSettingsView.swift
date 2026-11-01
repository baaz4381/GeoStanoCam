import SwiftUI
import PhotosUI

struct StampSettingsView: View {
    @ObservedObject var store: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var logoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Stamp content") {
                    ForEach(StampField.allCases) { field in
                        Toggle(field.title, isOn: binding(for: field))
                    }
                }

                Section("Format") {
                    Picker("Coordinates", selection: $store.config.coordinateFormat) {
                        ForEach(CoordinateFormat.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Date & time", selection: $store.config.dateFormat) {
                        ForEach(StampConfig.dateFormatPresets, id: \.self) { pattern in
                            Text(StampTextBuilder.format(Date(), pattern)).tag(pattern)
                        }
                    }
                    Picker("Temperature", selection: $store.config.temperatureUnit) {
                        ForEach(TemperatureUnit.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Map style", selection: $store.config.mapStyle) {
                        ForEach(MapStyleOption.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section("Note") {
                    TextField("Custom note (e.g. site name)", text: $store.config.note)
                }

                Section("Appearance") {
                    Picker("Position", selection: $store.config.position) {
                        ForEach(StampPosition.allCases) { Text($0.title).tag($0) }
                    }
                    VStack(alignment: .leading) {
                        Text("Background opacity")
                        Slider(value: $store.config.backgroundOpacity, in: 0.1...0.9)
                    }
                    PhotosPicker(selection: $logoItem, matching: .images) {
                        Text(store.config.logoData == nil ? "Choose logo" : "Change logo")
                    }
                    if store.config.logoData != nil {
                        Button("Remove logo", role: .destructive) { store.config.logoData = nil }
                    }
                }

                Section("Output") {
                    Toggle("Write GPS to photo metadata", isOn: $store.config.writeGPSMetadata)
                    VStack(alignment: .leading) {
                        Text("JPEG quality")
                        Slider(value: $store.config.jpegQuality, in: 0.5...1.0)
                    }
                }
            }
            .navigationTitle("Stamp Settings")
            .toolbar { Button("Done") { dismiss() } }
            .onChange(of: logoItem) { item in
                Task {
                    guard let data = try? await item?.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    store.config.logoData = image.resized(maxDimension: 512).pngData()
                }
            }
        }
    }

    private func binding(for field: StampField) -> Binding<Bool> {
        Binding(
            get: { store.config.enabledFields.contains(field) },
            set: { on in
                if on { store.config.enabledFields.insert(field) }
                else { store.config.enabledFields.remove(field) }
            }
        )
    }
}
