import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetple/data/repositories/image_upload_repository.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/screens/profile/profile_image_edit_page.dart';
import 'package:meetple/screens/profile/profile_page.dart';

void main() {
  testWidgets('selects and uploads a new profile image', (tester) async {
    final repository = _RecordingImageUploadRepository();
    String? updatedImageUrl;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              key: const Key('open_profile_image_edit'),
              onPressed: () async {
                updatedImageUrl = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => ProfileImageEditPage(
                      currentImageUrl: null,
                      imageUploadRepository: repository,
                      pickProfileImage: _pickPng,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open_profile_image_edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_image_picker')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('profile_image_selected_preview')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('profile_image_save')));
    await tester.pumpAndSettle();

    expect(repository.uploadedImage?.name, 'profile.png');
    expect(repository.uploadedImage?.contentType, 'image/png');
    expect(updatedImageUrl, 'https://cdn.example.com/profile/new.png');
  });

  testWidgets('updates the profile header immediately after saving', (
    tester,
  ) async {
    final repository = _RecordingImageUploadRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(
            authRepository: MockAuthRepository(),
            imageUploadRepository: repository,
            pickProfileImage: _pickPng,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile_image_edit_open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_image_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_image_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_avatar_image')), findsOneWidget);
    expect(find.text('프로필 사진을 변경했습니다.'), findsOneWidget);
  });

  testWidgets('rejects an unsupported image before upload', (tester) async {
    final repository = _RecordingImageUploadRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileImageEditPage(
          currentImageUrl: null,
          imageUploadRepository: repository,
          pickProfileImage: () async => XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            name: 'avatar.gif',
            mimeType: 'image/gif',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('profile_image_picker')));
    await tester.pumpAndSettle();

    expect(
      find.text('JPG, PNG, WEBP 이미지만 선택할 수 있습니다.'),
      findsOneWidget,
    );
    expect(repository.uploadCount, 0);
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
