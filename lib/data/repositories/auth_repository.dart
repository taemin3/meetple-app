import '../../models/auth_session.dart';
import '../../models/auth_user.dart';
import '../../models/legal_document.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession?> refreshSession();

  Future<AuthSession> signIn({
    required String email,
    required String password,
  });

  Future<List<LegalDocument>> getSignupLegalDocuments();

  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
    required List<LegalDocument> legalDocuments,
  });

  Future<AuthUser> updateProfile({
    required String nickname,
    required String introduction,
  });

  void synchronizeUser(AuthUser user);

  Future<void> signOut();
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
