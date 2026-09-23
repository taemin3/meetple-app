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

  test('report rejects a failed API envelope', () async {
    final client = _RecordingApiClient(
      postResponse: const {
        'success': false,
        'status': 400,
        'message': '요청을 처리할 수 없습니다.',
      },
    );
    final repository = ApiModerationRepository(apiClient: client);

    await expectLater(
      repository.createReport(
        targetType: ReportTargetType.member,
        targetId: 3,
        reason: ReportReason.spam,
      ),
      throwsA(isA<ApiException>()),
    );
  });
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({
    this.getResponse = const {'data': {}},
    this.postResponse = const {'success': true, 'data': {}},
  });
  final Map<String, dynamic> getResponse;
  final Map<String, dynamic> postResponse;
  String? getPath;
  Map<String, String?>? getQueryParameters;
  String? postPath;
  Map<String, dynamic>? postBody;

  @override
  Future<Map<String, dynamic>> getJson(String path,
      {Map<String, String?> queryParameters = const {}}) async {
    getPath = path;
    getQueryParameters = queryParameters;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path,
      {Map<String, dynamic> body = const {},
      bool includeAuthorization = true}) async {
    postPath = path;
    postBody = body;
    return postResponse;
  }
}
