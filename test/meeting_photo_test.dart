import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/mock/mock_meetings.dart';
import 'package:meetple/widgets/meeting_photo.dart';

void main() {
  testWidgets('uses the backend thumbnail URL for a meeting photo',
      (tester) async {
    const thumbnailUrl = 'https://cdn.meetple.com/meetings/1/thumbnail.png';
    final meeting = mockMeetings.first.copyWith(
      thumbnailImageUrl: thumbnailUrl,
      imageUrls: const [
        'https://cdn.meetple.com/meetings/1/secondary.png',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeetingPhoto(meeting: meeting),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byKey(const Key('meeting-photo-network')),
    );
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(
      tester.element(find.byType(MeetingPhoto)),
    );
    final expectedCacheHeight = (120 * devicePixelRatio).ceil();
    expect(image.imageUrl, thumbnailUrl);
    expect(image.memCacheHeight, expectedCacheHeight);
    expect(image.maxHeightDiskCache, expectedCacheHeight);
    expect(image.fadeInDuration, Duration.zero);
    expect(image.fadeOutDuration, Duration.zero);
    expect(image.useOldImageOnUrlChange, isTrue);
    expect(
      find.byKey(const Key('meeting-photo-loading-skeleton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('meeting-photo-fallback')), findsNothing);
  });

  test('uses the first image URL when a thumbnail is unavailable', () {
    final meeting = mockMeetings.first.copyWith(
      thumbnailImageUrl: ' ',
      imageUrls: const [
        '',
        'https://cdn.meetple.com/meetings/1/first.png',
        'https://cdn.meetple.com/meetings/1/second.png',
      ],
    );

    expect(
      meeting.primaryImageUrl,
      'https://cdn.meetple.com/meetings/1/first.png',
    );
  });

  test('can explicitly clear a meeting thumbnail', () {
    final meeting = mockMeetings.first.copyWith(
      thumbnailImageUrl: 'https://cdn.meetple.com/meetings/1/thumbnail.png',
    );

    final cleared = meeting.copyWith(
      clearThumbnailImageUrl: true,
      imageUrls: const [],
    );

    expect(cleared.thumbnailImageUrl, isNull);
    expect(cleared.primaryImageUrl, isNull);
  });

  testWidgets('keeps the illustrated fallback without an image URL',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeetingPhoto(meeting: mockMeetings.first),
        ),
      ),
    );

    expect(find.byKey(const Key('meeting-photo-network')), findsNothing);
    expect(find.byKey(const Key('meeting-photo-fallback')), findsOneWidget);
  });
}
