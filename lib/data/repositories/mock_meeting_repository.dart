import '../../models/meeting.dart';
import '../mock/mock_meetings.dart';
import 'meeting_repository.dart';

class MockMeetingRepository implements MeetingRepository {
  const MockMeetingRepository();

  @override
  Future<List<Meeting>> findAll() => Future.value(mockMeetings);

  @override
  Future<Meeting> createMeeting(CreateMeetingInput input) async {
    return Meeting(
      title: input.title,
      category: input.category,
      tags: [input.category],
      area: input.locationName,
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
    );
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
