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
    await _apiClient.postJson('/api/v1/reports', body: {
      'targetType': targetType.apiValue,
      'targetId': targetId,
      'reason': reason.apiValue,
      if (otherDescription != null && otherDescription.trim().isNotEmpty)
        'otherDescription': otherDescription.trim(),
    });
  }

  @override
  Future<void> blockMember(int memberId) async {
    await _apiClient.postJson('/api/v1/users/$memberId/block');
  }

  @override
  Future<void> unblockMember(int memberId) async {
    await _apiClient.deleteJson('/api/v1/users/$memberId/block');
  }

  @override
  Future<List<BlockedMember>> getBlockedMembers() async {
    final response = await _apiClient.getJson('/api/v1/users/me/blocks');
    final data = response['data'];
    if (data is! List) {
      throw const FormatException('Expected data to be a list.');
    }
    return [
      for (final item in data)
        if (item is Map<String, dynamic>)
          BlockedMember(
            memberId: _int(item['memberId']),
            nickname: item['nickname']?.toString() ?? '',
            profileImageUrl: _optionalString(item['profileImageUrl']),
            blockedAt: DateTime.parse(item['blockedAt'].toString()),
          ),
    ];
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Expected data to be an object.');
  }

  int _int(Object? value) => value is int ? value : int.parse(value.toString());
  String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
