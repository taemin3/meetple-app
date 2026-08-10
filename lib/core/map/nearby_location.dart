class NearbyLocation {
  const NearbyLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

abstract interface class NearbyLocationProvider {
  Future<NearbyLocation?> requestCurrentLocation();
}
