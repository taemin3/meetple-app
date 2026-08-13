import '../../models/meeting.dart';
import '../../models/meeting_engagement.dart';
import '../mock/mock_meetings.dart';
import 'meeting_repository.dart';

class MockMeetingRepository extends MeetingRepository {
  const MockMeetingRepository();

  @override
  Future<List<Meeting>> findAll() => Future.value(mockMeetings);

  @override
  Future<Meeting> findById(int meetingId) async {
    return mockMeetings.firstWhere(
      (meeting) => meeting.id == meetingId,
      orElse: () => mockMeetings.first,
    );
  }

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
  Future<MeetingSearchPage> searchMeetings(MeetingSearchQuery query) async {
    final keyword = query.keyword.trim().toLowerCase();
    final matches = mockMeetings.where((meeting) {
      final matchesKeyword = meeting.title.toLowerCase().contains(keyword) ||
          meeting.area.toLowerCase().contains(keyword) ||
          meeting.category.toLowerCase().contains(keyword);
      final matchesCategory = query.category == null ||
          query.category!.isEmpty ||
          meeting.category == query.category;
      return matchesKeyword && matchesCategory;
    }).toList(growable: false);
    final start = (query.page * query.size).clamp(0, matches.length);
    final end = (start + query.size).clamp(start, matches.length);
    final totalPages =
        matches.isEmpty ? 0 : (matches.length / query.size).ceil();

    return MeetingSearchPage(
      meetings: matches.sublist(start, end),
      page: query.page,
      totalElements: matches.length,
      totalPages: totalPages,
      isLast: totalPages == 0 || query.page + 1 >= totalPages,
    );
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
      scheduledAt: input.scheduledAt,
      endsAt: input.endsAt,
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
      endsAt: input.endsAt,
      clearEndsAt: input.endsAt == null,
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
  Future<List<Meeting>> getHostedMeetings() async =>
      mockMeetings.take(2).toList();

  @override
  Future<List<Meeting>> getJoinedMeetings() async =>
      mockMeetings.skip(1).take(2).toList();

  @override
  Future<List<MeetingParticipation>> getMyApplications() async {
    return [
      MeetingParticipation(
        id: 1,
        meetingId: mockMeetings.first.id,
        meetingTitle: mockMeetings.first.title,
        memberId: 2,
        memberNickname: '나',
        status: ParticipationStatus.pending,
        message: '함께 참여하고 싶어요.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
