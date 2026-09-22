import '../../models/moderation.dart';

abstract interface class ModerationRepository {
  Future<PublicMemberProfile> getPublicProfile(int memberId);

  Future<void> createReport({
    required ReportTargetType targetType,
    required int targetId,
    required ReportReason reason,
    String? otherDescription,
  });

  Future<void> blockMember(int memberId);
  Future<void> unblockMember(int memberId);
  Future<List<BlockedMember>> getBlockedMembers();
}
