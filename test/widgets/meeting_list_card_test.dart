import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/theme/app_theme.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/widgets/meeting_list_card.dart';
import 'package:meetple/widgets/meeting_photo.dart';

void main() {
  testWidgets('shows the reference card layout and opens the meeting',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: MeetingListCard(
                meeting: _meeting,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    final photo = tester.getRect(find.byType(MeetingPhoto));
    final category = tester.getRect(find.text('취미'));
    final bookmark = tester.getRect(find.byIcon(Icons.bookmark_border));
    final title = tester.getRect(find.text('도예 원데이 클래스'));
    final card = tester.getRect(find.byType(MeetingListCard));

    expect(photo.right, lessThan(category.left));
    expect(category.top, lessThan(title.top));
    expect(bookmark.center.dx, greaterThan(title.center.dx));
    expect(bookmark.top, lessThan(title.top));
    expect(card.right - bookmark.right, closeTo(8, 0.1));
    expect(find.text('흙으로 만드는 특별한 하루'), findsNothing);
    expect(find.text('9/23 (화) 14:00'), findsOneWidget);
    expect(find.text('수원 행궁동'), findsOneWidget);
    expect(find.text('6/8명'), findsOneWidget);

    await tester.tap(find.text('도예 원데이 클래스'));
    expect(tapped, isTrue);
  });

  testWidgets('keeps the card within a narrow list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: MeetingListCard(
                meeting: _meeting,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('6/8명'), findsOneWidget);
  });

  testWidgets('grows with large text and shows discover distance',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: MeetingListCard(
                  meeting: _meeting,
                  onTap: () {},
                  showDistance: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('1km'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.text('흙으로 만드는 특별한 하루'), findsNothing);
    final card = tester.getRect(find.byType(MeetingListCard));
    final photo = tester.getRect(find.byType(MeetingPhoto));
    final lastMeta = tester.getRect(find.text('6/8명'));
    final bookmark = tester.getRect(find.byIcon(Icons.bookmark_border));
    expect(card.height, greaterThan(photo.height));
    expect(lastMeta.bottom, lessThanOrEqualTo(card.bottom));
    expect(card.right - bookmark.right, closeTo(8, 0.1));
  });
}

const _meeting = Meeting(
  id: 1,
  title: '도예 원데이 클래스',
  category: '취미',
  tags: ['도예'],
  area: '수원 행궁동',
  date: '9/23 (화)',
  time: '14:00',
  distance: '1km',
  capacity: 8,
  joined: 6,
  host: '모임장',
  description: '흙으로 만드는 특별한 하루',
  fee: '무료',
  rating: 0,
  reviewCount: 0,
);
