import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/screens/meeting_detail/meeting_detail_page.dart';
import 'package:meetple/widgets/meeting_image_gallery.dart';

void main() {
  test('keeps the thumbnail first and removes duplicate image URLs', () {
    expect(
      meetingImageUrls(_meeting),
      [
        'https://example.com/first.png',
        'https://example.com/second.png',
      ],
    );
  });

  testWidgets('swipes detail images and opens a zoomable full-screen viewer',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: MeetingImageGallery(meeting: _meeting),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _clearExpectedImageErrors(tester);

    expect(
      find.byKey(const Key('meeting-detail-image-counter')),
      findsOneWidget,
    );
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('meeting-detail-image-gallery')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    _clearExpectedImageErrors(tester);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('meeting-detail-image-gallery')),
      const Offset(320, 0),
    );
    await tester.pumpAndSettle();
    _clearExpectedImageErrors(tester);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('meeting-detail-image-0')),
    );
    await tester.pumpAndSettle();
    _clearExpectedImageErrors(tester);

    expect(find.byKey(const Key('meeting-image-viewer')), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('meeting-image-viewer-pages'))),
      tester.getSize(find.byKey(const Key('meeting-image-viewer'))),
    );

    await tester.drag(
      find.byKey(const Key('meeting-image-viewer-pages')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    _clearExpectedImageErrors(tester);
    expect(find.text('2 / 2'), findsOneWidget);

    final interactiveViewerFinder =
        find.byKey(const Key('meeting-image-interactive-viewer'));
    await _doubleTap(tester, interactiveViewerFinder);
    await tester.pump();

    var interactiveViewer =
        tester.widget<InteractiveViewer>(interactiveViewerFinder);
    expect(
      interactiveViewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );

    await _doubleTap(tester, interactiveViewerFinder);
    await tester.pump();

    interactiveViewer =
        tester.widget<InteractiveViewer>(interactiveViewerFinder);
    expect(
      interactiveViewer.transformationController!.value.getMaxScaleOnAxis(),
      closeTo(1, 0.01),
    );
  });

  testWidgets('detail hero overlay passes swipe and tap gestures to gallery',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DetailHero(meeting: _meeting),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _clearExpectedImageErrors(tester);

    await tester.drag(
      find.byKey(const Key('meeting-detail-image-gallery')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    _clearExpectedImageErrors(tester);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('meeting-detail-image-1')),
    );
    await tester.pumpAndSettle();
    _clearExpectedImageErrors(tester);

    expect(find.byKey(const Key('meeting-image-viewer')), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });
}

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

void _clearExpectedImageErrors(WidgetTester tester) {
  while (tester.takeException() != null) {}
}

const _meeting = Meeting(
  id: 10,
  title: '이미지 모임',
  category: '취미',
  tags: ['취미'],
  area: '서울',
  date: '8/10',
  time: '19:30',
  distance: '1km',
  capacity: 10,
  joined: 2,
  host: '모임장',
  description: '이미지 갤러리 테스트',
  fee: '무료',
  rating: 0,
  reviewCount: 0,
  thumbnailImageUrl: 'https://example.com/first.png',
  imageUrls: [
    'https://example.com/first.png',
    'https://example.com/second.png',
  ],
);
