import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/api_meeting_repository.dart';
import 'package:meetple/data/repositories/meeting_repository.dart';

void main() {
  test('maps paged meeting API response to meetings', () async {
    final scheduledAt = DateTime.utc(2026, 5, 30, 0, 30);
    final localScheduledAt = scheduledAt.toLocal();
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'code': 2000,
        'message': 'OK',
        'data': {
          'content': [
            {
              'id': 10,
              'hostId': 1,
              'hostNickname': '민준',
              'categoryId': 2,
              'categoryName': '운동',
              'title': '한강 러닝 크루',
              'description': '함께 달려요.',
              'locationName': '여의나루역',
              'address': '서울 영등포구',
              'latitude': 37.5219,
              'longitude': 126.9245,
              'scheduledAt': scheduledAt.toIso8601String(),
              'capacity': 20,
              'currentPeople': 12,
              'status': 'RECRUITING',
              'thumbnailImageUrl': 'https://example.com/meeting.png',
              'createdAt': '2026-05-25T12:00:00',
              'updatedAt': '2026-05-25T12:00:00',
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
    final repository = ApiMeetingRepository(
      apiClient: apiClient,
      status: 'RECRUITING',
    );

    final meetings = await repository.findAll();

    expect(apiClient.path, '/api/v1/meetings');
    expect(apiClient.queryParameters, {
      'status': 'RECRUITING',
      'page': '0',
      'size': '20',
    });
    expect(meetings, hasLength(1));
    expect(meetings.single.id, 10);
    expect(meetings.single.title, '한강 러닝 크루');
    expect(meetings.single.category, '운동');
    expect(meetings.single.tags, ['운동']);
    expect(meetings.single.area, '여의나루역');
    expect(meetings.single.date, _dateLabel(localScheduledAt));
    expect(meetings.single.time, _timeLabel(localScheduledAt));
    expect(meetings.single.capacity, 20);
    expect(meetings.single.joined, 12);
    expect(meetings.single.host, '민준');
    expect(
        meetings.single.thumbnailImageUrl, 'https://example.com/meeting.png');
  });

  test('requests nearby meetings with map center and radius', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': {
          'content': [
            {
              'id': 11,
              'hostId': 2,
              'hostNickname': '서연',
              'categoryName': '취미',
              'title': '퇴근 후 영화 모임',
              'description': '함께 영화를 봐요.',
              'locationName': '여의도역',
              'address': '서울 영등포구',
              'latitude': 37.5219,
              'longitude': 126.9245,
              'scheduledAt': '2026-07-25T19:30:00',
              'capacity': 10,
              'currentPeople': 6,
              'thumbnailImageUrl': 'https://example.com/movie.png',
              'imageUrls': [
                'https://example.com/movie.png',
                'https://example.com/movie-2.png',
              ],
            },
          ],
        },
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    final meetings = await repository.findNearby(
      const NearbyMeetingQuery(
        latitude: 37.5219,
        longitude: 126.9245,
        radiusMeters: 5000,
        category: '취미',
      ),
    );

    expect(apiClient.path, '/api/v1/meetings/nearby');
    expect(apiClient.queryParameters, {
      'latitude': '37.5219',
      'longitude': '126.9245',
      'radiusMeters': '5000',
      'category': '취미',
      'page': '0',
      'size': '20',
    });
    expect(meetings, hasLength(1));
    expect(meetings.single.hostId, 2);
    expect(meetings.single.address, '서울 영등포구');
    expect(meetings.single.latitude, 37.5219);
    expect(meetings.single.longitude, 126.9245);
    expect(meetings.single.distance, '0m');
    expect(meetings.single.imageUrls, hasLength(2));
  });

  test('throws ApiException when API envelope is unsuccessful', () async {
    final repository = ApiMeetingRepository(
      apiClient: FakeApiClient(
        response: {
          'status': 400,
          'success': false,
          'message': '잘못된 요청입니다.',
        },
      ),
    );

    expect(
      repository.findAll(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 400)
            .having((error) => error.message, 'message', '잘못된 요청입니다.'),
      ),
    );
  });

  test('creates meeting with backend request body and maps response', () async {
    final scheduledAt = DateTime(2026, 7, 1, 19, 30);
    final apiClient = FakeApiClient(
      response: {
        'status': 201,
        'success': true,
        'code': 2001,
        'message': 'Created',
        'data': {
          'id': 20,
          'hostId': 1,
          'hostNickname': 'host',
          'categoryId': 2,
          'categoryName': 'exercise',
          'title': 'Morning run',
          'description': 'Run together',
          'locationName': 'Yeouido Park',
          'address': 'Seoul Yeongdeungpo-gu',
          'latitude': 37.5219,
          'longitude': 126.9245,
          'scheduledAt': '2026-07-01T19:30:00',
          'capacity': 12,
          'currentPeople': 1,
          'status': 'RECRUITING',
          'thumbnailImageUrl': null,
          'createdAt': '2026-06-30T12:00:00',
          'updatedAt': '2026-06-30T12:00:00',
        },
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    final meeting = await repository.createMeeting(
      CreateMeetingInput(
        title: 'Morning run',
        category: 'exercise',
        locationName: 'Yeouido Park',
        address: 'Seoul Yeongdeungpo-gu',
        latitude: 37.5219,
        longitude: 126.9245,
        scheduledAt: scheduledAt,
        capacity: 12,
        description: 'Run together',
      ),
    );

    expect(apiClient.method, 'POST');
    expect(apiClient.path, '/api/v1/meetings');
    expect(apiClient.includeAuthorization, isTrue);
    expect(apiClient.body, {
      'title': 'Morning run',
      'category': 'exercise',
      'locationName': 'Yeouido Park',
      'address': 'Seoul Yeongdeungpo-gu',
      'latitude': 37.5219,
      'longitude': 126.9245,
      'scheduledAt': '2026-07-01T19:30:00',
      'capacity': 12,
      'description': 'Run together',
    });
    expect(meeting.id, 20);
    expect(meeting.title, 'Morning run');
    expect(meeting.category, 'exercise');
    expect(meeting.joined, 1);
  });

  test('creates meeting with uploaded image URLs', () async {
    final scheduledAt = DateTime(2026, 7, 1, 19, 30);
    final apiClient = FakeApiClient(
      response: {
        'status': 201,
        'success': true,
        'data': {
          'id': 20,
          'hostId': 1,
          'hostNickname': 'host',
          'categoryId': 2,
          'categoryName': 'exercise',
          'title': 'Morning run',
          'description': 'Run together',
          'locationName': 'Yeouido Park',
          'address': 'Seoul Yeongdeungpo-gu',
          'latitude': 37.5219,
          'longitude': 126.9245,
          'scheduledAt': '2026-07-01T19:30:00',
          'capacity': 12,
          'currentPeople': 1,
          'status': 'RECRUITING',
          'thumbnailImageUrl': 'https://cdn.example.com/first.png',
          'imageUrls': ['https://cdn.example.com/first.png'],
        },
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    await repository.createMeeting(
      CreateMeetingInput(
        title: 'Morning run',
        category: 'exercise',
        locationName: 'Yeouido Park',
        address: 'Seoul Yeongdeungpo-gu',
        latitude: 37.5219,
        longitude: 126.9245,
        scheduledAt: scheduledAt,
        capacity: 12,
        description: 'Run together',
        imageUrls: const ['https://cdn.example.com/first.png'],
      ),
    );

    expect(apiClient.body?['imageUrls'], ['https://cdn.example.com/first.png']);
  });

  test('loads every notification page', () async {
    final apiClient = SequencedApiClient(
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
    final repository = ApiMeetingRepository(apiClient: apiClient);

    final notifications = await repository.getNotifications();

    expect(notifications.map((item) => item.id), [1, 2]);
    expect(apiClient.queries, [
      {'page': '0', 'size': '100'},
      {'page': '1', 'size': '100'},
    ]);
  });
}

String _dateLabel(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}';
}

String _timeLabel(DateTime dateTime) {
  return '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}

class FakeApiClient extends ApiClient {
  FakeApiClient({required this.response});

  final Map<String, dynamic> response;
  String? method;
  String? path;
  Map<String, String?>? queryParameters;
  Map<String, dynamic>? body;
  bool? includeAuthorization;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    method = 'GET';
    this.path = path;
    this.queryParameters = queryParameters;
    return response;
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  }) async {
    method = 'POST';
    this.path = path;
    this.body = body;
    this.includeAuthorization = includeAuthorization;
    return response;
  }
}

class SequencedApiClient extends ApiClient {
  SequencedApiClient({required this.responses});

  final List<Map<String, dynamic>> responses;
  final List<Map<String, String?>> queries = [];
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
}
