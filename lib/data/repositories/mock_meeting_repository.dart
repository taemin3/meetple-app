import '../../models/meeting.dart';
import '../mock/mock_meetings.dart';
import 'meeting_repository.dart';

class MockMeetingRepository implements MeetingRepository {
  const MockMeetingRepository();

  @override
  Future<List<Meeting>> findAll() => Future.value(mockMeetings);

  @override
  Future<List<Meeting>> findNearby(NearbyMeetingQuery query) async {
    const offsets = [
      (0.0032, 0.0015),
      (-0.0040, 0.0060),
      (0.0072, -0.0052),
      (-0.0100, -0.0080),
    ];

    final meetings = <Meeting>[];
    for (var index = 0; index < mockMeetings.length; index++) {
      final meeting = mockMeetings[index];
      if (query.category != null &&
          query.category!.isNotEmpty &&
          meeting.category != query.category) {
        continue;
      }

      final offset = offsets[index % offsets.length];
      meetings.add(
        meeting.copyWith(
          latitude: query.latitude + offset.$1,
          longitude: query.longitude + offset.$2,
        ),
      );
    }

    return meetings.take(query.size).toList(growable: false);
  }

  @override
  Future<Meeting> createMeeting(CreateMeetingInput input) async {
    return Meeting(
      title: input.title,
      category: input.category,
      tags: [input.category],
      area: input.locationName,
      address: input.address,
      latitude: input.latitude,
      longitude: input.longitude,
      date: '${input.scheduledAt.month}/${input.scheduledAt.day}',
      time:
          '${_twoDigits(input.scheduledAt.hour)}:${_twoDigits(input.scheduledAt.minute)}',
      distance: '거리 미정',
      capacity: input.capacity,
      joined: 1,
      host: '나',
      description: input.description,
      fee: '무료',
      rating: 0,
      reviewCount: 0,
      thumbnailImageUrl: input.imageUrls.isEmpty ? null : input.imageUrls.first,
      imageUrls: input.imageUrls,
    );
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
