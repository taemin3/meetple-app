import '../../models/moderation.dart';
import 'moderation_repository.dart';

class MockModerationRepository implements ModerationRepository {
  const MockModerationRepository();

  @override
  Future<PublicMemberProfile> getPublicProfile(int memberId) async =>
      PublicMemberProfile(
          memberId: memberId,
          nickname: '회원 $memberId',
          introduction: '함께 즐거운 모임을 만들어요.');

  @override
  Future<void> createReport(
      {required ReportTargetType targetType,
      required int targetId,
      required ReportReason reason,
      String? otherDescription}) async {}

  @override
  Future<void> blockMember(int memberId) async {}

  @override
  Future<void> unblockMember(int memberId) async {}

  @override
  Future<List<BlockedMember>> getBlockedMembers() async => const [];
}
