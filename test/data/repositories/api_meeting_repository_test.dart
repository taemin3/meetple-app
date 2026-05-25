import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/api_meeting_repository.dart';

void main() {
  test('maps paged meeting API response to meetings', () async {
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
              'scheduledAt': '2026-05-30T09:30:00',
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
    expect(meetings.single.date, '5/30');
    expect(meetings.single.time, '09:30');
    expect(meetings.single.capacity, 20);
    expect(meetings.single.joined, 12);
    expect(meetings.single.host, '민준');
    expect(
        meetings.single.thumbnailImageUrl, 'https://example.com/meeting.png');
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
}

class FakeApiClient implements ApiClient {
  FakeApiClient({required this.response});

  final Map<String, dynamic> response;
  String? path;
  Map<String, String?>? queryParameters;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    this.path = path;
    this.queryParameters = queryParameters;
    return response;
  }
}
