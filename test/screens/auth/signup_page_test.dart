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
import 'package:meetple/screens/auth/signup_page.dart';

void main() {
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

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password1!');
    await tester.enterText(find.byType(TextField).at(2), 'password1!');
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
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password1!');
    await tester.enterText(find.byType(TextField).at(2), 'password1!');
    await tester.tap(find.byKey(const Key('sign_up_age_confirmation')));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('거주 지역'), findsNothing);
    expect(find.textContaining('거주 지역을 선택'), findsNothing);
    expect(find.text('생년월일'), findsNothing);

    await tester.tap(find.byKey(const Key('sign_up_profile_photo_picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign_up_profile_photo_preview')), findsOne);

    await tester.enterText(find.byType(TextField).at(0), '밋플러');
    await tester.ensureVisible(find.text('가입 완료'));
    await tester.tap(find.text('가입 완료'));
    await tester.pumpAndSettle();

    expect(authRepository.signUpCount, 1);
    expect(authRepository.submittedLegalDocuments, hasLength(3));
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
    await tester.enterText(find.byType(TextField).at(0), '밋플러');

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
    await tester.enterText(find.byType(TextField).at(0), '밋플러');
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
  await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
  await tester.enterText(find.byType(TextField).at(1), 'password1!');
  await tester.enterText(find.byType(TextField).at(2), 'password1!');
  await tester.tap(find.byKey(const Key('sign_up_age_confirmation')));
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
}

class _SignUpAuthRepository implements AuthRepository {
  _SignUpAuthRepository({this.profileImageUrl});

  final String? profileImageUrl;
  int signUpCount = 0;
  List<LegalDocument>? submittedLegalDocuments;
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
  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
    required List<LegalDocument> legalDocuments,
  }) async {
    signUpCount += 1;
    submittedLegalDocuments = legalDocuments;
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
