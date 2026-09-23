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
    _ensureSuccess(response);
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

  @override
  Future<void> blockMember(int memberId) async {
    final response = await _apiClient.postJson('/api/v1/users/$memberId/block');
    _ensureSuccess(response);
  }

  @override
  Future<void> unblockMember(int memberId) async {
    final response =
        await _apiClient.deleteJson('/api/v1/users/$memberId/block');
    _ensureSuccess(response);
  }

  @override
  Future<List<BlockedMember>> getBlockedMembers() async {
    final blockedMembers = <BlockedMember>[];
    for (var page = 0;; page++) {
      final response = await _apiClient.getJson(
        '/api/v1/users/me/blocks',
        queryParameters: {'page': '$page', 'size': '100'},
      );
      _ensureSuccess(response);
      final data = response['data'];
      final List<dynamic> items;
      final bool last;
      if (data is List) {
        items = data;
        last = true;
      } else if (data is Map<String, dynamic> && data['content'] is List) {
        items = data['content'] as List<dynamic>;
        last = data['last'] is bool ? data['last'] as bool : true;
      } else {
        throw const FormatException('Expected blocked-member page data.');
      }
      blockedMembers.addAll([
        for (final item in items)
          if (item is Map<String, dynamic>)
            BlockedMember(
              memberId: _int(item['memberId']),
              nickname: item['nickname']?.toString() ?? '',
              profileImageUrl: _optionalString(item['profileImageUrl']),
              blockedAt: DateTime.parse(item['blockedAt'].toString()),
            ),
      ]);
      if (last) break;
    }
    return blockedMembers;
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Expected data to be an object.');
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw ApiException(
        statusCode: _int(response['status']),
        message: _optionalString(response['message']) ?? 'API request failed.',
        body: response,
      );
    }
  }

  int _int(Object? value) => value is int ? value : int.parse(value.toString());
  String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
