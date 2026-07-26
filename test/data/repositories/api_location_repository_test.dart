import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/api_location_repository.dart';

void main() {
  test('maps location search API response to location results', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'code': 2000,
        'message': 'OK',
        'data': [
          {
            'id': 'naver:place:1',
            'type': 'PLACE',
            'name': '여의도공원',
            'category': '공원',
            'address': '서울 영등포구 여의공원로 68',
            'latitude': 37.5268,
            'longitude': 126.9228,
            'provider': 'NAVER',
          },
        ],
      },
    );
    final repository = ApiLocationRepository(apiClient: apiClient);

    final locations = await repository.search('여의도공원', display: 5);

    expect(apiClient.path, '/api/v1/locations/search');
    expect(apiClient.queryParameters, {
      'query': '여의도공원',
      'display': '5',
    });
    expect(locations, hasLength(1));
    expect(locations.single.id, 'naver:place:1');
    expect(locations.single.type, 'PLACE');
    expect(locations.single.name, '여의도공원');
    expect(locations.single.address, '서울 영등포구 여의공원로 68');
    expect(locations.single.latitude, 37.5268);
    expect(locations.single.longitude, 126.9228);
    expect(locations.single.provider, 'NAVER');
  });

  test('maps reverse location API response to location result', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'code': 2000,
        'message': 'OK',
        'data': {
          'id': 'naver:reverse:1',
          'type': 'ADDRESS',
          'name': '서울 영등포구 여의도동',
          'category': '주소',
          'address': '서울 영등포구 여의공원로 68',
          'latitude': 37.527,
          'longitude': 126.923,
          'provider': 'NAVER',
        },
      },
    );
    final repository = ApiLocationRepository(apiClient: apiClient);

    final location = await repository.reverse(
      latitude: 37.527,
      longitude: 126.923,
    );

    expect(apiClient.path, '/api/v1/locations/reverse');
    expect(apiClient.queryParameters, {
      'latitude': '37.527',
      'longitude': '126.923',
    });
    expect(location.id, 'naver:reverse:1');
    expect(location.type, 'ADDRESS');
    expect(location.name, '서울 영등포구 여의도동');
    expect(location.address, '서울 영등포구 여의공원로 68');
    expect(location.latitude, 37.527);
    expect(location.longitude, 126.923);
    expect(location.provider, 'NAVER');
  });

  test('throws ApiException when location API envelope is unsuccessful',
      () async {
    final repository = ApiLocationRepository(
      apiClient: FakeApiClient(
        response: {
          'status': 401,
          'success': false,
          'message': '인증이 필요합니다.',
        },
      ),
    );

    expect(
      repository.search('여의도공원'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.message, 'message', '인증이 필요합니다.'),
      ),
    );
  });
}

class FakeApiClient extends ApiClient {
  FakeApiClient({required this.response});

  final Map<String, dynamic> response;
  String? path;
  Map<String, String?>? queryParameters;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    this.path = path;
    this.queryParameters = queryParameters;
    return response;
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  }) {
    throw UnsupportedError('postJson is not used in this test.');
  }
}
