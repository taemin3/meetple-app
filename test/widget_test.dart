import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/meetple_app.dart';
import 'package:meetple/data/mock/mock_auth.dart';
import 'package:meetple/data/repositories/auth_repository.dart';
import 'package:meetple/data/repositories/category_repository.dart';
import 'package:meetple/data/repositories/location_repository.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/models/auth_session.dart';
import 'package:meetple/models/location_search_result.dart';
import 'package:meetple/models/meeting_category.dart';
import 'package:meetple/screens/auth/login_page.dart';

void main() {
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

  testWidgets('opens create meeting screen from home banner', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });

  testWidgets('opens create meeting screen from bottom action', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('bottom-create-meeting-action')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_meeting_submit')), findsOneWidget);
    expect(
      find.byKey(const Key('app-bottom-navigation')),
      findsNothing,
    );
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

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('\uB85C\uADF8\uC778'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);

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
    await tester.pumpWidget(MeetpleApp(authRepository: authRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_sign_out')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_sign_out')));
    await tester.pumpAndSettle();

    expect(await authRepository.restoreSession(), isNull);
    expect(find.byKey(const Key('profile_sign_out')), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
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
