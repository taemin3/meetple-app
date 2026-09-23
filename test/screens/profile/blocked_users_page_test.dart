import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/moderation_repository.dart';
import 'package:meetple/models/moderation.dart';
import 'package:meetple/screens/profile/blocked_users_page.dart';

void main() {
  testWidgets('notifies meeting lists after unblocking a member',
      (tester) async {
    final repository = _BlockedUsersRepository();
    var changeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BlockedUsersPage(
          repository: repository,
          onChanged: () => changeCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('차단 해제'));
    await tester.pumpAndSettle();

    expect(repository.unblockedMemberIds, [2]);
    expect(changeCount, 1);
  });
}

class _BlockedUsersRepository implements ModerationRepository {
  final List<int> unblockedMemberIds = [];

  @override
  Future<List<BlockedMember>> getBlockedMembers() async => [
        BlockedMember(
          memberId: 2,
          nickname: '민준',
          blockedAt: DateTime(2026, 9, 24),
        ),
      ];

  @override
  Future<void> unblockMember(int memberId) async {
    unblockedMemberIds.add(memberId);
  }

  @override
  Future<void> blockMember(int memberId) async {}

  @override
  Future<void> createReport({
    required ReportTargetType targetType,
    required int targetId,
    required ReportReason reason,
    String? otherDescription,
  }) async {}

  @override
  Future<PublicMemberProfile> getPublicProfile(int memberId) async {
    throw UnimplementedError();
  }
}
