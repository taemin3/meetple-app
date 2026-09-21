import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_engagement.dart';
import 'package:meetple/screens/home/home_page.dart';
import 'package:meetple/widgets/bookmarkable_meeting_card.dart';

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

    final bookmark = find.byKey(Key('meeting-bookmark-${meeting.id}'));
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

  testWidgets('cards share one bookmark load and update together',
      (tester) async {
    final repository = _BookmarkRepository();
    final meeting = (await repository.findAll()).first;
    var openCount = 0;
    Widget cards(int count) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < count; i++)
                      BookmarkableMeetingCard(
                        meeting: meeting,
                        meetingRepository: repository,
                        onTap: () async => openCount++,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
    await tester.pumpWidget(cards(1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(cards(2));
    await tester.pumpAndSettle();

    expect(repository.bookmarkListRequests, 1);
    expect(repository.engagementRequests, 0);
    expect(find.byIcon(Icons.bookmark_border), findsNWidgets(2));

    await tester.tap(find.byKey(Key('meeting-bookmark-${meeting.id}')).first);
    await tester.pumpAndSettle();

    expect(repository.engagementRequests, 1);
    expect(find.byIcon(Icons.bookmark_rounded), findsNWidgets(2));
    expect(openCount, 0);
  });

  testWidgets('host bookmark tap stays on the card', (tester) async {
    final repository = _BookmarkRepository()..isHost = true;
    final meeting = (await repository.findAll()).first;
    var openCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: BookmarkableMeetingCard(
            meeting: meeting,
            meetingRepository: repository,
            onTap: () async => openCount++,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('meeting-bookmark-${meeting.id}')));
    await tester.pumpAndSettle();

    expect(openCount, 0);
    expect(repository.isBookmarked, isFalse);
  });

  testWidgets('bookmark tap while loading never opens the meeting',
      (tester) async {
    final repository = _DeferredBookmarkRepository();
    final meeting = (await repository.findAll()).first;
    var openCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: BookmarkableMeetingCard(
            meeting: meeting,
            meetingRepository: repository,
            onTap: () async => openCount++,
          ),
        ),
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(Key('meeting-bookmark-${meeting.id}')));
    await tester.pump();
    expect(openCount, 0);

    repository.completeBookmarkLoad();
    await tester.pumpAndSettle();

    expect(openCount, 0);
    expect(repository.isBookmarked, isTrue);
  });
}

class _BookmarkRepository extends MockMeetingRepository {
  bool isBookmarked = false;
  bool isHost = false;
  int bookmarkListRequests = 0;
  int engagementRequests = 0;

  @override
  Future<List<Meeting>> getBookmarkedMeetings() async {
    bookmarkListRequests++;
    return isBookmarked ? [(await findAll()).first] : [];
  }

  @override
  Future<MeetingEngagement> getEngagement(int meetingId) async {
    engagementRequests++;
    return MeetingEngagement(isHost: isHost, isBookmarked: isBookmarked);
  }

  @override
  Future<void> setBookmarked(int meetingId, bool bookmarked) async {
    isBookmarked = bookmarked;
  }
}

class _DeferredBookmarkRepository extends _BookmarkRepository {
  final _bookmarks = Completer<List<Meeting>>();

  @override
  Future<List<Meeting>> getBookmarkedMeetings() => _bookmarks.future;

  void completeBookmarkLoad() => _bookmarks.complete([]);
}
