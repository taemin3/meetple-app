import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

abstract interface class PushDeviceTokenRepository {
  Future<void> register({
    required String deviceId,
    required String token,
    required String platform,
  });
}

class ApiPushDeviceTokenRepository implements PushDeviceTokenRepository {
  ApiPushDeviceTokenRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  factory ApiPushDeviceTokenRepository.withBaseUrl({
    String baseUrl = AppConfig.apiBaseUrl,
    required AccessTokenProvider accessTokenProvider,
  }) {
    return ApiPushDeviceTokenRepository(
      apiClient: HttpApiClient(
        baseUri: Uri.parse(baseUrl),
        accessTokenProvider: accessTokenProvider,
      ),
    );
  }

  final ApiClient _apiClient;

  @override
  Future<void> register({
    required String deviceId,
    required String token,
    required String platform,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/push/device-tokens',
      body: {
        'deviceId': deviceId,
        'token': token,
        'platform': platform,
      },
    );
    if (response['success'] != true) {
      throw ApiException(
        statusCode: _readInt(response['status']),
        message:
            response['message']?.toString() ?? 'FCM token registration failed.',
        body: response,
      );
    }
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
