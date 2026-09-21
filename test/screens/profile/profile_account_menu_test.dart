import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/mock/mock_auth.dart';
import 'package:meetple/data/mock/mock_legal_documents.dart';
import 'package:meetple/data/repositories/auth_repository.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/models/auth_session.dart';
import 'package:meetple/screens/auth/password_reset_page.dart';
import 'package:meetple/screens/profile/legal_documents_page.dart';
import 'package:meetple/screens/profile/profile_page.dart';

void main() {
  testWidgets('opens profile edit and password reset actions from the gear', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(authRepository: MockAuthRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('최근 본 모임'), findsNothing);
    expect(find.text('고객센터'), findsNothing);

    await tester.tap(find.byKey(const Key('profile_account_menu_open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_account_edit')), findsOneWidget);
    expect(
      find.byKey(const Key('profile_account_reset_password')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('profile_account_delete')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('profile_account_reset_password')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PasswordResetPage), findsOneWidget);
    final emailField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('password_reset_email')),
        matching: find.byType(TextField),
      ),
    );
    expect(emailField.controller?.text, mockAuthUser.email);
    expect(emailField.readOnly, isTrue);
  });

  testWidgets('shows current service terms and privacy policy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(authRepository: MockAuthRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final legalDocumentsButton =
        find.byKey(const Key('profile_legal_documents_open'));
    await tester.ensureVisible(legalDocumentsButton);
    await tester.tap(legalDocumentsButton);
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentsPage), findsOneWidget);
    expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    expect(find.byKey(const Key('legal_documents_back')), findsOneWidget);
    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(find.text('개인정보 처리방침'), findsOneWidget);
    expect(find.text('만 14세 이상 확인'), findsNothing);

    await tester.tap(
      find.byKey(const Key('legal_document_SERVICE_TERMS')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentDetailPage), findsOneWidget);
    expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
    expect(
      find.byKey(const Key('legal_document_detail_back')),
      findsOneWidget,
    );
    expect(
      find.text(mockSignupLegalDocuments.first.content),
      findsOneWidget,
    );
    expect(find.byKey(const Key('legal_document_content')), findsOneWidget);
  });

  testWidgets('signs out after resetting the password from the profile', (
    tester,
  ) async {
    var signedOutCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(
            authRepository: MockAuthRepository(),
            onSignedOut: () => signedOutCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile_account_menu_open')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('profile_account_reset_password')),
    );
    await tester.pumpAndSettle();

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
      'new-password123',
    );
    await tester.tap(find.byKey(const Key('password_reset_primary_button')));
    await tester.pumpAndSettle();

    expect(signedOutCount, 1);
    expect(find.text('로그인이 필요합니다.'), findsOneWidget);
    expect(find.text('비밀번호가 변경되어 다시 로그인해 주세요.'), findsOneWidget);
  });

  testWidgets('signs out from the auth root when deletion session expires', (
    tester,
  ) async {
    var signedOutCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(
            authRepository: _SessionExpiredDeletionRepository(),
            onSignedOut: () => signedOutCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile_account_menu_open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_account_delete')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('account_deletion_password')),
      'password123',
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('account_deletion_confirm')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const Key('account_deletion_submit')));
    await tester.tap(find.byKey(const Key('account_deletion_submit')));
    await tester.pumpAndSettle();

    expect(signedOutCount, 1);
    expect(find.text('로그인이 필요합니다.'), findsOneWidget);
  });

  testWidgets('keeps profile visible while refreshing on tab return', (
    tester,
  ) async {
    final repository = _DeferredRefreshAuthRepository();

    Widget profile({required bool isActive}) => MaterialApp(
          home: Scaffold(
            body: ProfilePage(
              authRepository: repository,
              isActive: isActive,
            ),
          ),
        );

    await tester.pumpWidget(profile(isActive: true));
    await tester.pumpAndSettle();
    expect(find.text(mockAuthSession.user.nickname), findsOneWidget);

    await tester.pumpWidget(profile(isActive: false));
    await tester.pump();
    repository.pendingRefresh = Completer<AuthSession?>();
    await tester.pumpWidget(profile(isActive: true));
    await tester.pump();

    expect(find.text('내 정보를 불러오는 중입니다.'), findsNothing);
    expect(find.text(mockAuthSession.user.nickname), findsOneWidget);

    repository.pendingRefresh!.complete(mockAuthSession);
    await tester.pumpAndSettle();
  });
}

class _DeferredRefreshAuthRepository extends MockAuthRepository {
  int refreshCount = 0;
  Completer<AuthSession?>? pendingRefresh;

  @override
  Future<AuthSession?> refreshSession() {
    refreshCount++;
    if (refreshCount > 1) return pendingRefresh!.future;
    return super.refreshSession();
  }
}

class _SessionExpiredDeletionRepository extends MockAuthRepository {
  @override
  Future<void> deleteAccount({required String currentPassword}) {
    throw const AccountDeletionException(
      '세션이 만료되었습니다. 다시 로그인해 주세요.',
      AccountDeletionFailure.sessionExpired,
    );
  }
}
