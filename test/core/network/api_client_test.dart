import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meetple/core/network/api_client.dart';

void main() {
  test('builds GET request with base URL, query, and bearer token', () async {
    final client = HttpApiClient(
      baseUri: Uri.parse('http://localhost:8080'),
      accessTokenProvider: () => 'access-token',
      httpClient: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:8080/api/v1/meetings?page=0&size=20',
        );
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Authorization'], 'Bearer access-token');

        return http.Response('{"success":true}', 200);
      }),
    );

    final response = await client.getJson(
      '/api/v1/meetings',
      queryParameters: {
        'status': null,
        'page': '0',
        'size': '20',
      },
    );

    expect(response['success'], true);
  });

  test('throws ApiException for non-success status code', () {
    final client = HttpApiClient(
      baseUri: Uri.parse('http://localhost:8080'),
      httpClient: MockClient((request) async {
        return http.Response('{"message":"server error"}', 500);
      }),
    );

    expect(
      client.getJson('/api/v1/meetings'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having((error) => error.message, 'message', 'server error'),
      ),
    );
  });
}
