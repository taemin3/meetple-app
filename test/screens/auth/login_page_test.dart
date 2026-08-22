import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/mock/mock_auth.dart';
import 'package:meetple/data/mock/mock_legal_documents.dart';
import 'package:meetple/data/repositories/auth_repository.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/models/auth_session.dart';
import 'package:meetple/models/auth_user.dart';
import 'package:meetple/models/legal_document.dart';
import 'package:meetple/models/password_reset_verification.dart';
import 'package:meetple/models/signup_email_verification.dart';
import 'package:meetple/screens/auth/login_page.dart';
import 'package:meetple/screens/auth/password_reset_page.dart';
import 'package:meetple/widgets/primary_button.dart';

void main() {
  testWidgets('shows a loader instead of changing the login label', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _DeferredSignInRepository();
    AuthSession? authenticatedSession;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          authRepository: repository,
          onAuthenticated: (session) => authenticatedSession = session,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.widgetWithText(PrimaryButton, '로그인'));
    await tester.pump();

    final buttonFinder = find.byType(PrimaryButton);
    final button = tester.widget<PrimaryButton>(buttonFinder);
    expect(button.label, '로그인');
    expect(button.loading, isTrue);
    expect(
      find.descendant(
        of: buttonFinder,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: buttonFinder, matching: find.text('로그인 중...')),
      findsNothing,
    );

    repository.completeSignIn();
    await tester.pumpAndSettle();
    expect(authenticatedSession, mockAuthSession);
  });

  testWidgets('opens password reset with the entered email', (tester) async {
    final repository = MockAuthRepository(session: null);

    await tester.pumpWidget(
      MaterialApp(home: LoginPage(authRepository: repository)),
    );

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.tap(find.byKey(const Key('login_password_reset_button')));
    await tester.pumpAndSettle();

    expect(find.byType(PasswordResetPage), findsOneWidget);
    final emailField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('password_reset_email')),
        matching: find.byType(TextField),
      ),
    );
    expect(emailField.controller?.text, 'user@example.com');
  });
}

class _DeferredSignInRepository implements AuthRepository {
  final Completer<AuthSession> _signInCompleter = Completer<AuthSession>();

  void completeSignIn() => _signInCompleter.complete(mockAuthSession);

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession?> refreshSession() async => null;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) =>
      _signInCompleter.future;

  @override
  Future<void> sendSignupEmailVerificationCode({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<SignupEmailVerification> confirmSignupEmailVerificationCode({
    required String email,
    required String code,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetVerificationCode({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<PasswordResetVerification> confirmPasswordResetVerificationCode({
    required String email,
    required String code,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String passwordResetToken,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
    required String signupVerificationToken,
    required List<LegalDocument> legalDocuments,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<LegalDocument>> getSignupLegalDocuments() async {
    return mockSignupLegalDocuments;
  }

  @override
  Future<AuthUser> updateProfile({
    required String nickname,
    required String introduction,
  }) {
    throw UnimplementedError();
  }

  @override
  void synchronizeUser(AuthUser user) {}

  @override
  Future<void> signOut() async {}
}
