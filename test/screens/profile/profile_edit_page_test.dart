import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetple/data/mock/mock_auth.dart';
import 'package:meetple/data/repositories/image_upload_repository.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/models/auth_user.dart';
import 'package:meetple/screens/profile/profile_edit_page.dart';
import 'package:meetple/screens/profile/profile_page.dart';

void main() {
  testWidgets('updates image nickname and introduction from the profile page', (
    tester,
  ) async {
    final authRepository = _RecordingAuthRepository();
    final imageRepository = _RecordingImageUploadRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(
            authRepository: authRepository,
            imageUploadRepository: imageRepository,
            pickProfileImage: _pickPng,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile_image_edit_open')));
    await tester.pumpAndSettle();

    final nicknameField = tester.widget<TextField>(
      find.byKey(const Key('profile_edit_nickname')),
    );
    expect(nicknameField.controller?.text, mockAuthUser.nickname);

    await tester.enterText(
      find.byKey(const Key('profile_edit_nickname')),
      '산책친구',
    );
    await tester.enterText(
      find.byKey(const Key('profile_edit_introduction')),
      '주말 산책을 좋아해요',
    );
    await tester.tap(find.byKey(const Key('profile_edit_image_picker')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('profile_edit_selected_preview')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('profile_edit_complete')));
    await tester.pumpAndSettle();

    expect(authRepository.updateCount, 1);
    expect(authRepository.updatedNickname, '산책친구');
    expect(authRepository.updatedIntroduction, '주말 산책을 좋아해요');
    expect(imageRepository.uploadedImage?.name, 'profile.png');
    expect(find.text('산책친구'), findsOneWidget);
    expect(find.text('주말 산책을 좋아해요'), findsOneWidget);
    expect(find.byKey(const Key('profile_avatar_image')), findsOneWidget);
    expect(find.text('프로필을 수정했습니다.'), findsOneWidget);
  });

  testWidgets('rejects an invalid nickname before saving', (tester) async {
    final authRepository = _RecordingAuthRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileEditPage(
          user: mockAuthUser,
          authRepository: authRepository,
          imageUploadRepository: _RecordingImageUploadRepository(),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('profile_edit_nickname')),
      'a',
    );
    await tester.tap(find.byKey(const Key('profile_edit_complete')));
    await tester.pumpAndSettle();

    expect(find.text('닉네임은 2자 이상 20자 이하여야 합니다.'), findsOneWidget);
    expect(authRepository.updateCount, 0);
  });

  testWidgets('rejects an unsupported image before upload', (tester) async {
    final imageRepository = _RecordingImageUploadRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileEditPage(
          user: mockAuthUser,
          authRepository: _RecordingAuthRepository(),
          imageUploadRepository: imageRepository,
          pickProfileImage: () async => XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            name: 'avatar.gif',
            mimeType: 'image/gif',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('profile_edit_image_picker')));
    await tester.pumpAndSettle();

    expect(
      find.text('JPG, PNG, WEBP 이미지만 선택할 수 있습니다.'),
      findsOneWidget,
    );
    expect(imageRepository.uploadCount, 0);
  });
}

Future<XFile?> _pickPng() async {
  return XFile.fromData(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
      'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
    name: '',
    mimeType: 'image/png',
  );
}

class _RecordingAuthRepository extends MockAuthRepository {
  int updateCount = 0;
  String? updatedNickname;
  String? updatedIntroduction;

  @override
  Future<AuthUser> updateProfile({
    required String nickname,
    required String introduction,
  }) async {
    updateCount += 1;
    updatedNickname = nickname;
    updatedIntroduction = introduction;
    return super.updateProfile(
      nickname: nickname,
      introduction: introduction,
    );
  }
}

class _RecordingImageUploadRepository implements ImageUploadRepository {
  ImageUploadFile? uploadedImage;
  int uploadCount = 0;

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
    return const UploadedImage(
      objectKey: 'images/profile/1/new.png',
      fileUrl: 'https://cdn.example.com/profile/new.png',
    );
  }
}
