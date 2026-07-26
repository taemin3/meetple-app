import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/api_category_repository.dart';

void main() {
  test('maps category API response to meeting categories', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'code': 2000,
        'message': 'OK',
        'data': [
          {'id': 1, 'name': '운동'},
          {'id': 2, 'name': '스터디'},
        ],
      },
    );
    final repository = ApiCategoryRepository(apiClient: apiClient);

    final categories = await repository.findAll();

    expect(apiClient.path, '/api/v1/categories');
    expect(categories, hasLength(2));
    expect(categories.first.id, 1);
    expect(categories.first.name, '운동');
    expect(categories.last.id, 2);
    expect(categories.last.name, '스터디');
  });

  test('maps category default image URL when present', () async {
    final repository = ApiCategoryRepository(
      apiClient: FakeApiClient(
        response: {
          'status': 200,
          'success': true,
          'data': [
            {
              'id': 1,
              'name': 'exercise',
              'defaultImageUrl':
                  'https://cdn.meetple.com/categories/exercise.png',
            },
          ],
        },
      ),
    );

    final categories = await repository.findAll();

    expect(
      categories.single.defaultImageUrl,
      'https://cdn.meetple.com/categories/exercise.png',
    );
  });

  test('throws ApiException when category API envelope is unsuccessful',
      () async {
    final repository = ApiCategoryRepository(
      apiClient: FakeApiClient(
        response: {
          'status': 500,
          'success': false,
          'message': '카테고리를 불러오지 못했습니다.',
        },
      ),
    );

    expect(
      repository.findAll(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having(
              (error) => error.message,
              'message',
              '카테고리를 불러오지 못했습니다.',
            ),
      ),
    );
  });
}

class FakeApiClient extends ApiClient {
  FakeApiClient({required this.response});

  final Map<String, dynamic> response;
  String? path;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    this.path = path;
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
