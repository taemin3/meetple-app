import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/app_navigation.dart';
import 'package:meetple/core/theme/app_colors.dart';
import 'package:meetple/data/repositories/category_repository.dart';
import 'package:meetple/data/repositories/meeting_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_category.dart';
import 'package:meetple/screens/discover/discover_page.dart';
import 'package:meetple/widgets/app_state_view.dart';
import 'package:meetple/widgets/tag_chip.dart';

void main() {
  testWidgets('shows meeting card skeletons during the first nearby load',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final meetingRepository = _DeferredNearbyMeetingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoverPage(meetingRepository: meetingRepository),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('nearby-meeting-skeleton-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('nearby-meeting-skeleton-0'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('nearby-meeting-skeleton-2'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const Key('nearby-meeting-skeleton-list')),
          )
          .label,
      '내 주변 모임을 불러오는 중입니다.',
    );
    semantics.dispose();

    meetingRepository.complete(
      await const MockMeetingRepository().findAll(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('nearby-meeting-skeleton-list')),
      findsNothing,
    );
    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);
  });

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

  testWidgets('opens global search entry and preserves the map query on return',
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

    await tester.enterText(
      find.byKey(const Key('discover-search-field')),
      '러닝',
    );
    await tester.pump();

    expect(
      find.byKey(const Key('discover-global-search-entry')),
      findsOneWidget,
    );
    expect(find.text('전체 모임에서 ‘러닝’ 검색'), findsOneWidget);

    await tester.tap(find.text('전체 모임에서 ‘러닝’ 검색'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global-meeting-search-page')), findsOneWidget);
    expect(find.textContaining('‘러닝’ 검색 결과'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();

    final searchField = tester.widget<TextField>(
      find.byKey(const Key('discover-search-field')),
    );
    expect(searchField.controller?.text, '러닝');
    expect(
      find.byKey(const Key('discover-global-search-entry')),
      findsOneWidget,
    );
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

  testWidgets('submits a participation request from meeting detail',
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
    await tester.tap(find.text('참여 신청하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '함께 참여하고 싶어요.');
    await tester.tap(find.text('신청하기'));
    await tester.pumpAndSettle();

    expect(find.text('승인 대기 중 · 신청 취소'), findsOneWidget);
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

    final selectedChip = find.ancestor(
      of: find.text('전체'),
      matching: find.byType(TagChip),
    );
    final unselectedChip = find.ancestor(
      of: find.text('러닝'),
      matching: find.byType(TagChip),
    );
    final selectedDecoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: selectedChip,
        matching: find.byType(DecoratedBox),
      ),
    );
    final unselectedDecoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: unselectedChip,
        matching: find.byType(DecoratedBox),
      ),
    );

    expect(
      (selectedDecoration.decoration as BoxDecoration).color,
      AppColors.primary,
    );
    expect(
      (unselectedDecoration.decoration as BoxDecoration).color,
      Colors.white,
    );
    expect(tester.getSize(selectedChip).height, lessThan(36));
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

  testWidgets('reloads all meetings after an invalid entry category', (
    tester,
  ) async {
    final categoryRepository = _DeferredCategoryRepository();
    final meetingRepository = _RecordingNearbyMeetingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoverPage(
            meetingRepository: meetingRepository,
            categoryRepository: categoryRepository,
            openRequest: const DiscoverOpenRequest(
              id: 1,
              category: '여행',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(meetingRepository.queries.last.category, '여행');

    categoryRepository.complete(const [
      MeetingCategory(id: 10, name: '러닝'),
    ]);
    await tester.pumpAndSettle();

    expect(meetingRepository.queries.last.category, isNull);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);
  });

  testWidgets('reloads all meetings after entry category loading fails', (
    tester,
  ) async {
    final categoryRepository = _DeferredCategoryRepository();
    final meetingRepository = _RecordingNearbyMeetingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoverPage(
            meetingRepository: meetingRepository,
            categoryRepository: categoryRepository,
            openRequest: const DiscoverOpenRequest(
              id: 1,
              category: '여행',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(meetingRepository.queries.last.category, '여행');

    categoryRepository.fail();
    await tester.pumpAndSettle();

    expect(meetingRepository.queries.last.category, isNull);
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);
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

class _DeferredCategoryRepository implements CategoryRepository {
  final _completer = Completer<List<MeetingCategory>>();

  @override
  Future<List<MeetingCategory>> findAll() => _completer.future;

  void complete(List<MeetingCategory> categories) {
    _completer.complete(categories);
  }

  void fail() {
    _completer.completeError(StateError('category load failed'));
  }
}

class _RecordingNearbyMeetingRepository extends MockMeetingRepository {
  final queries = <NearbyMeetingQuery>[];

  @override
  Future<List<Meeting>> findNearby(NearbyMeetingQuery query) {
    queries.add(query);
    return super.findNearby(query);
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

class _DeferredNearbyMeetingRepository extends MockMeetingRepository {
  final Completer<List<Meeting>> _completer = Completer<List<Meeting>>();

  @override
  Future<List<Meeting>> findNearby(NearbyMeetingQuery query) {
    return _completer.future;
  }

  void complete(List<Meeting> meetings) {
    _completer.complete(meetings);
  }
}
