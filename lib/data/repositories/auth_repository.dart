import 'dart:convert';

import '../../models/auth_session.dart';
import '../../models/auth_user.dart';
import '../../models/legal_document.dart';
import '../../models/password_reset_verification.dart';
import '../../models/signup_email_verification.dart';

const passwordLengthErrorMessage = '비밀번호는 8자 이상 64자 이하여야 합니다.';
const passwordByteLengthErrorMessage = '비밀번호는 UTF-8 기준 72바이트 이하여야 합니다.';
const passwordCompositionErrorMessage = '비밀번호는 영문과 숫자를 포함해야 합니다.';

String? newPasswordValidationMessage(String password) {
  if (password.length < 8 || password.length > 64) {
    return passwordLengthErrorMessage;
  }
  if (utf8.encode(password).length > 72) {
    return passwordByteLengthErrorMessage;
  }
  if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
      !RegExp(r'\d').hasMatch(password)) {
    return passwordCompositionErrorMessage;
  }
  return null;
}

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
