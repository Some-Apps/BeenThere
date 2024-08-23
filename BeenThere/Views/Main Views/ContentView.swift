import SwiftUI
import CoreLocation
import FirebaseAuth
import Kingfisher
import MapKit
import FirebaseFirestore

struct ContentView: View {    
    @AppStorage("username") var username = ""
    @AppStorage("appState") var appState = "opening"
    @StateObject var accountViewModel = AccountViewModel()

    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var locationManagerDelegate = LocationManagerDelegate()
    @State private var isNavigationActive = false
    @State private var isKeyboardVisible = false
    @State private var showTestDialog = false
    @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @State private var showSettingsAlert: Bool = false
    @State private var focusedField: Any?
    @State private var showNavigation = false
    @State private var isInteractingWithSlidyView = false
    @State private var showSpeedAlert = false
    @State private var selection = 2

    var usesMetric: Bool {
        let locale = Locale.current
        switch locale.measurementSystem {
        case .metric:
            return true
        case .us, .uk:
            return false
        default:
            return true
        }
    }

    var body: some View {
        TabView(selection: $selection) {
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(1)
            MainMapView()
            .tabItem {
                Label("Map", systemImage: "map")
            }
            .tag(2)
            LeaderboardView()
                .tabItem {
                    Label("Leaderboards", systemImage: "person.3")
                }
                .tag(3)
        }
        .onAppear {
            locationManagerDelegate.requestLocationAccess()
        }
    }
    
    private func requestLocationAccess() {
        locationManagerDelegate.requestLocationAccess()
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }

    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

class LocationManagerDelegate: NSObject, CLLocationManagerDelegate, ObservableObject {
    @ObservedObject var viewModel = AccountViewModel()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    private var locationManager: CLLocationManager?

    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager?.delegate = self
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager?.distanceFilter = 100
        self.locationManager?.startUpdatingLocation()
    }
    
    func requestLocationAccess() {
        locationManager?.requestWhenInUseAuthorization()
    }

    func requestAlways() {
        locationManager?.requestAlwaysAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            self.locationManager?.startUpdatingLocation()
        }
        self.authorizationStatus = status
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        if let newLocation = locations.last {
//            print("Speed Accuracy: \(newLocation.speedAccuracy.description)")
//            print("Speed: \(newLocation.speed.description)")
            if newLocation.speedAccuracy.magnitude < 10 * 0.44704 && newLocation.speedAccuracy != -1 {
                if newLocation.speed <= 100 * 0.44704 && newLocation.speed.magnitude != -1 {
                    checkBeenThere(location: newLocation)
                } else {
                    print("Average speed is over 100 mph. Location not updated.")
                }
            }
        }

    }
    
    func checkBeenThere(location: CLLocation) {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        let increment: Double = 0.25
        
        let lowLatitude = floor(latitude / increment) * increment
        let highLatitude = lowLatitude + increment
        let lowLongitude = floor(longitude / increment) * increment
        let highLongitude = lowLongitude + increment

        let locationExists = viewModel.locations.contains { existingLocation in
            existingLocation.lowLatitude == lowLatitude &&
            existingLocation.highLatitude == highLatitude &&
            existingLocation.lowLongitude == lowLongitude &&
            existingLocation.highLongitude == highLongitude
        }

        if !locationExists {
            print("LOG: Saving to firestore")
            saveLocationToFirestore(lowLat: lowLatitude, highLat: highLatitude, lowLong: lowLongitude, highLong: highLongitude)
        }
    }


    func saveLocationToFirestore(lowLat: Double, highLat: Double, lowLong: Double, highLong: Double) {
        let locationData: [String: Any] = [
            "lowLatitude": lowLat,
            "highLatitude": highLat,
            "lowLongitude": lowLong,
            "highLongitude": highLong
        ]
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found")
            return
        }

        let userDocumentRef = Firestore.firestore().collection("users").document(userID)
        
        userDocumentRef.getDocument { (document, error) in
            if let document = document, document.exists {
                userDocumentRef.updateData([
                    "locations": FieldValue.arrayUnion([locationData])
                ]) { error in
                    if let error = error {
                        print("Error adding location: \(error)")
                    } else {
                        print("Location successfully updated!")
                    }
                }
            } else {
                userDocumentRef.setData([
                    "locations": [locationData]
                ]) { error in
                    if let error = error {
                        print("Error creating document with location: \(error)")
                    } else {
                        print("Document successfully created with location!")
                    }
                }
            }
        }
    }
}

