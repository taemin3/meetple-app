import 'nearby_location.dart';

NearbyLocationProvider createNearbyLocationProvider() {
  return const _UnsupportedNearbyLocationProvider();
}

class _UnsupportedNearbyLocationProvider implements NearbyLocationProvider {
  const _UnsupportedNearbyLocationProvider();

  @override
  Future<NearbyLocation?> requestCurrentLocation() async => null;
}
