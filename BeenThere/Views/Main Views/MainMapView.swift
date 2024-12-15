import SwiftUI
import MapKit
import Foundation
import AlertToast

struct MainMapView: View {
    @EnvironmentObject var accountViewModel: AccountViewModel
    @State private var cameraPosition = MapCameraPosition.automatic
    @State private var showLoadingToast = false

    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(accountViewModel.displayedLocations, id: \.self) { location in
                    MapPolygon(
                        coordinates: [
                            CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.lowLongitude),   // Northwest point
                            CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.highLongitude),   // Northeast point
                            CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.highLongitude),    // Southeast point
                            CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.lowLongitude),     // Southwest point
//                            CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.lowLongitude)    // Back to the start
                        ]
                    )
                    .foregroundStyle(.red.opacity(0.6))

                }
            }
            .animation(.easeInOut(duration: 1), value: accountViewModel.displayedLocations)
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onChange(of: accountViewModel.displayedLocations) {
                cameraPosition = MapCameraPosition.automatic
            }
                Picker("Map Selection", selection: $accountViewModel.mapSelection) {
                    Text("Personal").tag(MapSelection.personal)
                    Text("Global").tag(MapSelection.global)
                    ForEach(accountViewModel.friendList) { friend in
                        if friend.firstName != "" {
                            Text(friend.firstName + " " + friend.lastName)
                                .tag(MapSelection.friend(friend.id))
                        } else {
                            Text("@\(friend.username)")
                                .tag(MapSelection.friend(friend.id))
                        }
                    }
                }
                .background {
                    ContainerRelativeShape().fill(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
        }
    }
    
    func normalizeLatitudeDelta(latitudeDelta: CLLocationDegrees) -> CGFloat {
        // Define the maximum and minimum latitude delta values.
        let maxLatitudeDelta: CLLocationDegrees = 180.0 // Fully zoomed out (world view)
        let minLatitudeDelta: CLLocationDegrees = 0.0005 // Zoomed in very close (about 50 meters)

        // Normalize the latitude delta between 0 and 1.
        let normalizedZoom = CGFloat((latitudeDelta - minLatitudeDelta) / (maxLatitudeDelta - minLatitudeDelta))

        // Clamp the value between 0 and 1 to handle cases where the latitudeDelta is outside the expected range.
        return max(0, min(1, normalizedZoom))
    }
    
    private func centerCoordinate(for location: Location) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: (location.highLatitude + location.lowLatitude) / 2,
            longitude: (location.highLongitude + location.lowLongitude) / 2
        )
    }
}
