# GeoStamp Cam

SwiftUI iOS camera that stamps photos with map, address, GPS, date/time, altitude,
compass, weather and a custom note/logo. No third-party packages. iOS 16+, Xcode 15+.

## Run it
Option A (XcodeGen): `brew install xcodegen && xcodegen && open GeoStampCam.xcodeproj`
Option B (manual): new Xcode iOS App (SwiftUI) named GeoStampCam, delete its default
Swift files, drag the `GeoStampCam/` source folders in, and add these Info.plist keys:
NSCameraUsageDescription, NSLocationWhenInUseUsageDescription, NSPhotoLibraryAddUsageDescription.
Set a signing team and run on a real device (camera/GPS don't work in the simulator).

## Module map (what to edit for what)
| Want to change...                        | Edit this file |
|------------------------------------------|----------------|
| Which options exist / defaults           | Core/Models/StampConfig.swift |
| Wording of stamp lines                   | Core/Utilities/StampTextBuilder.swift |
| Look of the stamp (layout, fonts, logo)  | Core/Services/StampRenderer.swift |
| Weather source                           | Core/Services/WeatherService.swift |
| Map look / zoom level                    | Core/Services/MapSnapshotService.swift |
| GPS / address logic                      | Core/Services/LocationService.swift |
| Camera behaviour (zoom, flash, lenses)   | Core/Services/CameraService.swift |
| Where/how photos are saved               | Core/Services/PhotoLibraryService.swift |
| EXIF / JPEG output                       | Core/Utilities/JPEGEncoder.swift |
| Capture pipeline order                   | Features/Camera/CameraViewModel.swift |
| Camera screen UI                         | Features/Camera/* |
| Settings screen                          | Features/Settings/StampSettingsView.swift |
| Which implementations are used           | App/AppContainer.swift |

Services sit behind protocols (WeatherProviding, MapSnapshotting, ImageStamping,
PhotoSaving), so any of them can be replaced in AppContainer without touching the rest.

## Not included yet (good next modules)
Video recording, templates/presets, landscape support, ultra-wide lens, PDF reports,
cloud backup, tamper-evident hashing/signing of photos, in-app gallery, subscriptions.
