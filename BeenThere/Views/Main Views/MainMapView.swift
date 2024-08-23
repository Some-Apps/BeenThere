import SwiftUI
import MapKit
import Foundation

struct MainMapView: View {
    @StateObject var accountViewModel = AccountViewModel()

    var body: some View {
        Map {
            UserAnnotation()
            ForEach(accountViewModel.locations, id: \.self) { location in
                MapPolygon(
                    coordinates: [
                        CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.lowLongitude),   // Northwest point
                        CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.highLongitude),   // Northeast point
                        CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.highLongitude),    // Southeast point
                        CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.lowLongitude),     // Southwest point
                        CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.lowLongitude)    // Back to the start
                    ]
                )
                .foregroundStyle(.red.opacity(0.75))
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
        }
    }
}
