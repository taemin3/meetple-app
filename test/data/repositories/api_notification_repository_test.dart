import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/api_notification_repository.dart';

void main() {
  test('loads every notification page', () async {
    final apiClient = _NotificationApiClient(
      responses: [
        {
          'status': 200,
          'success': true,
          'data': {
            'content': [
              {
                'id': 1,
                'type': 'PARTICIPATION_APPROVED',
                'title': '참여 승인',
                'message': '참여가 승인되었습니다.',
              },
            ],
            'totalPages': 2,
            'last': false,
          },
        },
        {
          'status': 200,
          'success': true,
          'data': {
            'content': [
              {
                'id': 2,
                'type': 'PARTICIPATION_REJECTED',
                'title': '참여 거절',
                'message': '참여가 거절되었습니다.',
              },
            ],
            'totalPages': 2,
            'last': true,
          },
        },
      ],
    );
    final repository = ApiNotificationRepository(apiClient: apiClient);

    final notifications = await repository.getNotifications();

    expect(notifications.map((item) => item.id), [1, 2]);
    expect(apiClient.queries, [
      {'page': '0', 'size': '100'},
      {'page': '1', 'size': '100'},
    ]);
  });

  test('marks a notification as read', () async {
    final apiClient = _NotificationApiClient(
      responses: [
        {'status': 200, 'success': true},
      ],
    );
    final repository = ApiNotificationRepository(apiClient: apiClient);

    await repository.markNotificationRead(501);

    expect(apiClient.patchPaths, ['/api/v1/notifications/501/read']);
  });
}

class _NotificationApiClient extends ApiClient {
  _NotificationApiClient({required this.responses});

  final List<Map<String, dynamic>> responses;
  final List<Map<String, String?>> queries = [];
  final List<String> patchPaths = [];
  int _index = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    queries.add(Map<String, String?>.from(queryParameters));
    return responses[_index++];
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  }) {
    throw UnsupportedError('POST is not used in this test.');
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    patchPaths.add(path);
    return responses[_index++];
  }
}
