import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/app_routes.dart';
import 'package:meetple/app/meeting_repository_scope.dart';
import 'package:meetple/data/repositories/mock_category_repository.dart';
import 'package:meetple/data/repositories/mock_image_upload_repository.dart';
import 'package:meetple/data/repositories/mock_location_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_engagement.dart';
import 'package:meetple/screens/discover/global_meeting_search_page.dart';
import 'package:meetple/screens/meeting_detail/meeting_detail_page.dart';
import 'package:meetple/screens/meeting_detail/meeting_edit_page.dart';

void main() {
  testWidgets('passes scoped repositories through the meeting detail route',
      (tester) async {
    final meetingRepository = _HostMeetingRepository();
    const categoryRepository = MockCategoryRepository();
    const locationRepository = MockLocationRepository();
    const imageUploadRepository = MockImageUploadRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: MeetingRepositoryScope(
          repository: meetingRepository,
          categoryRepository: categoryRepository,
          locationRepository: locationRepository,
          imageUploadRepository: imageUploadRepository,
          child: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => AppRoutes.openMeetingDetail<void>(
                  context,
                  _meeting,
                ),
                child: const Text('상세 열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('상세 열기'));
    await tester.pumpAndSettle();

    final detailPage = tester.widget<MeetingDetailPage>(
      find.byType(MeetingDetailPage),
    );
    expect(detailPage.meetingRepository, same(meetingRepository));
    expect(detailPage.categoryRepository, same(categoryRepository));
    expect(detailPage.locationRepository, same(locationRepository));
    expect(detailPage.imageUploadRepository, same(imageUploadRepository));

    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();

    final editPage = tester.widget<MeetingEditPage>(
      find.byType(MeetingEditPage),
    );
    expect(meetingRepository.requestedMeetingIds, [10]);
    expect(editPage.meeting.imageUrls, [
      'https://cdn.example.com/images/meeting/1/meeting.png',
    ]);
    expect(editPage.meeting.imageObjectKeys, [
      'images/meeting/1/meeting.png',
    ]);
    expect(editPage.meetingRepository, same(meetingRepository));
    expect(editPage.categoryRepository, same(categoryRepository));
    expect(editPage.locationRepository, same(locationRepository));
    expect(editPage.imageUploadRepository, same(imageUploadRepository));
  });

  testWidgets('passes scoped repositories through the global search route',
      (tester) async {
    final meetingRepository = _HostMeetingRepository();
    const categoryRepository = MockCategoryRepository();
    const locationRepository = MockLocationRepository();
    const imageUploadRepository = MockImageUploadRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: MeetingRepositoryScope(
          repository: meetingRepository,
          categoryRepository: categoryRepository,
          locationRepository: locationRepository,
          imageUploadRepository: imageUploadRepository,
          child: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => AppRoutes.openGlobalMeetingSearch<void>(
                  context,
                  keyword: '러닝',
                  originLatitude: 37.5219,
                  originLongitude: 126.9245,
                  categories: const ['전체'],
                ),
                child: const Text('전체 검색 열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('전체 검색 열기'));
    await tester.pumpAndSettle();

    final searchPage = tester.widget<GlobalMeetingSearchPage>(
      find.byType(GlobalMeetingSearchPage),
    );
    expect(searchPage.meetingRepository, same(meetingRepository));
    expect(searchPage.categoryRepository, same(categoryRepository));
    expect(searchPage.locationRepository, same(locationRepository));
    expect(searchPage.imageUploadRepository, same(imageUploadRepository));
  });
}

class _HostMeetingRepository extends MockMeetingRepository {
  final requestedMeetingIds = <int>[];

  @override
  Future<Meeting> findById(int meetingId) async {
    requestedMeetingIds.add(meetingId);
    return _meeting.copyWith(
      imageUrls: const [
        'https://cdn.example.com/images/meeting/1/meeting.png',
      ],
      imageObjectKeys: const ['images/meeting/1/meeting.png'],
    );
  }

  @override
  Future<MeetingEngagement> getEngagement(int meetingId) async {
    return const MeetingEngagement(
      isHost: true,
      isBookmarked: false,
    );
  }
}

const _meeting = Meeting(
  id: 10,
  title: '저녁 러닝',
  category: '운동',
  tags: ['운동'],
  area: '여의도',
  date: '8/10',
  time: '19:30',
  distance: '1km',
  capacity: 10,
  joined: 2,
  host: '모임장',
  description: '함께 달려요.',
  fee: '무료',
  rating: 0,
  reviewCount: 0,
);
