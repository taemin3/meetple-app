import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/screens/profile/account_deletion_page.dart';

void main() {
  testWidgets('shows deletion scope and requires password plus confirmation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountDeletionPage(authRepository: MockAuthRepository()),
      ),
    );

    expect(find.text('탈퇴는 되돌릴 수 없습니다.'), findsOneWidget);
    expect(find.text('삭제되는 개인정보'), findsOneWidget);
    expect(find.text('유지될 수 있는 기록'), findsOneWidget);
    expect(find.text('진행 중인 모임'), findsOneWidget);

    final submit = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('account_deletion_submit')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(submit.onPressed, isNull);
  });

  testWidgets('distinguishes an incorrect current password', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountDeletionPage(authRepository: MockAuthRepository()),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('account_deletion_password')),
      'wrong-password',
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('account_deletion_confirm')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('account_deletion_submit')));
    await tester.tap(find.byKey(const Key('account_deletion_submit')));
    await tester.pumpAndSettle();

    expect(find.text('현재 비밀번호가 올바르지 않습니다.'), findsOneWidget);
  });

  testWidgets('blocks duplicate submission and returns success once',
      (tester) async {
    final repository = _DeferredDeletionRepository();
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AccountDeletionPage(
                      authRepository: repository,
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
    await tester.tap(find.text('open'));
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
    await tester.ensureVisible(find.byKey(const Key('account_deletion_submit')));
    await tester.tap(find.byKey(const Key('account_deletion_submit')));
    await tester.tap(find.byKey(const Key('account_deletion_submit')));
    await tester.pump();

    expect(repository.callCount, 1);
    expect(find.text('탈퇴 처리 중...'), findsOneWidget);

    repository.complete();
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(AccountDeletionPage), findsNothing);
  });
}

class _DeferredDeletionRepository extends MockAuthRepository {
  final Completer<void> _completer = Completer<void>();
  int callCount = 0;

  @override
  Future<void> deleteAccount({required String currentPassword}) {
    callCount += 1;
    return _completer.future;
  }

  void complete() => _completer.complete();
}
