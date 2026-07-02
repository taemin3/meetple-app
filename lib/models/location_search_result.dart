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

  LocationSearchResult copyWith({
    String? id,
    String? type,
    String? name,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    String? provider,
  }) {
    return LocationSearchResult(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      provider: provider ?? this.provider,
    );
  }
}
