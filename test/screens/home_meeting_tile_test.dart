import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/meeting_engagement.dart';
import 'package:meetple/screens/home/home_page.dart';

void main() {
  testWidgets('bookmark toggles without opening the meeting', (tester) async {
    final repository = _BookmarkRepository();
    final meeting = (await repository.findAll()).first;
    var openCount = 0;
    var changeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: HomeMeetingTile(
                meeting: meeting,
                meetingRepository: repository,
                onTap: () async {
                  openCount++;
                },
                onBookmarkChanged: () => changeCount++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bookmark = find.byKey(Key('home-meeting-bookmark-${meeting.id}'));
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    final category = tester.getRect(find.text(meeting.category));
    final bookmarkIcon = tester.getRect(find.byIcon(Icons.bookmark_border));
    final title = tester.getRect(find.text(meeting.title));
    expect((category.center.dy - bookmarkIcon.center.dy).abs(), lessThan(5));
    expect(
      title.top - bookmarkIcon.bottom,
      lessThanOrEqualTo(6),
      reason: 'category=$category icon=$bookmarkIcon '
          'button=${tester.getRect(bookmark)} title=$title',
    );

    await tester.tap(bookmark);
    await tester.pumpAndSettle();
    expect(repository.isBookmarked, isTrue);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    expect(openCount, 0);
    expect(changeCount, 1);

    await tester.tap(bookmark);
    await tester.pumpAndSettle();
    expect(repository.isBookmarked, isFalse);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(openCount, 0);
    expect(changeCount, 2);

    await tester.tap(find.text(meeting.title));
    await tester.pumpAndSettle();
    expect(openCount, 1);
  });
}

class _BookmarkRepository extends MockMeetingRepository {
  bool isBookmarked = false;

  @override
  Future<MeetingEngagement> getEngagement(int meetingId) async {
    return MeetingEngagement(isHost: false, isBookmarked: isBookmarked);
  }

  @override
  Future<void> setBookmarked(int meetingId, bool bookmarked) async {
    isBookmarked = bookmarked;
  }
}
