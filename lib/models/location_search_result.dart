class LocationSearchResult {
  const LocationSearchResult({
    required this.id,
    required this.type,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.provider,
  });

  final String id;
  final String type;
  final String name;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String provider;

  bool get isPlace => type == 'PLACE';
}
