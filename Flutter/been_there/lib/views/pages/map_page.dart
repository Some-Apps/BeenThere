// map_page.dart
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

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(appUserProvider);
    MapboxOptions.setAccessToken(
        "pk.eyJ1IjoiamFyZWRqb25lcyIsImEiOiJjbTJzZDJuenAxbmJyMmtva2Q2NDczbWwzIn0.BPn3NwsQcUtChJ3HRxqBkw");

    CameraOptions camera = CameraOptions(
        center: Point(coordinates: Position(-98.0, 39.5)), // This is the geotypes Position
        zoom: 2,
        bearing: 0,
        pitch: 0);
    print('appUser: ${appUser?.id}');

    final locationChunks = ref.watch(locationViewModelProvider(appUser!.id));

    // Update the map whenever locationChunks change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapboxMap != null) {
        _updateChunksOnMap(_mapboxMap!, locationChunks);
      }
    });

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
              _updateChunksOnMap(mapboxMap, locationChunks);
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centerMapOnUserLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  void _centerMapOnUserLocation() async {
    // Assuming you have a method to get the user's current location
    final userLocation = await _getUserCurrentLocation();
    if (userLocation != null && _mapboxMap != null) {
      _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(userLocation.longitude, userLocation.latitude)), // This is the geotypes Position
          zoom: 14,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  Future<geo.Position> _getUserCurrentLocation() async {
    // Implement your logic to get the user's current location
    // For example, using the geolocator package
    final position = await geo.Geolocator.getCurrentPosition();
    return position;
    // return Position(-98.0, 39.5); // Placeholder for user location
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

    // Debugging: Print GeoJSON data
    print('GeoJSON data: ${jsonEncode(geojson)}');

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
        'fill-opacity': 0.5,
      },
    });

    // Add the GeoJSON source
    try {
      await mapboxMap.style.addStyleSource(sourceId, sourceJson);
      print('Added source');
    } catch (e) {
      print('Error adding source: $e');
    }

    // Add the fill layer
    try {
      await mapboxMap.style.addStyleLayer(layerJson, null);
      print('Added layer');
    } catch (e) {
      print('Error adding layer: $e');
    }
  }
}