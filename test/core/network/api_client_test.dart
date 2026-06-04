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
        expect(request.url.scheme, 'http');
        expect(request.url.host, 'localhost');
        expect(request.url.port, 8080);
        expect(request.url.path, '/api/v1/meetings');
        expect(request.url.queryParameters, {
          'page': '0',
          'size': '20',
        });
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

  test('builds POST JSON request with body and optional bearer token',
      () async {
    final client = HttpApiClient(
      baseUri: Uri.parse('http://localhost:8080'),
      accessTokenProvider: () => 'access-token',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/logout');
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(request.body, '{"refreshToken":"refresh-token"}');

        return http.Response('{"success":true}', 200);
      }),
    );

    final response = await client.postJson(
      '/api/v1/auth/logout',
      body: {'refreshToken': 'refresh-token'},
    );

    expect(response['success'], true);
  });

  test('can send POST JSON request without bearer token', () async {
    final client = HttpApiClient(
      baseUri: Uri.parse('http://localhost:8080'),
      accessTokenProvider: () => 'access-token',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/login');
        expect(request.headers.containsKey('Authorization'), isFalse);

        return http.Response('{"success":true}', 200);
      }),
    );

    final response = await client.postJson(
      '/api/v1/auth/login',
      includeAuthorization: false,
      body: {'email': 'user@example.com', 'password': 'password123'},
    );

    expect(response['success'], true);
  });

  test('throws ApiException for non-json error body', () {
    final client = HttpApiClient(
      baseUri: Uri.parse('http://localhost:8080'),
      httpClient: MockClient((request) async {
        return http.Response('<html>Bad gateway</html>', 502);
      }),
    );

    expect(
      client.getJson('/api/v1/meetings'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 502)
            .having((error) => error.message, 'message', 'API request failed.'),
      ),
    );
  });

  test('preserves absolute API path when base URL has path', () async {
    final client = HttpApiClient(
      baseUri: Uri.parse('https://api.example.com/api'),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/meetings');

        return http.Response('{"success":true}', 200);
      }),
    );

    final response = await client.getJson('/api/v1/meetings');

    expect(response['success'], true);
  });
}
