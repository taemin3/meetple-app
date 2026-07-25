import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/category_repository.dart';
import 'package:meetple/data/repositories/meeting_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_category.dart';
import 'package:meetple/screens/discover/discover_page.dart';
import 'package:meetple/widgets/app_state_view.dart';

void main() {
  testWidgets('shows nearby discovery without a title app bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiscoverPage(
            meetingRepository: MockMeetingRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지도'), findsNothing);
    expect(find.text('모임, 장소, 카테고리 검색'), findsOneWidget);
    expect(find.text('내 주변 모임 🔥'), findsOneWidget);
    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);
  });

  testWidgets('opens meeting detail from a nearby meeting card',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiscoverPage(
            meetingRepository: MockMeetingRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('한강 러닝 크루 🏃'));
    await tester.pumpAndSettle();

    expect(find.text('모임 소개'), findsOneWidget);
    expect(find.text('모임장'), findsWidgets);
    expect(find.text('모임 위치'), findsOneWidget);
    expect(find.text('참여 신청하기'), findsOneWidget);
    expect(find.text('참여하기'), findsNothing);
    expect(find.byIcon(Icons.ios_share_rounded), findsNothing);
    expect(
      find.byKey(const Key('meeting-detail-hero-favorite-button')),
      findsOneWidget,
    );

    await tester.drag(
      find.byType(ListView),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('meeting-detail-back-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('meeting-detail-hero-favorite-button')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('meeting-location-preview')),
        matching: find.byIcon(Icons.location_on_rounded),
      ),
      findsOneWidget,
    );

    final fullMapButton = find.byKey(
      const Key('meeting-location-full-map-button'),
    );
    await tester.ensureVisible(fullMapButton);
    await tester.pumpAndSettle();
    await tester.tap(fullMapButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('collapses and expands the nearby meeting sheet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiscoverPage(
            meetingRepository: MockMeetingRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);

    await tester.tap(find.text('내 주변 모임 🔥'));
    await tester.pumpAndSettle();

    expect(find.text('한강 러닝 크루 🏃'), findsNothing);

    await tester.tap(find.text('내 주변 모임 🔥'));
    await tester.pumpAndSettle();

    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);
  });

  testWidgets('opens a chooser for meetings sharing one map position',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiscoverPage(
            meetingRepository: _OverlappingMeetingRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('meeting-group-marker')));
    await tester.pumpAndSettle();

    expect(find.text('2개의 모임이 있어요'), findsOneWidget);
    expect(find.text('확인할 모임을 선택해 주세요.'), findsOneWidget);
  });

  testWidgets('uses the same repository categories as meeting creation',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiscoverPage(
            meetingRepository: MockMeetingRepository(),
            categoryRepository: _DiscoverCategoryRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('전체'), findsOneWidget);
    expect(find.text('러닝'), findsOneWidget);
    expect(find.text('독서'), findsOneWidget);
    expect(find.text('여행'), findsNothing);
  });

  testWidgets('hides stale meetings when a refreshed search fails',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DiscoverPage(
            meetingRepository: _FailsFilteredNearbyRepository(),
            categoryRepository: _DiscoverCategoryRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('nearby-meeting-card-1')),
      findsOneWidget,
    );

    await tester.tap(find.text('러닝'));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(
      find.byKey(const ValueKey('nearby-meeting-card-1')),
      findsNothing,
    );
  });
}

class _DiscoverCategoryRepository implements CategoryRepository {
  const _DiscoverCategoryRepository();

  @override
  Future<List<MeetingCategory>> findAll() async {
    return const [
      MeetingCategory(id: 10, name: '러닝'),
      MeetingCategory(id: 11, name: '독서'),
    ];
  }
}

class _OverlappingMeetingRepository extends MeetingRepository {
  const _OverlappingMeetingRepository();

  static const _delegate = MockMeetingRepository();

  @override
  Future<List<Meeting>> findAll() => _delegate.findAll();

  @override
  Future<List<Meeting>> findNearby(NearbyMeetingQuery query) async {
    final meetings = await _delegate.findNearby(query);
    return meetings.take(2).map((meeting) {
      return meeting.copyWith(
        latitude: query.latitude,
        longitude: query.longitude,
      );
    }).toList(growable: false);
  }

  @override
  Future<Meeting> createMeeting(CreateMeetingInput input) {
    return _delegate.createMeeting(input);
  }
}

class _FailsFilteredNearbyRepository extends MeetingRepository {
  const _FailsFilteredNearbyRepository();

  static const _delegate = MockMeetingRepository();

  @override
  Future<List<Meeting>> findAll() => _delegate.findAll();

  @override
  Future<List<Meeting>> findNearby(NearbyMeetingQuery query) {
    if (query.category != null) {
      throw StateError('nearby search failed');
    }
    return _delegate.findNearby(query);
  }

  @override
  Future<Meeting> createMeeting(CreateMeetingInput input) {
    return _delegate.createMeeting(input);
  }
}
