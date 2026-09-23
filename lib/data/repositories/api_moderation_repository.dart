import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/moderation.dart';
import 'moderation_repository.dart';

class ApiModerationRepository implements ModerationRepository {
  ApiModerationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  ApiModerationRepository.withBaseUrl({
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
  Future<PublicMemberProfile> getPublicProfile(int memberId) async {
    final response =
        await _apiClient.getJson('/api/v1/users/$memberId/public-profile');
    final data = _dataMap(response);
    return PublicMemberProfile(
      memberId: memberId,
      nickname: data['nickname']?.toString() ?? '',
      profileImageUrl: _optionalString(data['profileImageUrl']),
      introduction: _optionalString(data['introduction']),
    );
  }

  @override
  Future<void> createReport({
    required ReportTargetType targetType,
    required int targetId,
    required ReportReason reason,
    String? otherDescription,
  }) async {
    final response = await _apiClient.postJson('/api/v1/reports', body: {
      'targetType': targetType.apiValue,
      'targetId': targetId,
      'reason': reason.apiValue,
      if (otherDescription != null && otherDescription.trim().isNotEmpty)
        'otherDescription': otherDescription.trim(),
    });
    _ensureSuccess(response);
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Expected data to be an object.');
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw ApiException(
        statusCode: response['status'] is int ? response['status'] as int : 0,
        message: _optionalString(response['message']) ?? 'API request failed.',
        body: response,
      );
    }
  }

  String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
