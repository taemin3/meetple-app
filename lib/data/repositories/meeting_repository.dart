import '../../models/meeting.dart';

abstract interface class MeetingRepository {
  Future<List<Meeting>> findAll();

  Future<Meeting> createMeeting(CreateMeetingInput input);
}

class CreateMeetingInput {
  const CreateMeetingInput({
    required this.title,
    required this.category,
    required this.locationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
    required this.capacity,
    required this.description,
  });

  final String title;
  final String category;
  final String locationName;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime scheduledAt;
  final int capacity;
  final String description;
}
