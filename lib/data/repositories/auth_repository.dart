import '../../models/auth_session.dart';
import '../../models/auth_user.dart';
import '../../models/legal_document.dart';
import '../../models/password_reset_verification.dart';
import '../../models/signup_email_verification.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession?> refreshSession();

  Future<AuthSession> signIn({
    required String email,
    required String password,
  });

  Future<List<LegalDocument>> getSignupLegalDocuments();

  Future<void> sendSignupEmailVerificationCode({required String email});

  Future<SignupEmailVerification> confirmSignupEmailVerificationCode({
    required String email,
    required String code,
  });

  Future<void> sendPasswordResetVerificationCode({required String email});

  Future<PasswordResetVerification> confirmPasswordResetVerificationCode({
    required String email,
    required String code,
  });

  Future<void> resetPassword({
    required String email,
    required String passwordResetToken,
    required String newPassword,
  });

  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
    required String signupVerificationToken,
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
