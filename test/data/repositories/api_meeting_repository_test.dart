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

  test('requests paged global search results with origin coordinates',
      () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': {
          'content': [
            {
              'id': 12,
              'hostId': 3,
              'hostNickname': '지민',
              'categoryName': '운동',
              'title': '전국 러닝 모임',
              'description': '함께 달려요.',
              'locationName': '여의도공원',
              'address': '서울 영등포구',
              'latitude': 37.5219,
              'longitude': 126.9245,
              'scheduledAt': '2026-07-25T19:30:00',
              'capacity': 10,
              'currentPeople': 4,
              'status': 'RECRUITING',
            },
          ],
          'page': 1,
          'size': 20,
          'totalElements': 24,
          'totalPages': 2,
          'first': false,
          'last': true,
        },
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    final result = await repository.searchMeetings(
      const MeetingSearchQuery(
        keyword: ' 러닝 ',
        category: '운동',
        latitude: 37.5219,
        longitude: 126.9245,
        page: 1,
      ),
    );

    expect(apiClient.path, '/api/v1/meetings/search');
    expect(apiClient.queryParameters, {
      'keyword': '러닝',
      'category': '운동',
      'latitude': '37.5219',
      'longitude': '126.9245',
      'page': '1',
      'size': '20',
    });
    expect(result.meetings.single.title, '전국 러닝 모임');
    expect(result.meetings.single.distance, '0m');
    expect(result.page, 1);
    expect(result.totalElements, 24);
    expect(result.totalPages, 2);
    expect(result.isLast, isTrue);
    expect(result.hasNext, isFalse);
  });

  test('maps participation applicant details and timestamps', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': {
          'content': [
            {
              'id': 100,
              'memberId': 2,
              'memberNickname': '러너',
              'memberProfileImageUrl': 'https://example.com/profile.png',
              'status': 'PENDING',
              'message': '함께 달리고 싶어요.',
              'reviewedAt': null,
              'canceledAt': null,
              'createdAt': '2026-07-27T18:35:00',
            },
          ],
        },
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    final participations = await repository.getParticipations(
      10,
      status: 'PENDING',
    );

    expect(apiClient.path, '/api/v1/meetings/10/participations');
    expect(apiClient.queryParameters, {
      'status': 'PENDING',
      'page': '0',
      'size': '100',
    });
    expect(participations.single.memberNickname, '러너');
    expect(participations.single.createdAt, DateTime(2026, 7, 27, 18, 35));
  });

  test('loads every participation page without a status filter', () async {
    final apiClient = SequencedApiClient(
      responses: [
        {
          'status': 200,
          'success': true,
          'data': {
            'content': [
              _participationJson(id: 100, status: 'PENDING'),
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
              _participationJson(id: 101, status: 'APPROVED'),
            ],
            'totalPages': 2,
            'last': true,
          },
        },
      ],
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    final participations = await repository.getParticipations(10);

    expect(participations.map((item) => item.id), [100, 101]);
    expect(apiClient.queries, [
      {'page': '0', 'size': '100'},
      {'page': '1', 'size': '100'},
    ]);
  });

  test('loads hosted and joined meetings from my-page API paths', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': {
          'content': [
            {
              'id': 10,
              'title': '한강 러닝',
              'categoryName': '운동',
              'locationName': '여의도',
              'capacity': 10,
              'currentPeople': 4,
            },
          ],
          'totalPages': 1,
          'last': true,
        },
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    final hosted = await repository.getHostedMeetings();

    expect(apiClient.path, '/api/v1/users/me/meetings/hosted');
    expect(apiClient.queryParameters, {'page': '0', 'size': '100'});
    expect(hosted.single.title, '한강 러닝');

    final joined = await repository.getJoinedMeetings();

    expect(apiClient.path, '/api/v1/users/me/meetings/joined');
    expect(joined.single.id, 10);
  });

  test('maps my participation applications with meeting details', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': {
          'content': [
            {
              'id': 100,
              'meetingId': 10,
              'meetingTitle': '한강 러닝',
              'memberId': 2,
              'memberNickname': '러너',
              'status': 'APPROVED',
              'message': '함께 달리고 싶어요.',
            },
          ],
          'totalPages': 1,
          'last': true,
        },
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    final applications = await repository.getMyApplications();

    expect(apiClient.path, '/api/v1/users/me/applications');
    expect(applications.single.meetingId, 10);
    expect(applications.single.meetingTitle, '한강 러닝');
    expect(applications.single.status.name, 'approved');
  });

  test('approves and rejects participation through meeting API paths',
      () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': _participationJson(id: 100, status: 'APPROVED'),
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    final approved = await repository.reviewParticipation(
      10,
      100,
      approve: true,
    );

    expect(apiClient.method, 'PATCH');
    expect(
      apiClient.path,
      '/api/v1/meetings/10/participations/100/approve',
    );
    expect(approved.status.name, 'approved');

    apiClient.response['data'] =
        _participationJson(id: 101, status: 'REJECTED');
    final rejected = await repository.reviewParticipation(
      10,
      101,
      approve: false,
    );

    expect(
      apiClient.path,
      '/api/v1/meetings/10/participations/101/reject',
    );
    expect(rejected.status.name, 'rejected');
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

  test('updates every editable meeting field', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': {
          'id': 20,
          'categoryName': '운동',
          'title': '저녁 러닝',
          'description': '함께 달려요.',
          'locationName': '여의도공원',
          'address': '서울 영등포구 여의공원로 68',
          'latitude': 37.5268,
          'longitude': 126.9228,
          'scheduledAt': '2026-08-10T19:30:00',
          'capacity': 12,
          'currentPeople': 6,
          'imageUrls': ['https://cdn.example.com/run.png'],
        },
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    await repository.updateMeetingDetails(
      20,
      UpdateMeetingInput(
        title: '저녁 러닝',
        category: '운동',
        locationName: '여의도공원',
        address: '서울 영등포구 여의공원로 68',
        latitude: 37.5268,
        longitude: 126.9228,
        scheduledAt: DateTime(2026, 8, 10, 19, 30),
        capacity: 12,
        description: '함께 달려요.',
        imageUrls: const ['https://cdn.example.com/run.png'],
      ),
    );

    expect(apiClient.method, 'PATCH');
    expect(apiClient.path, '/api/v1/meetings/20');
    expect(apiClient.body, {
      'title': '저녁 러닝',
      'category': '운동',
      'locationName': '여의도공원',
      'address': '서울 영등포구 여의공원로 68',
      'latitude': 37.5268,
      'longitude': 126.9228,
      'scheduledAt': '2026-08-10T19:30:00',
      'capacity': 12,
      'description': '함께 달려요.',
      'imageUrls': ['https://cdn.example.com/run.png'],
    });
  });

  test('omits image URLs when edit form did not change images', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': {'id': 20},
      },
    );
    final repository = ApiMeetingRepository(apiClient: apiClient);

    await repository.updateMeetingDetails(
      20,
      UpdateMeetingInput(
        title: '러닝 모임',
        category: '운동',
        locationName: '여의도공원',
        address: '서울 영등포구 여의공원로 68',
        latitude: 37.5268,
        longitude: 126.9228,
        scheduledAt: DateTime(2026, 8, 10, 19, 30),
        capacity: 12,
        description: '함께 달려요.',
      ),
    );

    expect(apiClient.body, isNot(contains('imageUrls')));
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

Map<String, dynamic> _participationJson({
  required int id,
  required String status,
}) {
  return {
    'id': id,
    'memberId': 2,
    'memberNickname': '러너',
    'memberProfileImageUrl': 'https://example.com/profile.png',
    'status': status,
    'message': '함께 달리고 싶어요.',
    'reviewedAt': status == 'PENDING' ? null : '2026-07-27T18:40:00',
    'canceledAt': null,
    'createdAt': '2026-07-27T18:35:00',
  };
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

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    method = 'PATCH';
    this.path = path;
    this.body = body;
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
