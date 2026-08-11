import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/category_repository.dart';
import 'package:meetple/data/repositories/meeting_repository.dart';
import 'package:meetple/data/repositories/mock_image_upload_repository.dart';
import 'package:meetple/data/repositories/mock_location_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_category.dart';
import 'package:meetple/screens/discover/global_meeting_search_page.dart';
import 'package:meetple/screens/meeting_detail/meeting_detail_page.dart';

void main() {
  testWidgets('searches globally with the selected category and origin',
      (tester) async {
    final repository = _RecordingSearchRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalMeetingSearchPage(
          meetingRepository: repository,
          initialKeyword: '러닝',
          originLatitude: 37.5219,
          originLongitude: 126.9245,
          categories: const ['전체', '운동'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.queries, hasLength(1));
    expect(repository.queries.single.keyword, '러닝');
    expect(repository.queries.single.category, isNull);
    expect(repository.queries.single.latitude, 37.5219);
    expect(repository.queries.single.longitude, 126.9245);
    expect(find.text('‘러닝’ 검색 결과 1개'), findsOneWidget);
    expect(find.text('1.2km'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('global-search-category-운동')),
    );
    await tester.pumpAndSettle();

    expect(repository.queries, hasLength(2));
    expect(repository.queries.last.category, '운동');
  });

  testWidgets('loads the next global search page near the list end',
      (tester) async {
    final repository = _PagedSearchRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalMeetingSearchPage(
          meetingRepository: repository,
          initialKeyword: '러닝',
          originLatitude: 37.5219,
          originLongitude: 126.9245,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const Key('global-search-list')),
      const Offset(0, -2000),
      1200,
    );
    await tester.pumpAndSettle();

    expect(repository.queries.map((query) => query.page), containsAll([0, 1]));
    expect(find.text('다음 페이지 러닝'), findsOneWidget);
  });

  testWidgets('shows an empty state when no global meeting matches',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalMeetingSearchPage(
          meetingRepository: _EmptySearchRepository(),
          initialKeyword: '없는모임',
          originLatitude: 37.5219,
          originLongitude: 126.9245,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('전국에서 ‘없는모임’ 모임을 찾지 못했어요.'), findsOneWidget);
  });

  testWidgets('shows a retry action when global search fails', (tester) async {
    final repository = _FailingSearchRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalMeetingSearchPage(
          meetingRepository: repository,
          initialKeyword: '러닝',
          originLatitude: 37.5219,
          originLongitude: 126.9245,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('전국 모임 검색 결과를 불러오지 못했습니다.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
  });

  testWidgets('updates category filters after the page is opened',
      (tester) async {
    final categoryRepository = _DeferredCategoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalMeetingSearchPage(
          meetingRepository: _RecordingSearchRepository(),
          categoryRepository: categoryRepository,
          initialKeyword: '러닝',
          originLatitude: 37.5219,
          originLongitude: 126.9245,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('global-search-category-운동')),
      findsNothing,
    );

    categoryRepository.complete(const [
      MeetingCategory(id: 1, name: '운동'),
      MeetingCategory(id: 2, name: '스터디'),
    ]);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('global-search-category-운동')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('global-search-category-스터디')),
      findsOneWidget,
    );
  });

  testWidgets('preserves edit repositories and notifies meeting changes',
      (tester) async {
    final meetingRepository = _RecordingSearchRepository();
    final categoryRepository = _StaticCategoryRepository();
    const locationRepository = MockLocationRepository();
    const imageUploadRepository = MockImageUploadRepository();
    var changeCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GlobalMeetingSearchPage(
          meetingRepository: meetingRepository,
          categoryRepository: categoryRepository,
          locationRepository: locationRepository,
          imageUploadRepository: imageUploadRepository,
          initialKeyword: '러닝',
          originLatitude: 37.5219,
          originLongitude: 126.9245,
          onMeetingChanged: () => changeCount += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('global-search-meeting-1')),
    );
    await tester.pumpAndSettle();

    final detailPage = tester.widget<MeetingDetailPage>(
      find.byType(MeetingDetailPage),
    );
    expect(detailPage.meetingRepository, same(meetingRepository));
    expect(detailPage.categoryRepository, same(categoryRepository));
    expect(detailPage.locationRepository, same(locationRepository));
    expect(detailPage.imageUploadRepository, same(imageUploadRepository));

    Navigator.of(
      tester.element(find.byType(MeetingDetailPage)),
    ).pop(true);
    await tester.pumpAndSettle();

    expect(changeCount, 1);
    expect(meetingRepository.queries, hasLength(2));
  });
}

class _DeferredCategoryRepository implements CategoryRepository {
  final _completer = Completer<List<MeetingCategory>>();

  @override
  Future<List<MeetingCategory>> findAll() => _completer.future;

  void complete(List<MeetingCategory> categories) {
    _completer.complete(categories);
  }
}

class _StaticCategoryRepository implements CategoryRepository {
  @override
  Future<List<MeetingCategory>> findAll() async {
    return const [MeetingCategory(id: 1, name: '운동')];
  }
}

class _RecordingSearchRepository extends MockMeetingRepository {
  final List<MeetingSearchQuery> queries = [];

  @override
  Future<MeetingSearchPage> searchMeetings(MeetingSearchQuery query) async {
    queries.add(query);
    return MeetingSearchPage(
      meetings: [_meeting(1, '전국 러닝 모임')],
      page: query.page,
      totalElements: 1,
      totalPages: 1,
      isLast: true,
    );
  }
}

class _PagedSearchRepository extends MockMeetingRepository {
  final List<MeetingSearchQuery> queries = [];

  @override
  Future<MeetingSearchPage> searchMeetings(MeetingSearchQuery query) async {
    queries.add(query);
    if (query.page == 0) {
      return MeetingSearchPage(
        meetings: [
          for (var index = 0; index < 12; index++)
            _meeting(index + 1, '러닝 모임 ${index + 1}'),
        ],
        page: 0,
        totalElements: 13,
        totalPages: 2,
        isLast: false,
      );
    }
    return MeetingSearchPage(
      meetings: [_meeting(13, '다음 페이지 러닝')],
      page: 1,
      totalElements: 13,
      totalPages: 2,
      isLast: true,
    );
  }
}

class _EmptySearchRepository extends MockMeetingRepository {
  @override
  Future<MeetingSearchPage> searchMeetings(MeetingSearchQuery query) async {
    return const MeetingSearchPage(
      meetings: [],
      page: 0,
      totalElements: 0,
      totalPages: 0,
      isLast: true,
    );
  }
}

class _FailingSearchRepository extends MockMeetingRepository {
  int calls = 0;

  @override
  Future<MeetingSearchPage> searchMeetings(MeetingSearchQuery query) async {
    calls += 1;
    throw Exception('search failed');
  }
}

Meeting _meeting(int id, String title) {
  return Meeting(
    id: id,
    title: title,
    category: '운동',
    tags: const ['운동'],
    area: '여의도공원',
    latitude: 37.5219,
    longitude: 126.9245,
    date: '8/15',
    time: '19:00',
    distance: '1.2km',
    capacity: 10,
    joined: 4,
    host: '모임장',
    description: '함께 달려요.',
    fee: '무료',
    rating: 0,
    reviewCount: 0,
  );
}
