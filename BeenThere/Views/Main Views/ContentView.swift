import SwiftUI
import CoreLocation
import FirebaseAuth
import Kingfisher
import MapKit

struct ContentView: View {    
    @AppStorage("username") var username = ""
    @AppStorage("appState") var appState = "opening"
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
    @State private var showSplash: Bool = true
    @State private var splashOpacity = 1.0
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
        self.region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
}

