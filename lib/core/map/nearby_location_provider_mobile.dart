import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'nearby_location.dart';

NearbyLocationProvider createNearbyLocationProvider() {
  return const _NaverNearbyLocationProvider();
}

class _NaverNearbyLocationProvider implements NearbyLocationProvider {
  const _NaverNearbyLocationProvider();

  @override
  Future<NearbyLocation?> requestCurrentLocation() async {
    final tracker = NDefaultMyLocationTracker();
    try {
      await tracker.requestLocationPermission();
      final position = await tracker.getCurrentPositionOnce();
      return NearbyLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    } finally {
      tracker.disposeLocationService();
      tracker.unbindAppLifecycleChange();
    }
  }
}
