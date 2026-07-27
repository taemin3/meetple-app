import '../../models/meeting.dart';
import '../../models/meeting_engagement.dart';
import '../../models/app_notification.dart';

abstract class MeetingRepository {
  const MeetingRepository();

  Future<List<Meeting>> findAll();

  Future<List<Meeting>> findNearby(NearbyMeetingQuery query);

  Future<Meeting> createMeeting(CreateMeetingInput input);

  Future<MeetingEngagement> getEngagement(int meetingId) {
    throw UnimplementedError();
  }

  Future<MeetingParticipation> applyParticipation(
    int meetingId, {
    String? message,
  }) {
    throw UnimplementedError();
  }

  Future<MeetingParticipation> cancelParticipation(
    int meetingId,
    int participationId,
  ) {
    throw UnimplementedError();
  }

  Future<void> setBookmarked(int meetingId, bool bookmarked) {
    throw UnimplementedError();
  }

  Future<List<MeetingParticipation>> getParticipations(
    int meetingId, {
    String status = 'PENDING',
  }) {
    throw UnimplementedError();
  }

  Future<MeetingParticipation> reviewParticipation(
    int meetingId,
    int participationId, {
    required bool approve,
  }) {
    throw UnimplementedError();
  }

  Future<void> completeMeeting(int meetingId) {
    throw UnimplementedError();
  }

  Future<void> cancelMeeting(int meetingId, String reason) {
    throw UnimplementedError();
  }

  Future<void> deleteMeeting(int meetingId) {
    throw UnimplementedError();
  }

  Future<Meeting> updateMeetingDetails(
    int meetingId,
    UpdateMeetingInput input,
  ) {
    throw UnimplementedError();
  }

  Future<List<Meeting>> getBookmarkedMeetings() {
    throw UnimplementedError();
  }

  Future<List<AppNotification>> getNotifications() {
    throw UnimplementedError();
  }

  Future<void> markNotificationRead(int notificationId) {
    throw UnimplementedError();
  }
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

class UpdateMeetingInput {
  const UpdateMeetingInput({
    required this.title,
    required this.category,
    required this.locationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
    required this.capacity,
    required this.description,
    this.imageUrls,
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
  final List<String>? imageUrls;
}
