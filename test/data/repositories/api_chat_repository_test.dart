import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/api_chat_repository.dart';

void main() {
  test('maps chat room list response and paging metadata', () async {
    final apiClient = _FakeApiClient(
      getResponse: {
        'status': 200,
        'success': true,
        'data': {
          'content': [
            {
              'roomId': 10,
              'meetingId': 10,
              'meetingTitle': '한강 러닝',
              'meetingStatus': 'RECRUITING',
              'thumbnailImageUrl': 'https://example.com/meeting.png',
              'lastMessage': {
                'id': 100,
                'roomId': 10,
                'sequence': 7,
                'clientMessageId': 'client-100',
                'senderId': 2,
                'senderNickname': '민준',
                'senderProfileImageUrl': null,
                'content': '잠시 후 만나요.',
                'createdAt': '2026-08-04T09:30:00',
              },
              'unreadCount': 2,
              'canSend': true,
            },
          ],
          'page': 0,
          'size': 20,
          'totalElements': 1,
          'totalPages': 1,
          'first': true,
          'last': true,
        },
      },
    );
    final repository = ApiChatRepository(apiClient: apiClient);

    final result = await repository.getRooms();

    expect(apiClient.lastPath, '/api/v1/chat/rooms');
    expect(apiClient.lastQuery, {'page': '0', 'size': '20'});
    expect(result.content.single.meetingTitle, '한강 러닝');
    expect(result.content.single.lastMessage?.sequence, 7);
    expect(result.content.single.unreadCount, 2);
    expect(result.isLast, isTrue);
  });

  test('loads cursor messages and updates last read sequence', () async {
    final apiClient = _FakeApiClient(
      getResponse: {
        'status': 200,
        'success': true,
        'data': {
          'content': [
            {
              'id': 101,
              'roomId': 10,
              'sequence': 8,
              'clientMessageId': 'client-101',
              'senderId': 1,
              'senderNickname': '김모임',
              'senderProfileImageUrl': null,
              'content': '도착했습니다.',
              'createdAt': '2026-08-04T09:31:00',
            },
          ],
          'hasMore': false,
          'oldestSequence': 8,
          'latestSequence': 8,
        },
      },
      patchResponse: {
        'status': 200,
        'success': true,
        'data': {
          'roomId': 10,
          'memberId': 1,
          'lastReadSequence': 8,
        },
      },
    );
    final repository = ApiChatRepository(apiClient: apiClient);

    final result = await repository.getMessages(
      10,
      beforeSequence: 20,
      size: 30,
    );
    await repository.markRead(10, 8);

    expect(apiClient.lastGetPath, '/api/v1/chat/rooms/10/messages');
    expect(
      apiClient.lastGetQuery,
      {'beforeSequence': '20', 'size': '30'},
    );
    expect(result.content.single.content, '도착했습니다.');
    expect(result.latestSequence, 8);
    expect(apiClient.lastPatchPath, '/api/v1/chat/rooms/10/read');
    expect(apiClient.lastPatchBody, {'lastReadSequence': 8});
  });

  test('throws ApiException for an unsuccessful chat response', () async {
    final repository = ApiChatRepository(
      apiClient: _FakeApiClient(
        getResponse: {
          'status': 403,
          'success': false,
          'message': '채팅방 입장 권한이 없습니다.',
        },
      ),
    );

    expect(
      repository.getRooms(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.message,
              'message',
              '채팅방 입장 권한이 없습니다.',
            ),
      ),
    );
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    required this.getResponse,
    this.patchResponse = const {'success': true},
  });

  final Map<String, dynamic> getResponse;
  final Map<String, dynamic> patchResponse;
  String? lastPath;
  Map<String, String?>? lastQuery;
  String? lastGetPath;
  Map<String, String?>? lastGetQuery;
  String? lastPatchPath;
  Map<String, dynamic>? lastPatchBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    lastPath = path;
    lastQuery = queryParameters;
    lastGetPath = path;
    lastGetQuery = queryParameters;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    lastPatchPath = path;
    lastPatchBody = body;
    return patchResponse;
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  }) {
    throw UnsupportedError('postJson is not used in this test.');
  }
}
