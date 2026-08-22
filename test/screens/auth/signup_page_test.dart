import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetple/data/mock/mock_legal_documents.dart';
import 'package:meetple/data/repositories/auth_repository.dart';
import 'package:meetple/data/repositories/image_upload_repository.dart';
import 'package:meetple/models/auth_session.dart';
import 'package:meetple/models/auth_user.dart';
import 'package:meetple/models/legal_document.dart';
import 'package:meetple/models/signup_email_verification.dart';
import 'package:meetple/screens/auth/signup_page.dart';

void main() {
  testWidgets('requires email verification and clears it when email changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final authRepository = _SignUpAuthRepository();

    await _openSignUp(
      tester,
      authRepository: authRepository,
      imageUploadRepository: _RecordingImageUploadRepository(),
      pickProfileImage: () async => null,
    );

    await tester.enterText(
      find.byKey(const Key('sign_up_email')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign_up_password')),
      'password1!',
    );
    await tester.enterText(
      find.byKey(const Key('sign_up_password_confirm')),
      'password1!',
    );
    await tester.tap(find.byKey(const Key('sign_up_age_confirmation')));
    await tester.tap(find.text('다음'));
    await tester.pump();
    expect(find.text('이메일 인증을 완료해 주세요.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign_up_send_verification_code')));
    await tester.pump();
    expect(authRepository.sendVerificationCodeCount, 1);
    expect(
      find.byKey(const Key('sign_up_email_verification_code')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('sign_up_email_verification_code')),
      '123456',
    );
    await tester.tap(
      find.byKey(const Key('sign_up_confirm_verification_code')),
    );
    await tester.pumpAndSettle();
    expect(authRepository.confirmVerificationCodeCount, 1);
    expect(find.text('이메일 인증이 완료됐어요.'), findsOneWidget);
    expect(find.text('이메일 인증을 완료해 주세요.'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('sign_up_email')),
      'changed@example.com',
    );
    await tester.pump();
    expect(
      find.byKey(const Key('sign_up_email_verification_code')),
      findsNothing,
    );
    expect(find.text('이메일 인증이 완료됐어요.'), findsNothing);
  });

  testWidgets('discards a send response when the email changes in flight', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sendCompleter = Completer<void>();
    final authRepository = _SignUpAuthRepository(
      sendVerificationCodeCompleter: sendCompleter,
    );

    await _openSignUp(
      tester,
      authRepository: authRepository,
      imageUploadRepository: _RecordingImageUploadRepository(),
      pickProfileImage: () async => null,
    );

    await tester.enterText(
      find.byKey(const Key('sign_up_email')),
      'first@example.com',
    );
    await tester.tap(find.byKey(const Key('sign_up_send_verification_code')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('sign_up_email')),
      'second@example.com',
    );

    sendCompleter.complete();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('sign_up_email_verification_code')),
      findsNothing,
    );
    expect(find.text('인증번호 받기'), findsOneWidget);
    final sendButton = tester.widget<TextButton>(
      find.byKey(const Key('sign_up_send_verification_code')),
    );
    expect(sendButton.onPressed, isNotNull);
  });

  testWidgets('discards a confirm response when the email changes in flight', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final confirmCompleter = Completer<SignupEmailVerification>();
    final authRepository = _SignUpAuthRepository(
      confirmVerificationCodeCompleter: confirmCompleter,
    );

    await _openSignUp(
      tester,
      authRepository: authRepository,
      imageUploadRepository: _RecordingImageUploadRepository(),
      pickProfileImage: () async => null,
    );

    await tester.enterText(
      find.byKey(const Key('sign_up_email')),
      'first@example.com',
    );
    await tester.tap(find.byKey(const Key('sign_up_send_verification_code')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('sign_up_email_verification_code')),
      '123456',
    );
    await tester.tap(
      find.byKey(const Key('sign_up_confirm_verification_code')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('sign_up_email')),
      'second@example.com',
    );

    confirmCompleter.complete(
      const SignupEmailVerification(
        token: 'stale-signup-verification-token',
        expiresIn: Duration(minutes: 15),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이메일 인증이 완료됐어요.'), findsNothing);
    expect(
      find.byKey(const Key('sign_up_email_verification_code')),
      findsNothing,
    );
    expect(find.text('인증번호 받기'), findsOneWidget);
  });

  testWidgets('refreshes the resend cooldown from its expiry on resume', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var now = DateTime(2026, 8, 23, 1);

    await _openSignUp(
      tester,
      authRepository: _SignUpAuthRepository(),
      imageUploadRepository: _RecordingImageUploadRepository(),
      pickProfileImage: () async => null,
      now: () => now,
    );

    await tester.enterText(
      find.byKey(const Key('sign_up_email')),
      'user@example.com',
    );
    await tester.tap(find.byKey(const Key('sign_up_send_verification_code')));
    await tester.pump();
    expect(find.text('60초'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    now = now.add(const Duration(seconds: 61));
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pump();

    expect(find.text('재전송'), findsOneWidget);
    final sendButton = tester.widget<TextButton>(
      find.byKey(const Key('sign_up_send_verification_code')),
    );
    expect(sendButton.onPressed, isNotNull);
  });

  testWidgets('shows legal content and requires only the age confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _openSignUp(
      tester,
      authRepository: _SignUpAuthRepository(),
      imageUploadRepository: _RecordingImageUploadRepository(),
      pickProfileImage: () async => null,
    );

    await tester.tap(find.byKey(const Key('sign_up_service_terms')));
    await tester.pumpAndSettle();
    expect(find.text('서비스 이용약관'), findsWidgets);
    expect(find.textContaining('기본 규칙'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    await _verifyEmail(tester);
    await tester.enterText(
      find.byKey(const Key('sign_up_password')),
      'password1!',
    );
    await tester.enterText(
      find.byKey(const Key('sign_up_password_confirm')),
      'password1!',
    );
    await tester.tap(find.text('다음'));
    await tester.pump();
    expect(find.text('만 14세 이상임을 확인해 주세요.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign_up_age_confirmation')));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('프로필 정보를 입력해주세요'), findsOneWidget);
  });

  testWidgets('removes region and uploads the selected profile image', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authRepository = _SignUpAuthRepository(
      profileImageUrl: 'https://cdn.example.com/profile/default.png',
    );
    final imageUploadRepository = _RecordingImageUploadRepository();
    AuthSession? completedSession;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  completedSession = await Navigator.of(context).push(
                    MaterialPageRoute<AuthSession>(
                      builder: (_) => SignUpPage(
                        authRepository: authRepository,
                        imageUploadRepository: imageUploadRepository,
                        pickProfileImage: () async => XFile.fromData(
                          base64Decode(
                            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
                            'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
                          ),
                          name: '',
                          mimeType: 'image/png',
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('회원가입 열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('회원가입 열기'));
    await tester.pumpAndSettle();
    await _advanceToProfileStep(tester);

    expect(find.text('거주 지역'), findsNothing);
    expect(find.textContaining('거주 지역을 선택'), findsNothing);
    expect(find.text('생년월일'), findsNothing);

    await tester.tap(find.byKey(const Key('sign_up_profile_photo_picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign_up_profile_photo_preview')), findsOne);

    await tester.enterText(
      find.byKey(const Key('sign_up_nickname')),
      '밋플러',
    );
    await tester.ensureVisible(find.text('가입 완료'));
    await tester.tap(find.text('가입 완료'));
    await tester.pumpAndSettle();

    expect(authRepository.signUpCount, 1);
    expect(authRepository.submittedLegalDocuments, hasLength(3));
    expect(
      authRepository.submittedSignupVerificationToken,
      'signup-verification-token',
    );
    expect(imageUploadRepository.uploadedImage?.name, 'profile.png');
    expect(imageUploadRepository.uploadedImage?.contentType, 'image/png');
    expect(
      completedSession?.user.profileImageUrl,
      'https://cdn.example.com/profile/avatar.png',
    );
  });

  testWidgets('disables signup while the profile image is being picked', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authRepository = _SignUpAuthRepository();
    final imageUploadRepository = _RecordingImageUploadRepository();
    final pickedImage = Completer<XFile?>();

    await _openSignUp(
      tester,
      authRepository: authRepository,
      imageUploadRepository: imageUploadRepository,
      pickProfileImage: () => pickedImage.future,
    );
    await _advanceToProfileStep(tester);
    await tester.enterText(
      find.byKey(const Key('sign_up_nickname')),
      '밋플러',
    );

    await tester.tap(find.byKey(const Key('sign_up_profile_photo_picker')));
    await tester.pump();

    final submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '가입 완료'),
    );
    expect(submitButton.onPressed, isNull);
    expect(authRepository.signUpCount, 0);

    pickedImage.complete(
      XFile.fromData(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
          'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
        name: 'avatar.png',
        mimeType: 'image/png',
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('returns the created session on system back after upload failure',
      (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authRepository = _SignUpAuthRepository();
    final imageUploadRepository = _RecordingImageUploadRepository(
      failUpload: true,
    );
    AuthSession? completedSession;

    await _openSignUp(
      tester,
      authRepository: authRepository,
      imageUploadRepository: imageUploadRepository,
      pickProfileImage: () async => XFile.fromData(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
          'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
        name: 'avatar.png',
        mimeType: 'image/png',
      ),
      onCompleted: (session) => completedSession = session,
    );
    await _advanceToProfileStep(tester);
    await tester.tap(find.byKey(const Key('sign_up_profile_photo_picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('sign_up_nickname')),
      '밋플러',
    );
    await tester.ensureVisible(find.text('가입 완료'));
    await tester.tap(find.text('가입 완료'));
    await tester.pumpAndSettle();

    expect(authRepository.signUpCount, 1);
    expect(imageUploadRepository.uploadCount, 1);
    expect(completedSession, isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(completedSession?.accessToken, 'access-token');
    expect(find.byType(SignUpPage), findsNothing);
  });
}

Future<void> _openSignUp(
  WidgetTester tester, {
  required AuthRepository authRepository,
  required ImageUploadRepository imageUploadRepository,
  required Future<XFile?> Function() pickProfileImage,
  ValueChanged<AuthSession?>? onCompleted,
  DateTime Function()? now,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                final session = await Navigator.of(context).push<AuthSession>(
                  MaterialPageRoute<AuthSession>(
                    builder: (_) => SignUpPage(
                      authRepository: authRepository,
                      imageUploadRepository: imageUploadRepository,
                      pickProfileImage: pickProfileImage,
                      now: now,
                    ),
                  ),
                );
                onCompleted?.call(session);
              },
              child: const Text('회원가입 열기'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('회원가입 열기'));
  await tester.pumpAndSettle();
}

Future<void> _advanceToProfileStep(WidgetTester tester) async {
  await _verifyEmail(tester);
  await tester.enterText(
    find.byKey(const Key('sign_up_password')),
    'password1!',
  );
  await tester.enterText(
    find.byKey(const Key('sign_up_password_confirm')),
    'password1!',
  );
  await tester.tap(find.byKey(const Key('sign_up_age_confirmation')));
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
}

Future<void> _verifyEmail(
  WidgetTester tester, {
  String email = 'user@example.com',
}) async {
  await tester.enterText(find.byKey(const Key('sign_up_email')), email);
  await tester.tap(find.byKey(const Key('sign_up_send_verification_code')));
  await tester.pump();
  await tester.enterText(
    find.byKey(const Key('sign_up_email_verification_code')),
    '123456',
  );
  await tester.tap(find.byKey(const Key('sign_up_confirm_verification_code')));
  await tester.pumpAndSettle();
}

class _SignUpAuthRepository implements AuthRepository {
  _SignUpAuthRepository({
    this.profileImageUrl,
    this.sendVerificationCodeCompleter,
    this.confirmVerificationCodeCompleter,
  });

  final String? profileImageUrl;
  final Completer<void>? sendVerificationCodeCompleter;
  final Completer<SignupEmailVerification>? confirmVerificationCodeCompleter;
  int signUpCount = 0;
  int sendVerificationCodeCount = 0;
  int confirmVerificationCodeCount = 0;
  List<LegalDocument>? submittedLegalDocuments;
  String? submittedSignupVerificationToken;
  AuthSession? _session;

  @override
  Future<AuthSession?> restoreSession() async => _session;

  @override
  Future<AuthSession?> refreshSession() async => _session;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendSignupEmailVerificationCode({required String email}) async {
    sendVerificationCodeCount += 1;
    await sendVerificationCodeCompleter?.future;
  }

  @override
  Future<SignupEmailVerification> confirmSignupEmailVerificationCode({
    required String email,
    required String code,
  }) async {
    confirmVerificationCodeCount += 1;
    final completer = confirmVerificationCodeCompleter;
    if (completer != null) {
      return completer.future;
    }
    return const SignupEmailVerification(
      token: 'signup-verification-token',
      expiresIn: Duration(minutes: 15),
    );
  }

  @override
  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
    required String signupVerificationToken,
    required List<LegalDocument> legalDocuments,
  }) async {
    signUpCount += 1;
    submittedLegalDocuments = legalDocuments;
    submittedSignupVerificationToken = signupVerificationToken;
    _session = AuthSession(
      user: AuthUser(
        id: 1,
        nickname: nickname.trim(),
        handle: nickname.trim(),
        email: email.trim(),
        profileImageUrl: profileImageUrl,
      ),
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    return _session!;
  }

  @override
  Future<List<LegalDocument>> getSignupLegalDocuments() async {
    return mockSignupLegalDocuments;
  }

  @override
  Future<AuthUser> updateProfile({
    required String nickname,
    required String introduction,
  }) {
    throw UnimplementedError();
  }

  @override
  void synchronizeUser(AuthUser user) {}

  @override
  Future<void> signOut() async {
    _session = null;
  }
}

class _RecordingImageUploadRepository implements ImageUploadRepository {
  _RecordingImageUploadRepository({this.failUpload = false});

  final bool failUpload;
  ImageUploadFile? uploadedImage;
  int uploadCount = 0;

  @override
  Future<void> deleteProfileImage() async {}

  @override
  Future<List<UploadedImage>> uploadMeetingImages(
    List<ImageUploadFile> images,
  ) async {
    return const [];
  }

  @override
  Future<UploadedImage> uploadProfileImage(ImageUploadFile image) async {
    uploadCount += 1;
    uploadedImage = image;
    if (failUpload) {
      throw const ImageUploadException('프로필 이미지 업로드에 실패했습니다.');
    }
    return const UploadedImage(
      objectKey: 'images/profile/1/avatar.png',
      fileUrl: 'https://cdn.example.com/profile/avatar.png',
    );
  }
}
