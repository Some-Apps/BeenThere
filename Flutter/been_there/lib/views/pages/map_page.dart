import 'dart:async';
import 'dart:convert';
import 'package:been_there/models/chunk.dart';
import 'package:been_there/view_models/auth_view_model.dart';
import 'package:been_there/view_models/location_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  MapboxMap? _mapboxMap;
  bool _isMapReady = false; // Track map readiness

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(appUserProvider);
    MapboxOptions.setAccessToken("YOUR_MAPBOX_ACCESS_TOKEN");

    // Set initial camera options
    CameraOptions camera = CameraOptions(
      center: Point(coordinates: Position(-98.0, 39.5)),
      zoom: 2,
      bearing: 0,
      pitch: 0,
    );

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: camera,
            styleUri: MediaQuery.of(context).platformBrightness == Brightness.dark
                ? "mapbox://styles/jaredjones/clot6czi600kb01qq4arcfy2g"
                : "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p",
            onMapCreated: (mapboxMap) {
              _mapboxMap = mapboxMap;
              _isMapReady = true;

              final appUser = ref.read(appUserProvider);
              if (appUser != null) {
                final locationChunks = ref.read(locationViewModelProvider(appUser.id));
                if (locationChunks.isNotEmpty) {
                  _updateChunksOnMap(mapboxMap, locationChunks);
                  _addGridLines(mapboxMap);
                  _centerMapOnChunks();
                }
              }
            },
          ),
          // Use ProviderListener to listen for changes in locationChunks
          if (appUser != null)
            Consumer(
              builder: (context, ref, child) {
                final appUser = ref.watch(appUserProvider);
                if (appUser != null) {
                  final locationChunks = ref.watch(locationViewModelProvider(appUser.id));
                  if (_isMapReady && _mapboxMap != null && locationChunks.isNotEmpty) {
                    _updateChunksOnMap(_mapboxMap!, locationChunks);
                    _centerMapOnChunks();
                  }
                }
                return SizedBox.shrink();
              },
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centerMapOnChunks,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

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
            northeast: Point(coordinates: Position(maxLng, maxLat)), infiniteBounds: true,
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

    // Find the ID of the 'landuse' layer
    String? beforeLayerId;
    for (var layer in layers) {
      if (layer?.id == 'landuse') {
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
      print('landuse layer not found, adding layer on top.');
    }

    // Add the fill layer at the specified position
    try {
      await mapboxMap.style.addStyleLayer(layerJson, layerPosition);
      print('Added layer above landuse layer');
    } catch (e) {
      print('Error adding layer: $e');
    }
  }

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
