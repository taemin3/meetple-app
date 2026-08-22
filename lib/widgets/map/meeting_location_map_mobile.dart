import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'meeting_location_map_fallback.dart';

const isMeetingLocationMapSupported = true;

class MeetingLocationMap extends StatelessWidget {
  const MeetingLocationMap({
    super.key,
    required this.enabled,
    required this.latitude,
    required this.longitude,
    this.interactive = false,
    this.showMarker = false,
  });

  final bool enabled;
  final double latitude;
  final double longitude;
  final bool interactive;
  final bool showMarker;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const MeetingLocationMapFallback();
    }

    final coordinate = NLatLng(latitude, longitude);

    return NaverMap(
      key: const Key('meeting-location-map'),
      forceGesture: interactive,
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: coordinate,
          zoom: 15.5,
        ),
        consumeSymbolTapEvents: false,
        indoorLevelPickerEnable: false,
        locationButtonEnable: false,
        scaleBarEnable: false,
        compassEnable: false,
        zoomGesturesEnable: interactive,
        scrollGesturesEnable: interactive,
        rotationGesturesEnable: interactive,
        tiltGesturesEnable: interactive,
        stopGesturesEnable: interactive,
        logoAlign: NLogoAlign.leftBottom,
        logoMargin: const EdgeInsets.all(6),
      ),
      onMapReady: (controller) async {
        if (!showMarker) return;
        await controller.addOverlay(
          NMarker(
            id: 'meeting-location-marker',
            position: coordinate,
          ),
        );
      },
    );
  }
}
