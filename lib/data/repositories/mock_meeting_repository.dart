import '../../models/meeting.dart';
import '../../models/meeting_engagement.dart';
import '../../models/app_notification.dart';
import '../mock/mock_meetings.dart';
import 'meeting_repository.dart';

class MockMeetingRepository extends MeetingRepository {
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

  @override
  Future<MeetingEngagement> getEngagement(int meetingId) async {
    return const MeetingEngagement(
      isHost: false,
      isBookmarked: false,
      members: [
        MeetingMember(memberId: 1, nickname: '모임장', isHost: true),
      ],
    );
  }

  @override
  Future<MeetingParticipation> applyParticipation(
    int meetingId, {
    String? message,
  }) async {
    return MeetingParticipation(
      id: 1,
      memberId: 2,
      memberNickname: '나',
      status: ParticipationStatus.pending,
      message: message,
    );
  }

  @override
  Future<MeetingParticipation> cancelParticipation(
    int meetingId,
    int participationId,
  ) async {
    return const MeetingParticipation(
      id: 1,
      memberId: 2,
      memberNickname: '나',
      status: ParticipationStatus.canceled,
    );
  }

  @override
  Future<void> setBookmarked(int meetingId, bool bookmarked) async {}

  @override
  Future<List<MeetingParticipation>> getParticipations(
    int meetingId, {
    String? status,
  }) async {
    return const [];
  }

  @override
  Future<MeetingParticipation> reviewParticipation(
    int meetingId,
    int participationId, {
    required bool approve,
  }) async {
    return MeetingParticipation(
      id: participationId,
      memberId: 2,
      memberNickname: '참여자',
      status:
          approve ? ParticipationStatus.approved : ParticipationStatus.rejected,
    );
  }

  @override
  Future<void> completeMeeting(int meetingId) async {}

  @override
  Future<void> cancelMeeting(int meetingId, String reason) async {}

  @override
  Future<void> deleteMeeting(int meetingId) async {}

  @override
  Future<Meeting> updateMeetingDetails(
    int meetingId,
    UpdateMeetingInput input,
  ) async {
    final meeting = mockMeetings.first;
    final imageUrls = input.imageUrls;
    return meeting.copyWith(
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
      scheduledAt: input.scheduledAt,
      description: input.description,
      capacity: input.capacity,
      thumbnailImageUrl:
          imageUrls == null || imageUrls.isEmpty ? null : imageUrls.first,
      clearThumbnailImageUrl: imageUrls != null && imageUrls.isEmpty,
      imageUrls: imageUrls,
    );
  }

  @override
  Future<List<Meeting>> getBookmarkedMeetings() async =>
      mockMeetings.take(2).toList();

  @override
  Future<List<AppNotification>> getNotifications() async {
    return const [
      AppNotification(
        id: 1,
        type: 'PARTICIPATION_APPROVED',
        title: '참여 승인',
        message: '모임 참여가 승인되었습니다.',
      ),
    ];
  }

  @override
  Future<void> markNotificationRead(int notificationId) async {}

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
