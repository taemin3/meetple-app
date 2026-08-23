import '../../models/auth_session.dart';
import '../../models/auth_user.dart';
import '../../models/legal_document.dart';
import '../../models/password_reset_verification.dart';
import '../../models/signup_email_verification.dart';
import '../mock/mock_auth.dart';
import '../mock/mock_legal_documents.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({AuthSession? session = mockAuthSession})
      : _session = session;

  AuthSession? _session;

  @override
  Future<AuthSession?> restoreSession() async {
    return _session;
  }

  @override
  Future<AuthSession?> refreshSession() => restoreSession();

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
    _ensureNotBlank(password, '비밀번호를 입력해 주세요.');

    final session = AuthSession(
      user: mockAuthUser.copyWith(email: email),
      accessToken: mockAuthSession.accessToken,
      refreshToken: mockAuthSession.refreshToken,
    );
    _session = session;

    return session;
  }

  @override
  Future<List<LegalDocument>> getSignupLegalDocuments() async {
    return mockSignupLegalDocuments;
  }

  @override
  Future<void> sendSignupEmailVerificationCode({required String email}) async {
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
  }

  @override
  Future<SignupEmailVerification> confirmSignupEmailVerificationCode({
    required String email,
    required String code,
  }) async {
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      throw const AuthException('인증번호는 6자리 숫자로 입력해 주세요.');
    }
    return const SignupEmailVerification(
      token: 'mock-signup-verification-token',
      expiresIn: Duration(minutes: 15),
    );
  }

  @override
  Future<void> sendPasswordResetVerificationCode(
      {required String email}) async {
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
  }

  @override
  Future<PasswordResetVerification> confirmPasswordResetVerificationCode({
    required String email,
    required String code,
  }) async {
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      throw const AuthException('인증번호는 6자리 숫자로 입력해 주세요.');
    }
    return const PasswordResetVerification(
      token: 'mock-password-reset-token',
      expiresIn: Duration(minutes: 15),
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String passwordResetToken,
    required String newPassword,
  }) async {
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
    _ensureNotBlank(passwordResetToken, '이메일 인증을 완료해 주세요.');
    _ensureNotBlank(newPassword, '새 비밀번호를 입력해 주세요.');
    final passwordValidationMessage =
        newPasswordValidationMessage(newPassword);
    if (passwordValidationMessage != null) {
      throw AuthException(passwordValidationMessage);
    }
    _session = null;
  }

  @override
  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
    required String signupVerificationToken,
    required List<LegalDocument> legalDocuments,
  }) async {
    _ensureNotBlank(nickname, '닉네임을 입력해 주세요.');
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
    _ensureNotBlank(password, '비밀번호를 입력해 주세요.');
    _ensureNotBlank(signupVerificationToken, '이메일 인증을 완료해 주세요.');
    final passwordValidationMessage = newPasswordValidationMessage(password);
    if (passwordValidationMessage != null) {
      throw AuthException(passwordValidationMessage);
    }
    if (legalDocuments.length != LegalDocumentType.values.length) {
      throw const AuthException('최신 약관을 확인해 주세요.');
    }

    final session = AuthSession(
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
    _session = session;

    return session;
  }

  @override
  Future<AuthUser> updateProfile({
    required String nickname,
    required String introduction,
  }) async {
    final session = _session;
    if (session == null) {
      throw const AuthException('로그인이 필요합니다.');
    }

    final normalizedNickname = nickname.trim();
    if (normalizedNickname.length < 2 || normalizedNickname.length > 20) {
      throw const AuthException('닉네임은 2자 이상 20자 이하여야 합니다.');
    }

    final normalizedIntroduction = introduction.trim();
    if (normalizedIntroduction.length > 30) {
      throw const AuthException('한줄 소개는 30자 이하여야 합니다.');
    }

    final user = session.user.copyWith(
      nickname: normalizedNickname,
      handle: normalizedNickname,
      introduction: normalizedIntroduction,
    );
    synchronizeUser(user);
    return user;
  }

  @override
  void synchronizeUser(AuthUser user) {
    final session = _session;
    if (session == null) {
      return;
    }
    _session = AuthSession(
      user: user,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }

  void _ensureNotBlank(String value, String message) {
    if (value.trim().isEmpty) {
      throw AuthException(message);
    }
  }
}
