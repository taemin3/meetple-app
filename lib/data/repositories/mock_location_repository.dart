import '../../models/location_search_result.dart';
import 'location_repository.dart';

class MockLocationRepository implements LocationRepository {
  const MockLocationRepository();

  static const _locations = [
    LocationSearchResult(
      id: 'mock:place:yeouido-park',
      type: 'PLACE',
      name: '여의도공원',
      category: '공원',
      address: '서울 영등포구 여의공원로 68',
      latitude: 37.5268,
      longitude: 126.9228,
      provider: 'MOCK',
    ),
    LocationSearchResult(
      id: 'mock:place:seoul-forest',
      type: 'PLACE',
      name: '서울숲',
      category: '공원',
      address: '서울 성동구 뚝섬로 273',
      latitude: 37.5444,
      longitude: 127.0374,
      provider: 'MOCK',
    ),
    LocationSearchResult(
      id: 'mock:address:gangnam-station',
      type: 'ADDRESS',
      name: '강남역',
      category: '주소',
      address: '서울 강남구 강남대로 지하 396',
      latitude: 37.4979,
      longitude: 127.0276,
      provider: 'MOCK',
    ),
  ];

  @override
  Future<List<LocationSearchResult>> search(
    String query, {
    int display = 5,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final results = _locations.where((location) {
      return location.name.toLowerCase().contains(normalizedQuery) ||
          location.address.toLowerCase().contains(normalizedQuery);
    }).toList();

    if (results.isEmpty) {
      return _locations.take(display).toList();
    }

    return results.take(display).toList();
  }
}
