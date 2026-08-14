import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetple/data/repositories/auth_repository.dart';
import 'package:meetple/data/repositories/image_upload_repository.dart';
import 'package:meetple/models/auth_session.dart';
import 'package:meetple/models/auth_user.dart';
import 'package:meetple/screens/auth/signup_page.dart';

void main() {
  testWidgets('removes region and uploads the selected profile image', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authRepository = _SignUpAuthRepository();
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
                          name: 'avatar.png',
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
    await tester.tap(find.byKey(const Key('sign_up_all_terms')));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('거주 지역'), findsNothing);
    expect(find.textContaining('거주 지역을 선택'), findsNothing);

    await tester.tap(find.byKey(const Key('sign_up_profile_photo_picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign_up_profile_photo_preview')), findsOne);

    await tester.enterText(find.byType(TextField).at(0), '밋플러');
    await tester.ensureVisible(find.text('가입 완료'));
    await tester.tap(find.text('가입 완료'));
    await tester.pumpAndSettle();

    expect(authRepository.signUpCount, 1);
    expect(imageUploadRepository.uploadedImage?.name, 'profile.png');
    expect(imageUploadRepository.uploadedImage?.contentType, 'image/png');
    expect(
      completedSession?.user.profileImageUrl,
      'https://cdn.example.com/profile/avatar.png',
    );
  });
}

class _SignUpAuthRepository implements AuthRepository {
  int signUpCount = 0;
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
  }) async {
    signUpCount += 1;
    _session = AuthSession(
      user: AuthUser(
        id: 1,
        nickname: nickname.trim(),
        handle: nickname.trim(),
        email: email.trim(),
      ),
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    return _session!;
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }
}

class _RecordingImageUploadRepository implements ImageUploadRepository {
  ImageUploadFile? uploadedImage;

  @override
  Future<List<String>> uploadMeetingImages(List<ImageUploadFile> images) async {
    return const [];
  }

  @override
  Future<String> uploadProfileImage(ImageUploadFile image) async {
    uploadedImage = image;
    return 'https://cdn.example.com/profile/avatar.png';
  }
}
