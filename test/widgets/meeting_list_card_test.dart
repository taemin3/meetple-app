import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/theme/app_theme.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/widgets/meeting_list_card.dart';
import 'package:meetple/widgets/meeting_photo.dart';

void main() {
  testWidgets('aligns the trailing bookmark at the bottom right',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: MeetingListCard(
                meeting: _meeting,
                onTap: () {},
                trailing: const Icon(Icons.bookmark_border),
              ),
            ),
          ),
        ),
      ),
    );

    final cardMaterial = find
        .descendant(
          of: find.byType(MeetingListCard),
          matching: find.byType(Material),
        )
        .first;
    final cardRect = tester.getRect(cardMaterial);
    final photoRect = tester.getRect(find.byType(MeetingPhoto));
    final bookmarkRect = tester.getRect(find.byIcon(Icons.bookmark_border));

    expect(bookmarkRect.center.dx, greaterThan(photoRect.right));
    expect(bookmarkRect.bottom, closeTo(cardRect.bottom - 10, 0.1));
  });

  testWidgets('aligns trailing to the actual bottom of a variable-height card',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: MeetingListCard(
                meeting: _meetingWithWrappedTags,
                onTap: () {},
                trailing: const Icon(Icons.bookmark_border),
              ),
            ),
          ),
        ),
      ),
    );

    final cardMaterial = find
        .descendant(
          of: find.byType(MeetingListCard),
          matching: find.byType(Material),
        )
        .first;
    final cardRect = tester.getRect(cardMaterial);
    final photoRect = tester.getRect(find.byType(MeetingPhoto));
    final bookmarkRect = tester.getRect(find.byIcon(Icons.bookmark_border));

    expect(cardRect.height, greaterThan(photoRect.height + 20));
    expect(bookmarkRect.bottom, greaterThan(photoRect.bottom));
    expect(bookmarkRect.bottom, closeTo(cardRect.bottom - 10, 0.1));
  });
}

const _meeting = Meeting(
  id: 1,
  title: '한강 러닝',
  category: '운동',
  tags: ['운동'],
  area: '여의도',
  date: '8/10',
  time: '19:00',
  distance: '1km',
  capacity: 10,
  joined: 4,
  host: '모임장',
  description: '설명',
  fee: '무료',
  rating: 0,
  reviewCount: 0,
);

const _meetingWithWrappedTags = Meeting(
  id: 2,
  title: '한강 러닝',
  category: '운동',
  tags: ['러닝 모임', '주말 운동', '초보 환영'],
  area: '여의도',
  date: '8/10',
  time: '19:00',
  distance: '1km',
  capacity: 10,
  joined: 4,
  host: '모임장',
  description: '설명',
  fee: '무료',
  rating: 0,
  reviewCount: 0,
);
