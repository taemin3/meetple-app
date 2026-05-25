import '../../models/meeting.dart';

abstract interface class MeetingRepository {
  Future<List<Meeting>> findAll();
}
