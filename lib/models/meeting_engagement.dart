enum ParticipationStatus {
  pending,
  approved,
  rejected,
  canceled,
}

class MeetingParticipation {
  const MeetingParticipation({
    required this.id,
    this.meetingId,
    this.meetingTitle,
    required this.memberId,
    required this.memberNickname,
    this.memberProfileImageUrl,
    required this.status,
    this.message,
    this.reviewedAt,
    this.canceledAt,
    this.createdAt,
  });

  final int id;
  final int? meetingId;
  final String? meetingTitle;
  final int memberId;
  final String memberNickname;
  final String? memberProfileImageUrl;
  final ParticipationStatus status;
  final String? message;
  final DateTime? reviewedAt;
  final DateTime? canceledAt;
  final DateTime? createdAt;
}

class MeetingMember {
  const MeetingMember({
    required this.memberId,
    required this.nickname,
    this.introduction,
    this.profileImageUrl,
    required this.isHost,
  });

  final int memberId;
  final String nickname;
  final String? introduction;
  final String? profileImageUrl;
  final bool isHost;
}

class MeetingEngagement {
  const MeetingEngagement({
    required this.isHost,
    required this.isBookmarked,
    this.participation,
    this.members = const [],
  });

  final bool isHost;
  final bool isBookmarked;
  final MeetingParticipation? participation;
  final List<MeetingMember> members;

  MeetingEngagement copyWith({
    bool? isHost,
    bool? isBookmarked,
    MeetingParticipation? participation,
    bool clearParticipation = false,
    List<MeetingMember>? members,
  }) {
    return MeetingEngagement(
      isHost: isHost ?? this.isHost,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      participation:
          clearParticipation ? null : participation ?? this.participation,
      members: members ?? this.members,
    );
  }
}
