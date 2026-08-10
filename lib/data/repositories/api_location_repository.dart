import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/location_search_result.dart';
import 'location_repository.dart';

class ApiLocationRepository implements LocationRepository {
  ApiLocationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  ApiLocationRepository.withBaseUrl({
    String baseUrl = AppConfig.apiBaseUrl,
    AccessTokenProvider? accessTokenProvider,
    UnauthorizedTokenRefresher? unauthorizedTokenRefresher,
  }) : this(
          apiClient: HttpApiClient(
            baseUri: Uri.parse(baseUrl),
            accessTokenProvider: accessTokenProvider,
            unauthorizedTokenRefresher: unauthorizedTokenRefresher,
          ),
        );

  final ApiClient _apiClient;

  @override
  Future<List<LocationSearchResult>> search(
    String query, {
    int display = 5,
  }) async {
    final response = await _apiClient.getJson(
      '/api/v1/locations/search',
      queryParameters: {
        'query': query.trim(),
        'display': display.toString(),
      },
    );

    _ensureSuccess(response);

    final data = _readList(response['data'], 'data');
    return [
      for (final item in data) _locationFromJson(_readMap(item, 'data[]')),
    ];
  }

  @override
  Future<LocationSearchResult> reverse({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.getJson(
      '/api/v1/locations/reverse',
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );

    _ensureSuccess(response);

    return _locationFromJson(_readMap(response['data'], 'data'));
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw ApiException(
        statusCode: _readInt(response['status']),
        message:
            _readString(response['message'], fallback: 'API request failed.'),
        body: response,
      );
    }
  }

  LocationSearchResult _locationFromJson(Map<String, dynamic> json) {
    return LocationSearchResult(
      id: _readString(json['id']),
      type: _readString(json['type'], fallback: 'PLACE'),
      name: _readString(json['name'], fallback: '장소명 없음'),
      category: _readString(json['category']),
      address: _readString(json['address'], fallback: '주소 미정'),
      latitude: _readDouble(json['latitude']),
      longitude: _readDouble(json['longitude']),
      provider: _readString(json['provider'], fallback: 'NAVER'),
    );
  }

  Map<String, dynamic> _readMap(Object? value, String fieldName) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    throw FormatException('Expected $fieldName to be an object.');
  }

  List<Object?> _readList(Object? value, String fieldName) {
    if (value is List) {
      return value;
    }

    throw FormatException('Expected $fieldName to be a list.');
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  double _readDouble(Object? value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return fallback;
  }
}
