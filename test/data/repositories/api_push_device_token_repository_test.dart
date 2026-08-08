import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/push_device_token_repository.dart';

void main() {
  test('registers the device token through the push API', () async {
    final apiClient = _RecordingApiClient(
      response: const {'status': 200, 'success': true},
    );
    final repository = ApiPushDeviceTokenRepository(apiClient: apiClient);

    await repository.register(
      deviceId: 'installation-1',
      token: 'fcm-token-1',
      platform: 'ANDROID',
    );

    expect(apiClient.path, '/api/v1/push/device-tokens');
    expect(apiClient.includeAuthorization, isTrue);
    expect(apiClient.body, {
      'deviceId': 'installation-1',
      'token': 'fcm-token-1',
      'platform': 'ANDROID',
    });
  });

  test('throws when the push API envelope reports failure', () {
    final repository = ApiPushDeviceTokenRepository(
      apiClient: _RecordingApiClient(
        response: const {
          'status': 400,
          'success': false,
          'message': 'invalid token',
        },
      ),
    );

    expect(
      repository.register(
        deviceId: 'installation-1',
        token: 'fcm-token-1',
        platform: 'ANDROID',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'invalid token',
        ),
      ),
    );
  });
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({required this.response});

  final Map<String, dynamic> response;
  String? path;
  Map<String, dynamic>? body;
  bool? includeAuthorization;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  }) async {
    this.path = path;
    this.body = body;
    this.includeAuthorization = includeAuthorization;
    return response;
  }
}
