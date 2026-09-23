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

  test('mutations reject failed API envelopes', () async {
    final client = _RecordingApiClient(
      postResponse: const {
        'success': false,
        'status': 400,
        'message': '요청을 처리할 수 없습니다.',
      },
      deleteResponse: const {
        'success': false,
        'status': 400,
        'message': '차단 해제에 실패했습니다.',
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
    await expectLater(repository.blockMember(3), throwsA(isA<ApiException>()));
    await expectLater(
      repository.unblockMember(3),
      throwsA(isA<ApiException>()),
    );
  });

  test('blocked members map paged backend response', () async {
    final client = _RecordingApiClient(getResponse: {
      'data': {
        'content': [
          {
            'memberId': 3,
            'nickname': '차단 회원',
            'profileImageUrl': null,
            'blockedAt': '2026-09-22T10:00:00',
          }
        ],
        'last': true,
      }
    });
    final repository = ApiModerationRepository(apiClient: client);

    final result = await repository.getBlockedMembers();

    expect(result.single.memberId, 3);
    expect(client.getPath, '/api/v1/users/me/blocks');
    expect(client.getQueryParameters, {'page': '0', 'size': '100'});
  });
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({
    this.getResponse = const {'data': {}},
    this.postResponse = const {'success': true, 'data': {}},
    this.deleteResponse = const {'success': true, 'data': {}},
  });
  final Map<String, dynamic> getResponse;
  final Map<String, dynamic> postResponse;
  final Map<String, dynamic> deleteResponse;
  String? getPath;
  Map<String, String?>? getQueryParameters;
  String? postPath;
  Map<String, dynamic>? postBody;
  String? deletePath;

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

  @override
  Future<Map<String, dynamic>> deleteJson(String path,
      {Map<String, dynamic> body = const {}}) async {
    deletePath = path;
    return deleteResponse;
  }
}
