import 'package:flutter/widgets.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

const isNaverLocationMapSupported = true;

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
    return NaverMap(
      key: const Key('location_picker_map'),
      forceGesture: true,
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: initialCoordinate.toNLatLng(),
          zoom: 16,
        ),
        consumeSymbolTapEvents: false,
        indoorLevelPickerEnable: false,
        locationButtonEnable: false,
        scaleBarEnable: false,
        logoAlign: NLogoAlign.leftBottom,
        logoMargin: const EdgeInsets.all(8),
        contentPadding: const EdgeInsets.only(bottom: 28),
      ),
      onMapReady: (controller) {
        onMapReady(_NaverLocationMapController(controller));
      },
      onMapTapped: (_, latLng) {
        onMapTapped(latLng.toLocationMapCoordinate());
      },
      onCameraIdle: onCameraIdle,
    );
  }
}

class _NaverLocationMapController implements LocationMapController {
  const _NaverLocationMapController(this._controller);

  final NaverMapController _controller;

  @override
  LocationMapCoordinate get cameraTarget {
    return _controller.nowCameraPosition.target.toLocationMapCoordinate();
  }

  @override
  Future<bool> moveTo(LocationMapCoordinate coordinate, {double zoom = 16}) {
    return _controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: coordinate.toNLatLng(),
        zoom: zoom,
      ),
    );
  }
}

extension on LocationMapCoordinate {
  NLatLng toNLatLng() {
    return NLatLng(latitude, longitude);
  }
}

extension on NLatLng {
  LocationMapCoordinate toLocationMapCoordinate() {
    return LocationMapCoordinate(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
