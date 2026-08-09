import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/meetple_app.dart';
import 'package:meetple/core/push/push_notification_message.dart';
import 'package:meetple/core/push/push_notification_service.dart';
import 'package:meetple/data/mock/mock_auth.dart';
import 'package:meetple/data/repositories/auth_repository.dart';
import 'package:meetple/data/repositories/category_repository.dart';
import 'package:meetple/data/repositories/location_repository.dart';
import 'package:meetple/data/repositories/meeting_repository.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/models/auth_session.dart';
import 'package:meetple/models/location_search_result.dart';
import 'package:meetple/models/meeting.dart';
import 'package:meetple/models/meeting_category.dart';
import 'package:meetple/screens/auth/login_page.dart';
import 'package:meetple/screens/home/home_page.dart';
import 'package:meetple/screens/meeting_detail/meeting_detail_page.dart';

void main() {
  testWidgets('shows meeting card skeletons during the first home load', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final meetingRepository = _DeferredFindAllRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(meetingRepository: meetingRepository),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('home-meeting-skeleton-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-meeting-skeleton-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-meeting-skeleton-2')),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const Key('home-meeting-skeleton-list')),
          )
          .label,
      '추천 모임을 불러오는 중입니다.',
    );
    semantics.dispose();

    meetingRepository.complete(
      await const MockMeetingRepository().findAll(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('home-meeting-skeleton-list')),
      findsNothing,
    );
    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);
  });

  testWidgets('keeps home cards visible while refreshing existing data', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final meetingRepository = _RefreshableFindAllRepository();
    Widget buildHome(int refreshToken) {
      return MaterialApp(
        home: Scaffold(
          body: HomePage(
            meetingRepository: meetingRepository,
            refreshToken: refreshToken,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildHome(0));
    await tester.pumpAndSettle();
    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);

    await tester.pumpWidget(buildHome(1));
    await tester.pump();

    expect(
      find.byKey(const Key('home-meeting-skeleton-list')),
      findsNothing,
    );
    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    meetingRepository.completeRefresh(
      await const MockMeetingRepository().findAll(),
    );
    await tester.pumpAndSettle();

    expect(find.text('한강 러닝 크루 🏃'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('shows Meetple home when session is restored', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();

    expect(
      find.text('\uCD94\uCC9C \uBAA8\uC784', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('keeps tab data loaded while switching tabs', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final meetingRepository = _CountingMeetingRepository();
    await tester.pumpWidget(
      MeetpleApp(meetingRepository: meetingRepository),
    );
    await tester.pumpAndSettle();

    expect(meetingRepository.findAllCount, 1);
    expect(meetingRepository.findNearbyCount, 0);

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    expect(meetingRepository.findNearbyCount, 1);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();

    expect(meetingRepository.findAllCount, 1);
    expect(meetingRepository.findNearbyCount, 1);
  });

  testWidgets('pauses skeleton animations in an inactive tab', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final meetingRepository = _DeferredFindAllRepository();
    await tester.pumpWidget(
      MeetpleApp(meetingRepository: meetingRepository),
    );
    await tester.pump();

    final homeSkeleton = find.byKey(
      const Key('home-meeting-skeleton-list'),
      skipOffstage: false,
    );
    expect(homeSkeleton, findsOneWidget);
    expect(
      tester
          .widget<TickerMode>(
            find.byKey(const ValueKey('app-tab-ticker-home')),
          )
          .enabled,
      isTrue,
    );

    await tester.tap(find.text('탐색'));
    await tester.pump();

    expect(
      tester
          .widget<TickerMode>(
            find.byKey(
              const ValueKey('app-tab-ticker-home'),
              skipOffstage: false,
            ),
          )
          .enabled,
      isFalse,
    );

    meetingRepository.complete(
      await const MockMeetingRepository().findAll(),
    );
    await tester.pump();
  });

  testWidgets('dismisses the search keyboard when switching tabs', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField).first;
    await tester.showKeyboard(searchField);
    final searchFocusNode = tester
        .widget<EditableText>(
          find.descendant(
            of: searchField,
            matching: find.byType(EditableText),
          ),
        )
        .focusNode;
    expect(searchFocusNode.hasFocus, isTrue);

    await tester.tap(find.text('홈'));
    await tester.pump();

    expect(searchFocusNode.hasFocus, isFalse);
  });

  testWidgets('refreshes the other visited tab after a meeting changes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final meetingRepository = _CountingMeetingRepository();
    await tester.pumpWidget(
      MeetpleApp(meetingRepository: meetingRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    final initialNearbyLoadCount = meetingRepository.findNearbyCount;
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    final initialHomeLoadCount = meetingRepository.findAllCount;

    await tester.tap(find.text('한강 러닝 크루 🏃'));
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.text('모임 소개')),
    ).pop('updated');
    await tester.pumpAndSettle();

    expect(meetingRepository.findAllCount, initialHomeLoadCount + 1);
    expect(meetingRepository.findNearbyCount, initialNearbyLoadCount);

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();

    expect(meetingRepository.findNearbyCount, initialNearbyLoadCount + 1);
  });

  testWidgets('opens create meeting screen from home banner', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final meetingRepository = _CountingMeetingRepository();
    await tester.pumpWidget(
      MeetpleApp(meetingRepository: meetingRepository),
    );
    await tester.pumpAndSettle();
    final initialLoadCount = meetingRepository.findAllCount;

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const Key('create_meeting_submit'))),
    ).pop(_createdMeeting);
    await tester.pumpAndSettle();

    expect(meetingRepository.findAllCount, initialLoadCount + 1);
  });

  testWidgets('opens create meeting screen from bottom action', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final meetingRepository = _CountingMeetingRepository();
    await tester.pumpWidget(
      MeetpleApp(meetingRepository: meetingRepository),
    );
    await tester.pumpAndSettle();
    final initialLoadCount = meetingRepository.findAllCount;

    await tester.tap(
      find.byKey(const Key('bottom-create-meeting-action')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_meeting_submit')), findsOneWidget);
    expect(
      find.byKey(const Key('app-bottom-navigation')),
      findsNothing,
    );

    Navigator.of(
      tester.element(find.byKey(const Key('create_meeting_submit'))),
    ).pop(_createdMeeting);
    await tester.pumpAndSettle();

    expect(meetingRepository.findAllCount, initialLoadCount + 1);
  });

  testWidgets('reloads discover meetings after creating from bottom action', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final meetingRepository = _CountingMeetingRepository();
    await tester.pumpWidget(
      MeetpleApp(meetingRepository: meetingRepository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    final initialLoadCount = meetingRepository.findNearbyCount;
    final initialHomeLoadCount = meetingRepository.findAllCount;

    await tester.tap(
      find.byKey(const Key('bottom-create-meeting-action')),
    );
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byKey(const Key('create_meeting_submit'))),
    ).pop(_createdMeeting);
    await tester.pumpAndSettle();

    expect(meetingRepository.findNearbyCount, initialLoadCount + 1);
    expect(meetingRepository.findAllCount, initialHomeLoadCount);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();

    expect(meetingRepository.findAllCount, initialHomeLoadCount + 1);
  });

  testWidgets('keeps create action fixed while form scrolls and keyboard opens',
      (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('bottom-create-meeting-action')),
    );
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('create_meeting_submit'));
    final initialTop = tester.getTopLeft(submitButton).dy;

    await tester.drag(
      find.byKey(const Key('meeting_form_scroll_view')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(submitButton).dy, initialTop);

    await tester.showKeyboard(
      find.descendant(
        of: find.byKey(const Key('create_meeting_title')),
        matching: find.byType(TextFormField),
      ),
    );
    await tester.pump();

    expect(tester.getTopLeft(submitButton).dy, initialTop);
  });

  testWidgets('validates create meeting form before submit', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_meeting_submit')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '\uBAA8\uC784 \uC81C\uBAA9\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows categories from category repository in create form', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MeetpleApp(
        categoryRepository: _StaticCategoryRepository([
          MeetingCategory(id: 10, name: '러닝'),
          MeetingCategory(id: 11, name: '독서'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.text('러닝'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create_meeting_category')));
    await tester.pumpAndSettle();

    expect(find.text('독서'), findsWidgets);
  });

  testWidgets('selects location from location picker in create form', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MeetpleApp(
        locationRepository: _StaticLocationRepository([
          LocationSearchResult(
            id: 'test-location',
            type: 'PLACE',
            name: '여의도공원',
            category: '공원',
            address: '서울 영등포구 여의공원로 68',
            latitude: 37.5268,
            longitude: 126.9228,
            provider: 'NAVER',
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_meeting_location_name')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('location_picker_query')),
      '여의도공원',
    );
    await tester.tap(find.byKey(const Key('location_picker_search')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('location_picker_result_0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('location_picker_map_unavailable')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('location_picker_confirm')), findsOneWidget);

    await tester.tap(find.byKey(const Key('location_picker_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('여의도공원'), findsWidgets);
    expect(find.text('서울 영등포구 여의공원로 68'), findsOneWidget);
  });

  testWidgets('shows authenticated profile from auth repository', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('\uAE40\uBAA8\uC784'), findsOneWidget);
    expect(find.text('@gather_together'), findsOneWidget);
  });

  testWidgets('shows login first when no session is restored', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('\uD68C\uC6D0\uAC00\uC785'), findsOneWidget);
  });

  testWidgets('enters app after signing in from entry login', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pushNotificationService = _RecordingPushNotificationService();
    addTearDown(pushNotificationService.dispose);
    await tester.pumpWidget(
      MeetpleApp(
        authRepository: MockAuthRepository(session: null),
        pushNotificationService: pushNotificationService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('\uB85C\uADF8\uC778'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(pushNotificationService.activateCount, 1);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('\uAE40\uBAA8\uC784'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('\uAE40\uBAA8\uC784'), findsOneWidget);
  });

  testWidgets('returns to entry login after signing out', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authRepository = MockAuthRepository();
    final pushNotificationService = _RecordingPushNotificationService();
    addTearDown(pushNotificationService.dispose);
    await tester.pumpWidget(
      MeetpleApp(
        authRepository: authRepository,
        pushNotificationService: pushNotificationService,
      ),
    );
    await tester.pumpAndSettle();

    expect(pushNotificationService.activateCount, 1);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_sign_out')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_sign_out')));
    await tester.pumpAndSettle();

    expect(await authRepository.restoreSession(), isNull);
    expect(pushNotificationService.deactivateCount, 1);
    expect(find.byKey(const Key('profile_sign_out')), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('opens meeting detail from a terminated push notification', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pushNotificationService = _RecordingPushNotificationService(
      pendingNotification: const PushNotificationMessage({
        'route': 'MEETING_DETAIL',
        'meetingId': '1',
        'notificationId': '501',
      }),
    );
    addTearDown(pushNotificationService.dispose);
    final meetingRepository = _PushNavigationMeetingRepository();

    await tester.pumpWidget(
      MeetpleApp(
        authRepository: MockAuthRepository(),
        pushNotificationService: pushNotificationService,
        meetingRepository: meetingRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MeetingDetailPage), findsOneWidget);
    expect(meetingRepository.requestedMeetingIds, [1]);
    expect(meetingRepository.readNotificationIds, [501]);
  });

  testWidgets('opens meeting detail from an opened push notification stream', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pushNotificationService = _RecordingPushNotificationService();
    addTearDown(pushNotificationService.dispose);
    final meetingRepository = _PushNavigationMeetingRepository();
    await tester.pumpWidget(
      MeetpleApp(
        authRepository: MockAuthRepository(),
        pushNotificationService: pushNotificationService,
        meetingRepository: meetingRepository,
      ),
    );
    await tester.pumpAndSettle();

    pushNotificationService.emit(
      const PushNotificationMessage({
        'route': 'MEETING_DETAIL',
        'meetingId': '2',
        'notificationId': '502',
      }),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MeetingDetailPage), findsOneWidget);
    expect(meetingRepository.requestedMeetingIds, [2]);
    expect(meetingRepository.readNotificationIds, [502]);
  });

  testWidgets('opens a later push while the current detail remains visible', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pushNotificationService = _RecordingPushNotificationService();
    addTearDown(pushNotificationService.dispose);
    final meetingRepository = _PushNavigationMeetingRepository();
    await tester.pumpWidget(
      MeetpleApp(
        authRepository: MockAuthRepository(),
        pushNotificationService: pushNotificationService,
        meetingRepository: meetingRepository,
      ),
    );
    await tester.pumpAndSettle();

    pushNotificationService.emit(
      const PushNotificationMessage({
        'route': 'MEETING_DETAIL',
        'meetingId': '1',
      }),
    );
    await tester.pumpAndSettle();
    pushNotificationService.emit(
      const PushNotificationMessage({
        'route': 'MEETING_DETAIL',
        'meetingId': '2',
      }),
    );
    await tester.pumpAndSettle();

    expect(meetingRepository.requestedMeetingIds, [1, 2]);
    expect(
      find.byType(MeetingDetailPage, skipOffstage: false),
      findsNWidgets(2),
    );
  });

  testWidgets('refreshes meeting tabs after a push detail reports a change', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final pushNotificationService = _RecordingPushNotificationService();
    addTearDown(pushNotificationService.dispose);
    final meetingRepository = _PushNavigationMeetingRepository();
    await tester.pumpWidget(
      MeetpleApp(
        authRepository: MockAuthRepository(),
        pushNotificationService: pushNotificationService,
        meetingRepository: meetingRepository,
      ),
    );
    await tester.pumpAndSettle();
    final initialLoadCount = meetingRepository.findAllCount;

    pushNotificationService.emit(
      const PushNotificationMessage({
        'route': 'MEETING_DETAIL',
        'meetingId': '1',
      }),
    );
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(MeetingDetailPage)))
        .pop(_createdMeeting);
    await tester.pumpAndSettle();

    expect(meetingRepository.findAllCount, initialLoadCount + 1);
  });

  testWidgets('ignores stale restore result after auth repository changes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final staleRepository = _DeferredAuthRepository();
    final currentRepository = MockAuthRepository(session: null);

    await tester.pumpWidget(MeetpleApp(authRepository: staleRepository));
    await tester.pump();

    await tester.pumpWidget(MeetpleApp(authRepository: currentRepository));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);

    staleRepository.completeRestore(mockAuthSession);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text('\uCD94\uCC9C \uBAA8\uC784', skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('moves sign up from account step to profile step', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('\uD68C\uC6D0\uAC00\uC785'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign_up_all_terms')), findsOneWidget);
    expect(find.text('\uB2E4\uC74C'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password1!');
    await tester.enterText(find.byType(TextField).at(2), 'password1!');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign_up_all_terms')));
    await tester.pump();
    await tester.tap(find.text('\uB2E4\uC74C'));
    await tester.pumpAndSettle();

    expect(find.text('\uAC00\uC785 \uC644\uB8CC'), findsOneWidget);
  });
}

class _RecordingPushNotificationService implements PushNotificationService {
  _RecordingPushNotificationService({
    PushNotificationMessage? pendingNotification,
  }) : _pendingNotification = pendingNotification;

  int activateCount = 0;
  int deactivateCount = 0;
  final StreamController<PushNotificationMessage> _openedController =
      StreamController<PushNotificationMessage>.broadcast(sync: true);
  PushNotificationMessage? _pendingNotification;

  @override
  Stream<PushNotificationMessage> get openedNotifications =>
      _openedController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> activate() async {
    activateCount += 1;
  }

  @override
  Future<void> deactivate() async {
    deactivateCount += 1;
  }

  @override
  Future<String?> deviceId() async => 'installation-1';

  @override
  PushNotificationMessage? takePendingOpenedNotification() {
    final pending = _pendingNotification;
    _pendingNotification = null;
    return pending;
  }

  void emit(PushNotificationMessage notification) {
    _openedController.add(notification);
  }

  Future<void> dispose() => _openedController.close();
}

class _PushNavigationMeetingRepository extends MockMeetingRepository {
  final requestedMeetingIds = <int>[];
  final readNotificationIds = <int>[];
  int findAllCount = 0;

  @override
  Future<List<Meeting>> findAll() {
    findAllCount++;
    return super.findAll();
  }

  @override
  Future<Meeting> findById(int meetingId) {
    requestedMeetingIds.add(meetingId);
    return super.findById(meetingId);
  }

  @override
  Future<void> markNotificationRead(int notificationId) async {
    readNotificationIds.add(notificationId);
  }
}

class _StaticLocationRepository implements LocationRepository {
  const _StaticLocationRepository(this.locations);

  final List<LocationSearchResult> locations;

  @override
  Future<List<LocationSearchResult>> search(
    String query, {
    int display = 5,
  }) async {
    return locations.take(display).toList();
  }

  @override
  Future<LocationSearchResult> reverse({
    required double latitude,
    required double longitude,
  }) async {
    return locations.first.copyWith(
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class _StaticCategoryRepository implements CategoryRepository {
  const _StaticCategoryRepository(this.categories);

  final List<MeetingCategory> categories;

  @override
  Future<List<MeetingCategory>> findAll() async {
    return categories;
  }
}

class _DeferredAuthRepository implements AuthRepository {
  final Completer<AuthSession?> _restoreCompleter = Completer<AuthSession?>();

  void completeRestore(AuthSession? session) {
    _restoreCompleter.complete(session);
  }

  @override
  Future<AuthSession?> restoreSession() {
    return _restoreCompleter.future;
  }

  @override
  Future<AuthSession?> refreshSession() => restoreSession();

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

class _CountingMeetingRepository extends MockMeetingRepository {
  int findAllCount = 0;
  int findNearbyCount = 0;

  @override
  Future<List<Meeting>> findAll() {
    findAllCount++;
    return super.findAll();
  }

  @override
  Future<List<Meeting>> findNearby(NearbyMeetingQuery query) {
    findNearbyCount++;
    return super.findNearby(query);
  }
}

class _DeferredFindAllRepository extends MockMeetingRepository {
  final Completer<List<Meeting>> _completer = Completer<List<Meeting>>();

  @override
  Future<List<Meeting>> findAll() {
    return _completer.future;
  }

  void complete(List<Meeting> meetings) {
    _completer.complete(meetings);
  }
}

class _RefreshableFindAllRepository extends MockMeetingRepository {
  final Completer<List<Meeting>> _refreshCompleter = Completer<List<Meeting>>();
  int _findAllCount = 0;

  @override
  Future<List<Meeting>> findAll() {
    _findAllCount++;
    if (_findAllCount == 1) {
      return super.findAll();
    }
    return _refreshCompleter.future;
  }

  void completeRefresh(List<Meeting> meetings) {
    _refreshCompleter.complete(meetings);
  }
}

const _createdMeeting = Meeting(
  id: 100,
  title: '새 모임',
  category: '운동',
  tags: ['운동'],
  area: '서울',
  date: '8/10',
  time: '19:30',
  distance: '1km',
  capacity: 10,
  joined: 1,
  host: '모임장',
  description: '새로 만든 모임',
  fee: '무료',
  rating: 0,
  reviewCount: 0,
);
