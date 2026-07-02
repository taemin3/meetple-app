import 'package:flutter/widgets.dart';

const isNaverLocationMapSupported = false;

class LocationMapCoordinate {
  const LocationMapCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

abstract interface class LocationMapController {
  LocationMapCoordinate get cameraTarget;

  Future<bool> moveTo(LocationMapCoordinate coordinate, {double zoom = 16});
}

class NaverLocationMap extends StatelessWidget {
  const NaverLocationMap({
    super.key,
    required this.initialCoordinate,
    required this.onMapReady,
    required this.onMapTapped,
    required this.onCameraIdle,
  });

  final LocationMapCoordinate initialCoordinate;
  final ValueChanged<LocationMapController> onMapReady;
  final ValueChanged<LocationMapCoordinate> onMapTapped;
  final VoidCallback onCameraIdle;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
