import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetple/data/mock/mock_auth.dart';
import 'package:meetple/data/repositories/image_upload_repository.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/models/auth_session.dart';
import 'package:meetple/models/auth_user.dart';
import 'package:meetple/screens/profile/profile_edit_page.dart';
import 'package:meetple/screens/profile/profile_page.dart';

void main() {
  testWidgets('shows introduction instead of handle in the profile header', (
    tester,
  ) async {
    const introduction = '주말 산책을 좋아해요';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileHeader(
            user: mockAuthUser.copyWith(introduction: introduction),
            onOpenAccountMenu: () {},
          ),
        ),
      ),
    );

    expect(find.text(introduction), findsOneWidget);
    expect(find.text('@${mockAuthUser.handle}'), findsNothing);
  });

  testWidgets('updates image nickname and introduction from the profile page', (
    tester,
  ) async {
    final saveEvents = <String>[];
    final authRepository = _RecordingAuthRepository(saveEvents: saveEvents);
    final imageRepository = _RecordingImageUploadRepository(
      saveEvents: saveEvents,
    );

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

    await _openProfileEdit(tester);

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
    await tester.tap(find.byKey(const Key('profile_edit_change_image')));
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
    expect(saveEvents, ['profile', 'image']);
    expect(find.text('산책친구'), findsOneWidget);
    expect(find.text('주말 산책을 좋아해요'), findsOneWidget);
    expect(find.byKey(const Key('profile_avatar_image')), findsOneWidget);
    expect(find.text('프로필을 수정했습니다.'), findsOneWidget);
    expect(
      (await authRepository.refreshSession())?.user.profileImageUrl,
      'https://cdn.example.com/profile/new.png',
    );
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

  testWidgets('rejects a known unsupported MIME despite a valid extension', (
    tester,
  ) async {
    final imageRepository = _RecordingImageUploadRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileEditPage(
          user: mockAuthUser,
          authRepository: _RecordingAuthRepository(),
          imageUploadRepository: imageRepository,
          pickProfileImage: () async => XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            name: 'avatar.jpg',
            mimeType: 'image/gif',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('profile_edit_image_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_edit_change_image')));
    await tester.pumpAndSettle();

    expect(
      find.text('JPG, PNG, WEBP 이미지만 선택할 수 있습니다.'),
      findsOneWidget,
    );
    expect(imageRepository.uploadCount, 0);
  });

  testWidgets('changes an existing profile image to the default image', (
    tester,
  ) async {
    final imageRepository = _RecordingImageUploadRepository();
    final user = mockAuthUser.copyWith(
      profileImageUrl: 'https://cdn.example.com/profile/current.png',
    );
    final authRepository = _RecordingAuthRepository.withSession(
      AuthSession(
        user: user,
        accessToken: mockAuthSession.accessToken,
        refreshToken: mockAuthSession.refreshToken,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(
            authRepository: authRepository,
            imageUploadRepository: imageRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_avatar_image')), findsOneWidget);

    await _openProfileEdit(tester);

    expect(
      find.byKey(const Key('profile_edit_current_preview')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('profile_edit_image_picker')));
    await tester.pumpAndSettle();

    expect(find.text('사진 변경'), findsOneWidget);
    expect(find.text('기본 이미지로 변경'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile_edit_use_default_image')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('profile_edit_current_preview')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('profile_edit_complete')));
    await tester.pumpAndSettle();

    expect(imageRepository.deleteCount, 1);
    expect(imageRepository.uploadCount, 0);
    expect(find.byKey(const Key('profile_avatar_image')), findsNothing);
    expect(find.text('프로필을 수정했습니다.'), findsOneWidget);
    expect(
      (await authRepository.refreshSession())?.user.profileImageUrl,
      isNull,
    );
  });

  testWidgets('keeps saved text when the image update fails', (tester) async {
    final authRepository = _RecordingAuthRepository();
    final imageRepository = _RecordingImageUploadRepository(failUpload: true);

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

    await _openProfileEdit(tester);
    await tester.enterText(
      find.byKey(const Key('profile_edit_nickname')),
      '정보저장완료',
    );
    await tester.tap(find.byKey(const Key('profile_edit_image_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_edit_change_image')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_edit_complete')));
    await tester.pumpAndSettle();

    expect(find.text('정보저장완료'), findsOneWidget);
    expect(
      find.text('프로필 정보는 저장했지만 사진을 변경하지 못했습니다.'),
      findsOneWidget,
    );
    expect(
      (await authRepository.refreshSession())?.user.nickname,
      '정보저장완료',
    );
  });

  testWidgets('blocks the system back action while saving', (tester) async {
    final authRepository = _DeferredProfileAuthRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              key: const Key('open_profile_edit'),
              onPressed: () => Navigator.of(context).push<ProfileEditResult>(
                MaterialPageRoute(
                  builder: (_) => ProfileEditPage(
                    user: mockAuthUser,
                    authRepository: authRepository,
                    imageUploadRepository: _RecordingImageUploadRepository(),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_profile_edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_edit_complete')));
    await tester.pump();

    expect(authRepository.updateStarted.isCompleted, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('프로필 수정'), findsOneWidget);

    authRepository.allowUpdate.complete();
    await tester.pumpAndSettle();
    expect(find.text('프로필 수정'), findsNothing);
  });
}

Future<void> _openProfileEdit(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('profile_account_menu_open')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('profile_account_edit')));
  await tester.pumpAndSettle();
  expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, isTrue);
  expect(find.byKey(const Key('profile_edit_back')), findsOneWidget);
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
  _RecordingAuthRepository({this.saveEvents}) : super();

  _RecordingAuthRepository.withSession(AuthSession session)
      : saveEvents = null,
        super(session: session);

  int updateCount = 0;
  String? updatedNickname;
  String? updatedIntroduction;
  final List<String>? saveEvents;

  @override
  Future<AuthUser> updateProfile({
    required String nickname,
    required String introduction,
  }) async {
    updateCount += 1;
    updatedNickname = nickname;
    updatedIntroduction = introduction;
    saveEvents?.add('profile');
    return super.updateProfile(
      nickname: nickname,
      introduction: introduction,
    );
  }
}

class _DeferredProfileAuthRepository extends MockAuthRepository {
  final updateStarted = Completer<void>();
  final allowUpdate = Completer<void>();

  @override
  Future<AuthUser> updateProfile({
    required String nickname,
    required String introduction,
  }) async {
    updateStarted.complete();
    await allowUpdate.future;
    return super.updateProfile(
      nickname: nickname,
      introduction: introduction,
    );
  }
}

class _RecordingImageUploadRepository implements ImageUploadRepository {
  _RecordingImageUploadRepository({
    this.failUpload = false,
    this.saveEvents,
  });

  ImageUploadFile? uploadedImage;
  int uploadCount = 0;
  int deleteCount = 0;
  final bool failUpload;
  final List<String>? saveEvents;

  @override
  Future<void> deleteProfileImage() async {
    deleteCount += 1;
  }

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
    saveEvents?.add('image');
    if (failUpload) {
      throw const ImageUploadException('프로필 이미지 업로드에 실패했습니다.');
    }
    return const UploadedImage(
      objectKey: 'images/profile/1/new.png',
      fileUrl: 'https://cdn.example.com/profile/new.png',
    );
  }
}
