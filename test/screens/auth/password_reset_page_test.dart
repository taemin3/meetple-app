import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/models/password_reset_verification.dart';
import 'package:meetple/screens/auth/password_reset_page.dart';

void main() {
  testWidgets('completes email verification and password reset flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _RecordingPasswordResetRepository();
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open_password_reset'),
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => PasswordResetPage(
                      authRepository: repository,
                      initialEmail: 'user@example.com',
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_password_reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('password_reset_primary_button')));
    await tester.pump();

    expect(repository.sentEmail, 'user@example.com');
    expect(find.byKey(const Key('password_reset_code')), findsOneWidget);
    expect(
      find.text('인증번호는 발급 후 5분 동안 유효합니다.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('password_reset_code')),
        matching: find.byType(TextField),
      ),
      '123456',
    );
    await tester.tap(find.byKey(const Key('password_reset_primary_button')));
    await tester.pump();

    expect(repository.confirmedCode, '123456');
    expect(
        find.byKey(const Key('password_reset_new_password')), findsOneWidget);
    var passwordField = tester.widget<TextField>(
      find.byKey(const Key('password_reset_new_password')),
    );
    expect(passwordField.enableSuggestions, isFalse);
    expect(passwordField.autocorrect, isFalse);

    await tester.tap(find.byTooltip('비밀번호 보기').first);
    await tester.pump();
    passwordField = tester.widget<TextField>(
      find.byKey(const Key('password_reset_new_password')),
    );
    expect(passwordField.obscureText, isFalse);
    expect(passwordField.enableSuggestions, isFalse);
    expect(passwordField.autocorrect, isFalse);

    await tester.enterText(
      find.byKey(const Key('password_reset_new_password')),
      'new-password123',
    );
    await tester.enterText(
      find.byKey(const Key('password_reset_password_confirm')),
      'new-password123',
    );
    await tester.tap(find.byKey(const Key('password_reset_primary_button')));
    await tester.pumpAndSettle();

    expect(repository.resetEmail, 'user@example.com');
    expect(repository.resetToken, 'password-reset-token');
    expect(repository.newPassword, 'new-password123');
    expect(result, isTrue);
  });

  testWidgets('does not submit mismatched passwords', (tester) async {
    final repository = _RecordingPasswordResetRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PasswordResetPage(
          authRepository: repository,
          initialEmail: 'user@example.com',
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('password_reset_primary_button')));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('password_reset_code')),
        matching: find.byType(TextField),
      ),
      '123456',
    );
    await tester.tap(find.byKey(const Key('password_reset_primary_button')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('password_reset_new_password')),
      'new-password123',
    );
    await tester.enterText(
      find.byKey(const Key('password_reset_password_confirm')),
      'different-password',
    );
    await tester.tap(find.byKey(const Key('password_reset_primary_button')));
    await tester.pump();

    expect(find.text('비밀번호가 일치하지 않습니다.'), findsOneWidget);
    expect(repository.newPassword, isNull);
  });

  testWidgets('disables confirmation while a resend is pending', (
    tester,
  ) async {
    var now = DateTime(2026, 8, 23, 12);
    final resendGate = Completer<void>();
    final repository = _RecordingPasswordResetRepository(
      resendGate: resendGate,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PasswordResetPage(
          authRepository: repository,
          initialEmail: 'user@example.com',
          now: () => now,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('password_reset_primary_button')));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('password_reset_code')),
        matching: find.byType(TextField),
      ),
      '123456',
    );

    now = now.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('password_reset_resend_button')));
    await tester.pump();

    final primaryButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('password_reset_primary_button')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(primaryButton.onPressed, isNull);
    expect(repository.confirmedCode, isNull);

    resendGate.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _RecordingPasswordResetRepository extends MockAuthRepository {
  _RecordingPasswordResetRepository({this.resendGate}) : super(session: null);

  final Completer<void>? resendGate;
  int sendCount = 0;
  String? sentEmail;
  String? confirmedCode;
  String? resetEmail;
  String? resetToken;
  String? newPassword;

  @override
  Future<void> sendPasswordResetVerificationCode(
      {required String email}) async {
    sendCount += 1;
    if (sendCount > 1 && resendGate != null) {
      await resendGate!.future;
    }
    sentEmail = email;
  }

  @override
  Future<PasswordResetVerification> confirmPasswordResetVerificationCode({
    required String email,
    required String code,
  }) async {
    confirmedCode = code;
    return const PasswordResetVerification(
      token: 'password-reset-token',
      expiresIn: Duration(minutes: 15),
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String passwordResetToken,
    required String newPassword,
  }) async {
    resetEmail = email;
    resetToken = passwordResetToken;
    this.newPassword = newPassword;
  }
}
