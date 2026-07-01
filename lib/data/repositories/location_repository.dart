import '../../models/location_search_result.dart';

abstract interface class LocationRepository {
  Future<List<LocationSearchResult>> search(String query, {int display = 5});
}
