import '../../models/auth_session.dart';
import '../mock/mock_auth.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository({this.session = mockAuthSession});

  final AuthSession? session;

  @override
  Future<AuthSession?> restoreSession() async {
    return session;
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
    _ensureNotBlank(password, '비밀번호를 입력해 주세요.');

    return AuthSession(
      user: mockAuthUser.copyWith(email: email),
      accessToken: mockAuthSession.accessToken,
      refreshToken: mockAuthSession.refreshToken,
    );
  }

  @override
  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    _ensureNotBlank(nickname, '닉네임을 입력해 주세요.');
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
    _ensureNotBlank(password, '비밀번호를 입력해 주세요.');

    return AuthSession(
      user: mockAuthUser.copyWith(
        nickname: nickname,
        handle: nickname,
        email: email,
        createdMeetingsCount: 0,
        joinedMeetingsCount: 0,
        likedMeetingsCount: 0,
      ),
      accessToken: mockAuthSession.accessToken,
      refreshToken: mockAuthSession.refreshToken,
    );
  }

  @override
  Future<void> signOut() async {}

  void _ensureNotBlank(String value, String message) {
    if (value.trim().isEmpty) {
      throw AuthException(message);
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
