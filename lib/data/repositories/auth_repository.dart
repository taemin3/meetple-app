import '../../models/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> signIn({
    required String email,
    required String password,
  });

  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
