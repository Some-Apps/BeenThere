// lib/providers/location_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationProvider = StreamProvider<Position>((ref) async* {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Prompt the user to enable location services.
    Geolocator.openLocationSettings();
    throw Exception('Location services are disabled.');
  }

  // Check location permissions.
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, throw an exception.
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When permissions are granted, start listening to location updates.
  yield* Geolocator.getPositionStream(locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 10,
  )).handleError((error) {
    // Handle any errors that occur during the stream.
    throw Exception('An error occurred: $error');
  }
  );
});
