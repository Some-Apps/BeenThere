import SwiftUI
import MapKit
import Foundation

struct MainMapView: View {
    @ObservedObject var accountViewModel = AccountViewModel()
    @State private var cameraPosition = MapCameraPosition.automatic

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
                            CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.lowLongitude)    // Back to the start
                        ]
                    )
                    .foregroundStyle(.red.opacity(0.7))

                    
                }
            }
            .animation(.easeInOut(duration: 0.5), value: accountViewModel.displayedLocations)
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
            }
            .onChange(of: accountViewModel.locations) {
                cameraPosition = MapCameraPosition.automatic
            }
            
            if UIDevice.current.userInterfaceIdiom == .pad {
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
            } else {
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
            }
        }
    }
    
    
    private func centerCoordinate(for location: Location) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: (location.highLatitude + location.lowLatitude) / 2,
            longitude: (location.highLongitude + location.lowLongitude) / 2
        )
    }
}
