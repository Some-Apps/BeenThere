import 'dart:convert';
import 'dart:math' show log, max, ln2;
import 'package:been_there/models/chunk.dart';
import 'package:been_there/view_models/auth_view_model.dart';
import 'package:been_there/view_models/location_provider.dart';
import 'package:been_there/view_models/location_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:fluttertoast/fluttertoast.dart'; // For displaying toasts

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage>
    with AutomaticKeepAliveClientMixin<MapPage>, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true; // Ensures the state is preserved

  MapboxMap? _mapboxMap;
  bool _isMapReady = false;
  CameraOptions? _savedCameraOptions;
  late PointAnnotationManager _pointAnnotationManager;
  PointAnnotation? _currentLocationAnnotation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set your Mapbox access token
    MapboxOptions.setAccessToken("YOUR_MAPBOX_ACCESS_TOKEN"); // Replace with your actual token
  }

  @override
  void dispose() {
    if (_mapboxMap != null) {
      // Save the current camera position
      _mapboxMap!.getCameraState().then((cameraState) {
        _savedCameraOptions = CameraOptions(
          center: cameraState.center,
          zoom: cameraState.zoom,
          bearing: cameraState.bearing,
          pitch: cameraState.pitch,
        );
      });
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final appUser = ref.watch(appUserProvider);

    if (appUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    final locationChunksAsyncValue = ref.watch(locationViewModelProvider(appUser.id));
    
    final locationChunks = locationChunksAsyncValue;
    if (locationChunks.isEmpty) {
      return const CircularProgressIndicator(); // Show a loading indicator
    }

    // Compute initial camera options based on the chunks
    final cameraOptions = CameraOptions(
      center: Point(coordinates: Position(0, 0)),
      zoom: 1,
      bearing: 0,
      pitch: 0,
    );

    // Listen to location updates
    final locationAsyncValue = ref.watch(locationProvider);

    locationAsyncValue.when(
      data: (position) {
        if (_mapboxMap != null) {
          _updateUserLocationOnMap(position);
        }
      },
      loading: () {
        // Optionally, show a loading indicator or do nothing
      },
      error: (error, stack) {
        // Handle errors, possibly show a toast
        print('Error fetching location: $error');
        Fluttertoast.showToast(
          msg: 'Error fetching location: $error',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: cameraOptions,
            styleUri: MediaQuery.of(context).platformBrightness == Brightness.dark
                ? "mapbox://styles/jaredjones/clot6czi600kb01qq4arcfy2g"
                : "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p",
            onMapCreated: (mapboxMap) async {
              _mapboxMap = mapboxMap;
              _isMapReady = true;

              // Initialize PointAnnotationManager
              _pointAnnotationManager =
                  await _mapboxMap!.annotations.createPointAnnotationManager();

              // Update chunks on map
              _updateChunksOnMap(_mapboxMap!, locationChunks);

              // Add grid lines
              _addGridLines(_mapboxMap!);

            },
            onMapLoadedListener: (mapboxMap) async {
              _centerMapOnChunks();
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centerMapOnChunks,
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
        ],
      ),
    );
  }

  // /// Computes the initial camera options based on the chunks
  // CameraOptions _computeInitialCameraOptions(List<Chunk> chunks) {
  //   double minLat = double.infinity;
  //   double maxLat = double.negativeInfinity;
  //   double minLng = double.infinity;
  //   double maxLng = double.negativeInfinity;

  //   for (var chunk in chunks) {
  //     if (chunk.lowLatitude < minLat) minLat = chunk.lowLatitude;
  //     if (chunk.highLatitude > maxLat) maxLat = chunk.highLatitude;
  //     if (chunk.lowLongitude < minLng) minLng = chunk.lowLongitude;
  //     if (chunk.highLongitude > maxLng) maxLng = chunk.highLongitude;
  //   }

  //   double centerLat = (minLat + maxLat) / 2;
  //   double centerLng = (minLng + maxLng) / 2;

  //   // Estimate zoom level (adjust as needed)
  //   double deltaLat = maxLat - minLat;
  //   double deltaLng = maxLng - minLng;
  //   double maxDelta = max(deltaLat, deltaLng);
  //   double zoom = (maxDelta > 0) ? (11 - (log(maxDelta) / ln2)) : 14;
  //   zoom = zoom.clamp(0.0, 22.0);

  //   return CameraOptions(
  //     center: Point(coordinates: Position(centerLng, centerLat)),
  //     zoom: zoom,
  //     bearing: 0,
  //     pitch: 0,
  //   );
  // }

  /// Updates or adds a Point Annotation representing the user's current location.
  Future<void> _updateUserLocationOnMap(geo.Position position) async {
    if (!_isMapReady || _pointAnnotationManager == null) return;

    final coordinates = Point(coordinates: Position(position.longitude, position.latitude));

    // Define the annotation options
    final annotationOptions = PointAnnotationOptions(
      geometry: coordinates,
      iconImage: "marker-15", // Use a default marker or a custom one
      iconSize: 1.5,
      iconColor: Colors.red.value, // Red color for visibility
    );

    if (_currentLocationAnnotation == null) {
      // Add a new annotation for the user's location
      _currentLocationAnnotation = await _pointAnnotationManager.create(annotationOptions);
    } else {
      // Update the existing annotation's position
      _currentLocationAnnotation!.geometry = coordinates;
      await _pointAnnotationManager.update(_currentLocationAnnotation!);
    }
  }

  /// Centers the map on the chunks
  void _centerMapOnChunks() async {
    if (_mapboxMap != null) {
      final appUser = ref.read(appUserProvider);
      if (appUser != null) {
        final locationChunks = ref.read(locationViewModelProvider(appUser.id));
        if (locationChunks.isNotEmpty) {
          double minLat = double.infinity;
          double maxLat = double.negativeInfinity;
          double minLng = double.infinity;
          double maxLng = double.negativeInfinity;

          for (var chunk in locationChunks) {
            if (chunk.lowLatitude < minLat) minLat = chunk.lowLatitude;
            if (chunk.highLatitude > maxLat) maxLat = chunk.highLatitude;
            if (chunk.lowLongitude < minLng) minLng = chunk.lowLongitude;
            if (chunk.highLongitude > maxLng) maxLng = chunk.highLongitude;
          }

          // Create CoordinateBounds with Point objects
          final bounds = CoordinateBounds(
            southwest: Point(coordinates: Position(minLng, minLat)),
            northeast: Point(coordinates: Position(maxLng, maxLat)),
            infiniteBounds: true,
          );

          // Optional padding
          final padding = MbxEdgeInsets(
            top: 10,
            bottom: 10,
            left: 10,
            right: 10,
          );

          // Get camera options to fit bounds
          final cameraOptions = await _mapboxMap!.cameraForCoordinateBounds(
            bounds,
            padding,
            null, // Optional: bearing
            null, // Optional: pitch
            null, // Optional: maxZoom
            null, // Optional: minZoom
          );

          // Animate to the calculated camera position
          _mapboxMap!.flyTo(
            cameraOptions,
            MapAnimationOptions(duration: 1000),
          );
        }
      }
    }
  }

  /// Updates the map with the user's chunks
  void _updateChunksOnMap(MapboxMap mapboxMap, List<Chunk> chunks) async {
    const sourceId = 'chunks-source';
    const layerId = 'chunks-layer';

    // Remove existing source and layer if they exist
    try {
      await mapboxMap.style.removeStyleLayer(layerId);
    } catch (e) {
      print('Error removing layer: $e');
    }
    try {
      await mapboxMap.style.removeStyleSource(sourceId);
    } catch (e) {
      print('Error removing source: $e');
    }

    if (chunks.isEmpty) {
      print('No chunks to display.');
      return;
    }

    // Create GeoJSON data
    final features = chunks.map((chunk) {
      final lowLat = chunk.lowLatitude;
      final highLat = chunk.highLatitude;
      final lowLng = chunk.lowLongitude;
      final highLng = chunk.highLongitude;

      return {
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [lowLng, lowLat],
              [highLng, lowLat],
              [highLng, highLat],
              [lowLng, highLat],
              [lowLng, lowLat],
            ]
          ],
        },
        'properties': {},
      };
    }).toList();

    final geojson = {
      'type': 'FeatureCollection',
      'features': features,
    };

    // Convert the source and layer definitions to JSON strings
    final sourceJson = jsonEncode({
      'type': 'geojson',
      'data': geojson,
    });

    final layerJson = jsonEncode({
      'id': layerId,
      'type': 'fill',
      'source': sourceId,
      'paint': {
        'fill-color': '#00FF00',
        'fill-opacity': 1.0, // Set opacity to 1.0
        'fill-antialias': false, // Disable antialiasing
        'fill-outline-color': 'rgba(0,0,0,0)', // Optional: remove outline
      },
    });

    // Add the GeoJSON source
    try {
      await mapboxMap.style.addStyleSource(sourceId, sourceJson);
      print('Added source');
    } catch (e) {
      print('Error adding source: $e');
    }

    // Get the list of existing layers
    List<StyleObjectInfo?> layers = await mapboxMap.style.getStyleLayers();

    // Find the ID of the 'land' layer
    String? beforeLayerId;
    for (var layer in layers) {
      if (layer?.id == 'land') {
        beforeLayerId = layer?.id;
        break;
      }
    }

    // Optionally, print layer IDs for debugging
    for (var layer in layers) {
      print('Layer ID: ${layer?.id}');
    }

    // Create a LayerPosition object
    LayerPosition? layerPosition;
    if (beforeLayerId != null) {
      layerPosition = LayerPosition(above: beforeLayerId);
      print('Inserting layer above: $beforeLayerId');
    } else {
      print('land layer not found, adding layer on top.');
    }

    // Add the fill layer at the specified position
    try {
      await mapboxMap.style.addStyleLayer(layerJson, layerPosition);
      print('Added layer above land layer');
    } catch (e) {
      print('Error adding layer: $e');
    }
  }

  /// Adds grid lines to the map
  void _addGridLines(MapboxMap mapboxMap) async {
    const gridSourceId = 'grid-source';
    const gridLayerId = 'grid-layer';

    // Remove existing grid source and layer if they exist
    try {
      await mapboxMap.style.removeStyleLayer(gridLayerId);
    } catch (e) {
      print('Error removing grid layer: $e');
    }
    try {
      await mapboxMap.style.removeStyleSource(gridSourceId);
    } catch (e) {
      print('Error removing grid source: $e');
    }

    // Create GeoJSON data for grid lines
    final features = <Map<String, dynamic>>[];
    for (double lat = -90; lat <= 90; lat += 0.25) {
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [-180, lat],
            [180, lat],
          ],
        },
        'properties': {},
      });
    }
    for (double lng = -180; lng <= 180; lng += 0.25) {
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [lng, -90],
            [lng, 90],
          ],
        },
        'properties': {},
      });
    }

    final geojson = {
      'type': 'FeatureCollection',
      'features': features,
    };

    // Convert the source and layer definitions to JSON strings
    final sourceJson = jsonEncode({
      'type': 'geojson',
      'data': geojson,
    });

    final layerJson = jsonEncode({
      'id': gridLayerId,
      'type': 'line',
      'source': gridSourceId,
      'paint': {
        'line-color': '#000000',
        'line-width': 1,
        'line-opacity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          4,
          0,
          40,
          1
        ],
      },
    });

    // Add the GeoJSON source
    try {
      await mapboxMap.style.addStyleSource(gridSourceId, sourceJson);
      print('Added grid source');
    } catch (e) {
      print('Error adding grid source: $e');
    }

    // Add the line layer
    try {
      await mapboxMap.style.addStyleLayer(layerJson, null);
      print('Added grid layer');
    } catch (e) {
      print('Error adding grid layer: $e');
    }
  }
}
