import '../../models/meeting.dart';
import '../mock/mock_meetings.dart';
import 'meeting_repository.dart';

class MockMeetingRepository implements MeetingRepository {
  const MockMeetingRepository();

  @override
  Future<List<Meeting>> findAll() => Future.value(mockMeetings);
}
