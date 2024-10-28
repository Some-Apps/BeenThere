import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {

    MapboxOptions.setAccessToken("pk.eyJ1IjoiamFyZWRqb25lcyIsImEiOiJjbTJzZDJuenAxbmJyMmtva2Q2NDczbWwzIn0.BPn3NwsQcUtChJ3HRxqBkw");




    CameraOptions camera = CameraOptions(
        center: Point(coordinates: Position(-98.0, 39.5)),
        zoom: 2,
        bearing: 0,
        pitch: 0);

    return MapWidget(
      cameraOptions: camera,
      styleUri: MediaQuery.of(context).platformBrightness == Brightness.dark
          ? "mapbox://styles/jaredjones/clot6czi600kb01qq4arcfy2g"
          : "mapbox://styles/jaredjones/clot66ah300l501pe2lmbg11p",
    );
  }
}
