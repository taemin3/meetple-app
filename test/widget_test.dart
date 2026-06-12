import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/meetple_app.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/widgets/primary_gradient_button.dart';

void main() {
  testWidgets('shows Meetple home', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pump();

    expect(
      find.textContaining('함께할 사람을', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('추천 모임', skipOffstage: false), findsOneWidget);
  });

  testWidgets('opens create meeting tab from home banner', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pump();

    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });

  testWidgets('shows authenticated profile from auth repository', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MeetpleApp());
    await tester.pump();

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    expect(find.text('김모임'), findsOneWidget);
    expect(find.text('@gather_together'), findsOneWidget);
    expect(find.text('내 정보'), findsOneWidget);
  });

  testWidgets('keeps signed-in profile after tab switch', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pump();

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인하기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(find.text('김모임'), findsOneWidget);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    expect(find.text('김모임'), findsOneWidget);
    expect(find.text('로그인이 필요합니다.'), findsNothing);
  });

  testWidgets('signs out from profile page', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(540, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authRepository = MockAuthRepository();
    await tester.pumpWidget(MeetpleApp(authRepository: authRepository));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_sign_out')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_sign_out')));
    await tester.pumpAndSettle();

    expect(await authRepository.restoreSession(), isNull);
    expect(find.byKey(const Key('profile_sign_out')), findsNothing);
    expect(find.byType(PrimaryGradientButton), findsOneWidget);
  });

  testWidgets('shows reference login form copy', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pump();

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인하기'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('밋플'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('우리, 가까운 모임으로 연결되는 순간'), findsOneWidget);
    expect(find.text('이메일을 입력해주세요'), findsOneWidget);
    expect(find.text('비밀번호를 입력해주세요'), findsOneWidget);
    expect(find.text('비밀번호 찾기'), findsOneWidget);
    expect(find.text('계정이 없으신가요?'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });

  testWidgets('moves sign up from account step to profile step', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MeetpleApp(authRepository: MockAuthRepository(session: null)),
    );
    await tester.pump();

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('계정 정보를 입력해주세요'), findsOneWidget);
    expect(find.text('약관 동의'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password1!');
    await tester.enterText(find.byType(TextField).at(2), 'password1!');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign_up_all_terms')));
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('프로필 정보를 입력해주세요'), findsOneWidget);
    expect(find.text('프로필 사진'), findsOneWidget);
    expect(find.text('닉네임'), findsOneWidget);
    expect(find.text('한줄 소개'), findsOneWidget);
    expect(find.text('가입 완료'), findsOneWidget);
  });
}
