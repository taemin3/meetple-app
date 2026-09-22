import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/api_moderation_repository.dart';
import 'package:meetple/models/moderation.dart';

void main() {
  test('public profile maps only public fields', () async {
    final client = _RecordingApiClient(getResponse: {
      'data': {
        'profileImageUrl': 'https://example.com/profile.png',
        'nickname': '민준',
        'introduction': '러닝을 좋아해요',
      }
    });
    final repository = ApiModerationRepository(apiClient: client);

    final profile = await repository.getPublicProfile(7);

    expect(client.getPath, '/api/v1/users/7/public-profile');
    expect(profile.memberId, 7);
    expect(profile.nickname, '민준');
    expect(profile.introduction, '러닝을 좋아해요');
  });

  test('report sends target and other description using API enum values',
      () async {
    final client = _RecordingApiClient();
    final repository = ApiModerationRepository(apiClient: client);

    await repository.createReport(
      targetType: ReportTargetType.chatMessage,
      targetId: 99,
      reason: ReportReason.other,
      otherDescription: '  반복 도배  ',
    );

    expect(client.postPath, '/api/v1/reports');
    expect(client.postBody, {
      'targetType': 'CHAT_MESSAGE',
      'targetId': 99,
      'reason': 'OTHER',
      'otherDescription': '반복 도배',
    });
  });

  test('block and unblock use idempotent member endpoints', () async {
    final client = _RecordingApiClient();
    final repository = ApiModerationRepository(apiClient: client);

    await repository.blockMember(3);
    expect(client.postPath, '/api/v1/users/3/block');
    await repository.unblockMember(3);
    expect(client.deletePath, '/api/v1/users/3/block');
  });
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({this.getResponse = const {'data': {}}});
  final Map<String, dynamic> getResponse;
  String? getPath;
  String? postPath;
  Map<String, dynamic>? postBody;
  String? deletePath;

  @override
  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, String?> queryParameters = const {}}) async {
    getPath = path;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path,
      {Map<String, dynamic> body = const {},
      bool includeAuthorization = true}) async {
    postPath = path;
    postBody = body;
    return const {'data': {}};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path,
      {Map<String, dynamic> body = const {}}) async {
    deletePath = path;
    return const {'data': {}};
  }
}
