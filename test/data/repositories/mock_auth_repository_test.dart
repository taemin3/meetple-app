import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/mock/mock_auth.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';

void main() {
  test('restores mock session by default', () async {
    const repository = MockAuthRepository();

    final session = await repository.restoreSession();

    expect(session, mockAuthSession);
    expect(session?.user.nickname, '김모임');
  });

  test('can represent signed-out state', () async {
    const repository = MockAuthRepository(session: null);

    final session = await repository.restoreSession();

    expect(session, isNull);
  });

  test('signs in with mock session and requested email', () async {
    const repository = MockAuthRepository();

    final session = await repository.signIn(
      email: 'user@example.com',
      password: 'password',
    );

    expect(session.user.email, 'user@example.com');
    expect(session.accessToken, isNotEmpty);
    expect(session.hasRefreshToken, isTrue);
  });

  test('signs up with requested nickname and email', () async {
    const repository = MockAuthRepository();

    final session = await repository.signUp(
      nickname: '밋플러',
      email: 'new@example.com',
      password: 'password',
    );

    expect(session.user.nickname, '밋플러');
    expect(session.user.handle, '밋플러');
    expect(session.user.email, 'new@example.com');
    expect(session.user.createdMeetingsCount, 0);
  });

  test('throws auth exception for blank sign in fields', () {
    const repository = MockAuthRepository();

    expect(
      repository.signIn(email: '', password: 'password'),
      throwsA(isA<AuthException>()),
    );
  });
}
