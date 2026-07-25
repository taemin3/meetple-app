import '../../models/meeting.dart';

abstract interface class MeetingRepository {
  Future<List<Meeting>> findAll();

  Future<List<Meeting>> findNearby(NearbyMeetingQuery query);

  Future<Meeting> createMeeting(CreateMeetingInput input);
}

class NearbyMeetingQuery {
  const NearbyMeetingQuery({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 5000,
    this.category,
    this.page = 0,
    this.size = 20,
  });

  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String? category;
  final int page;
  final int size;
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
    this.imageUrls = const [],
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
  final List<String> imageUrls;
}
