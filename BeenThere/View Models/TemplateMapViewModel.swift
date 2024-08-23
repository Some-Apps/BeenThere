//import Foundation
//import CoreLocation
//import FirebaseAuth
//import Firebase
//import Combine
//import SwiftUI
//
//class TemplateMapViewModel: NSObject, ObservableObject {
//    private let speedReadingsKey = "speedReadings"
//
//    
//    @Published var mapSelection: MapSelection = .personal {
//        didSet {
//            observeLocations()
//        }
//    }
//    @Published var friendLocations: [Location] = []
//    @Published var tappedLocation: CLLocationCoordinate2D?
//    @Published var isDarkModeEnabled: Bool = false
//    @Published var locations: [Location] = []
//    
//    @Published var posts: [Post] = []
//    @Published var showTappedLocation: Bool = false {
//        didSet {
//            if !showTappedLocation {
//                tappedLocation = nil
//            }
//        }
//    }
//    var retryCount = 0
//    var lastCameraCenter: CLLocationCoordinate2D?
//    var lastCameraZoom: CGFloat?
//    var lastCameraPitch: CGFloat?
//    var locationManager = CLLocationManager()
//    var currentSquares = Set<String>()
//    var db = Firestore.firestore()
//    var locationsListener: ListenerRegistration?
//    
//    var accountViewModel: AccountViewModel?
//    var cancellable: AnyCancellable?
//    
//
//    init(accountViewModel: AccountViewModel) {
//        super.init()
//        self.accountViewModel = accountViewModel
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.pausesLocationUpdatesAutomatically = false
//        locationManager.startUpdatingLocation()
//        locationManager.startMonitoringSignificantLocationChanges()
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.delegate = self
//        observeLocations()
//        accountViewModel.setUpFirestoreListener()
//    }
//    deinit {
//        locationsListener?.remove()
//    }
//    
//    func observeLocations() {
//        switch mapSelection {
//        case .personal:
//            friendLocations = []
//            cancellable = accountViewModel?.$locations.sink { [weak self] newLocations in
//                self?.locations = newLocations
//                print("LOG: Personal locations updated")
//                self?.addSquaresToMap(locations: newLocations)
//                self?.adjustMapViewToFitSquares()
////                self?.mapSelection = .personal
//            }
//        case .global:
//            friendLocations = []
//            guard let globalLocations = accountViewModel?.userLocations else { return }
////            locations = globalLocations
//            addSquaresToMap(locations: globalLocations)
//            print("LOG: Global locations updated")
//            centerMapOnLocation(location: locationManager.location ?? CLLocation(latitude: 50, longitude: 50))
//        case .friend(let friendID):
//            fetchFriendLocations(id: friendID)
//            addSquaresToMap(locations: friendLocations)
//            adjustMapViewToFitSquares()
//            print("adjusted")
//        }
//    }
//    
//    func fetchFriendLocations(id: String) {
//        guard let accountViewModel = accountViewModel else { return }
//        print("UID: \(id)")
//
//        if let friend = accountViewModel.friends.first(where: { $0["uid"] as? String == id }),
//           let tempFriendLocations = friend["locations"] as? [[String: Any]] {
//            
//            // Convert each dictionary into a Location object
//            friendLocations = tempFriendLocations.compactMap { dict in
//                guard let lowLatitude = dict["lowLatitude"] as? Double,
//                      let highLatitude = dict["highLatitude"] as? Double,
//                      let lowLongitude = dict["lowLongitude"] as? Double,
//                      let highLongitude = dict["highLongitude"] as? Double else {
//                          return nil
//                      }
//                return Location(lowLatitude: lowLatitude, highLatitude: highLatitude, lowLongitude: lowLongitude, highLongitude: highLongitude)
//            }
//        } else {
//            print("friend has no locations")
//            friendLocations = []
//        }
//    }
//   
//
//
//   
//    func addSquaresToMap(locations: [Location]) {
//        guard let mapView = mapView else { return }
//
//        var features = [Feature]()
//        
//        locations.forEach { location in
//            let coordinates = [
//                CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.lowLongitude),
//                CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.highLongitude),
//                CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.highLongitude),
//                CLLocationCoordinate2D(latitude: location.highLatitude, longitude: location.lowLongitude),
//                CLLocationCoordinate2D(latitude: location.lowLatitude, longitude: location.lowLongitude)
//            ]
//            
//            let polygon = Polygon([coordinates])
//            let feature = Feature(geometry: .polygon(polygon))
//            features.append(feature)
//        }
//        
//        let sourceId = "square-source"
//        let layerId = "square-fill-layer"
//        var source = GeoJSONSource()
//        let featureCollection = FeatureCollection(features: features)
//
//        source.data = .featureCollection(FeatureCollection(features: features))
//        
//        let setupLayers = { [weak self] in
//            do {
//                if mapView.mapboxMap.style.sourceExists(withId: sourceId) {
//                            try mapView.mapboxMap.style.updateGeoJSONSource(withId: sourceId, geoJSON: .featureCollection(featureCollection))
//                        } else {
//                            var source = GeoJSONSource()
//                            source.data = .featureCollection(featureCollection)
//                            try mapView.mapboxMap.style.addSource(source, id: sourceId)
//                        }
//                var fillLayer = FillLayer(id: layerId)
//                fillLayer.source = sourceId
//
//                let fillColorExpression = Exp(.interpolate) {
//                    Exp(.linear)
//                    Exp(.zoom)
//                    0
//                    UIColor.green
//                    1
//                    UIColor.green
//                    6
//                    self!.isDarkModeEnabled ? UIColor(red: 0/255, green: 100/255, blue: 0/255, alpha: 1) : UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 1)
//                }
//                fillLayer.fillColor = .expression(fillColorExpression)
//                fillLayer.fillOpacity = .constant(1)
//
//                if mapView.mapboxMap.style.layerExists(withId: layerId) {
//                    try mapView.mapboxMap.style.updateLayer(withId: layerId, type: FillLayer.self) { layer in
//                        layer.fillColor = fillLayer.fillColor
//                        layer.fillOpacity = fillLayer.fillOpacity
//                    }
//                } else {
//                    let landLayerId = mapView.mapboxMap.style.allLayerIdentifiers.first(where: { $0.id.contains("land") || $0.id.contains("landcover") })?.id
//                    if let landLayerId = landLayerId {
//                        try mapView.mapboxMap.style.addLayer(fillLayer, layerPosition: .above(landLayerId))
//                    } else {
//                        try mapView.mapboxMap.style.addLayer(fillLayer)
//                    }
//                }
//
//                self?.currentSquares = Set(features.compactMap { feature in
//                    if case let .string(id) = feature.identifier {
//                        return id
//                    }
//                    return nil
//                })
//            } catch {
//                print("Failed to add or update squares on the map: \(error)")
//            }
//        }
//
//        if mapView.mapboxMap.style.isLoaded {
//            setupLayers()
//        } else {
//            mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
//                setupLayers()
//            }
//        }
//    }
//    
//    func checkAndAddSquaresIfNeeded() {
//        if areSquaresAdded() {
//            addSquaresToMap(locations: locations)
//        }
//    }
//
//
//
//
//
//    private func areSquaresAdded() -> Bool {
//        return locations.count >= 1
//    }
//    
//    func boundingBox(for locations: [Location]) -> (southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D)? {
//        guard !locations.isEmpty else { return nil }
//
//        var minLat = locations.first!.lowLatitude
//        var maxLat = locations.first!.highLatitude
//        var minLong = locations.first!.lowLongitude
//        var maxLong = locations.first!.highLongitude
//
//        for location in locations {
//            minLat = min(minLat, location.lowLatitude)
//            maxLat = max(maxLat, location.highLatitude)
//            minLong = min(minLong, location.lowLongitude)
//            maxLong = max(maxLong, location.highLongitude)
//        }
//
//        let southWest = CLLocationCoordinate2D(latitude: minLat, longitude: minLong)
//        let northEast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLong)
//
//        return (southWest, northEast)
//    }
//    
//    func generateGridlines(insetBy inset: Double = 0.25) -> [LineString] {
//        var gridlines = [LineString]()
//
//        let minLat = -90.0
//        let maxLat = 90.0
//        let minLong = -180.0
//        let maxLong = 180.0
//
//        for lat in stride(from: minLat, through: maxLat, by: inset) {
//            let line = LineString([
//                CLLocationCoordinate2D(latitude: lat, longitude: minLong),
//                CLLocationCoordinate2D(latitude: lat, longitude: maxLong)
//            ])
//            gridlines.append(line)
//        }
//
//        for long in stride(from: minLong, through: maxLong, by: inset) {
//            let line = LineString([
//                CLLocationCoordinate2D(latitude: minLat, longitude: long),
//                CLLocationCoordinate2D(latitude: maxLat, longitude: long)
//            ])
//            gridlines.append(line)
//        }
//
//        return gridlines
//    }
//
//
//    
//    func checkBeenThere(location: CLLocation) {
//        let latitude = location.coordinate.latitude
//        let longitude = location.coordinate.longitude
//
//        let increment: Double = 0.25
//        
//        let lowLatitude = floor(latitude / increment) * increment
//        let highLatitude = lowLatitude + increment
//        let lowLongitude = floor(longitude / increment) * increment
//        let highLongitude = lowLongitude + increment
//
//        let locationExists = locations.contains { existingLocation in
//            existingLocation.lowLatitude == lowLatitude &&
//            existingLocation.highLatitude == highLatitude &&
//            existingLocation.lowLongitude == lowLongitude &&
//            existingLocation.highLongitude == highLongitude
//        }
//
//        if !locationExists {
//            print("LOG: Saving to firestore")
//            saveLocationToFirestore(lowLat: lowLatitude, highLat: highLatitude, lowLong: lowLongitude, highLong: highLongitude)
//        }
//    }
//
//
//    func saveLocationToFirestore(lowLat: Double, highLat: Double, lowLong: Double, highLong: Double) {
//        let locationData: [String: Any] = [
//            "lowLatitude": lowLat,
//            "highLatitude": highLat,
//            "lowLongitude": lowLong,
//            "highLongitude": highLong
//        ]
//        
//        guard let userID = Auth.auth().currentUser?.uid else {
//            print("Error: No authenticated user found")
//            return
//        }
//
//        let userDocumentRef = db.collection("users").document(userID)
//        
//        userDocumentRef.getDocument { (document, error) in
//            if let document = document, document.exists {
//                userDocumentRef.updateData([
//                    "locations": FieldValue.arrayUnion([locationData])
//                ]) { error in
//                    if let error = error {
//                        print("Error adding location: \(error)")
//                    } else {
//                        print("Location successfully updated!")
//                    }
//                }
//            } else {
//                userDocumentRef.setData([
//                    "locations": [locationData]
//                ]) { error in
//                    if let error = error {
//                        print("Error creating document with location: \(error)")
//                    } else {
//                        print("Document successfully created with location!")
//                    }
//                }
//            }
//        }
//    }
//    
//    func layerExists(withId id: String) -> Bool {
//            return mapView?.mapboxMap.style.layerExists(withId: id) ?? false
//        }
//    
//}
//
//extension TemplateMapViewModel: CLLocationManagerDelegate {
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let newLocation = locations.last {
////            print("Speed Accuracy: \(newLocation.speedAccuracy.description)")
////            print("Speed: \(newLocation.speed.description)")
//            if newLocation.speedAccuracy.magnitude < 10 * 0.44704 && newLocation.speedAccuracy != -1 {
//                if newLocation.speed <= 100 * 0.44704 && newLocation.speed.magnitude != -1 {
//                    checkBeenThere(location: newLocation)
//                } else {
//                    print("Average speed is over 100 mph. Location not updated.")
//                }
//            }
//        }
//    }
//}
//
//
//
