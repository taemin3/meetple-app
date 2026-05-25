import '../../models/meeting.dart';

abstract interface class MeetingRepository {
  List<Meeting> findAll();
}
