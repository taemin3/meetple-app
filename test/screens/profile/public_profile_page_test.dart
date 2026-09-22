import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/moderation_repository.dart';
import 'package:meetple/models/moderation.dart';
import 'package:meetple/screens/profile/public_profile_page.dart';

void main() {
  testWidgets(
      'shows only public profile fields and moderation menu for another member',
      (tester) async {
    final repository = _FakeModerationRepository();
    await tester.pumpWidget(MaterialApp(
      home: PublicProfilePage(
        memberId: 2,
        currentMemberId: 1,
        moderationRepository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('서연'), findsOneWidget);
    expect(find.text('함께 운동해요.'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    expect(find.byKey(const Key('public-profile-more')), findsOneWidget);

    await tester.tap(find.byKey(const Key('public-profile-more')));
    await tester.pumpAndSettle();
    expect(find.text('사용자 신고'), findsOneWidget);
    expect(find.text('사용자 차단'), findsOneWidget);
  });

  testWidgets('does not show report or block menu on my profile',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PublicProfilePage(
        memberId: 1,
        currentMemberId: 1,
        moderationRepository: _FakeModerationRepository(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('public-profile-more')), findsNothing);
  });
}

class _FakeModerationRepository implements ModerationRepository {
  @override
  Future<PublicMemberProfile> getPublicProfile(int memberId) async =>
      PublicMemberProfile(
        memberId: memberId,
        nickname: '서연',
        introduction: '함께 운동해요.',
      );

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
  Future<List<BlockedMember>> getBlockedMembers() async => const [];

  @override
  Future<void> unblockMember(int memberId) async {}
}
