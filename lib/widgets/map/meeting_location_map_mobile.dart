import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../core/theme/app_colors.dart';
import 'meeting_location_map_fallback.dart';

const isMeetingLocationMapSupported = true;

class MeetingLocationMap extends StatelessWidget {
  const MeetingLocationMap({
    super.key,
    required this.enabled,
    required this.latitude,
    required this.longitude,
  });

  final bool enabled;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const MeetingLocationMapFallback();
    }

    final coordinate = NLatLng(latitude, longitude);

    return NaverMap(
      key: const Key('meeting-location-map'),
      forceGesture: false,
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
        zoomGesturesEnable: false,
        scrollGesturesEnable: false,
        rotationGesturesEnable: false,
        tiltGesturesEnable: false,
        stopGesturesEnable: false,
        logoAlign: NLogoAlign.leftBottom,
        logoMargin: const EdgeInsets.all(6),
      ),
      onMapReady: (controller) async {
        final marker = NMarker(
          id: 'meeting-location',
          position: coordinate,
        );
        marker.setIconTintColor(AppColors.primary);
        await controller.addOverlay(marker);
      },
    );
  }
}
