import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/image_upload_repository.dart';
import '../../models/auth_user.dart';
import '../../widgets/network_image_with_skeleton.dart';
import '../../widgets/centered_page_app_bar.dart';

typedef ProfileImagePicker = Future<XFile?> Function();

enum _ProfileImageAction { change, useDefault }

class ProfileEditResult {
  const ProfileEditResult({required this.user, required this.message});

  final AuthUser user;
  final String message;
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.user,
    required this.authRepository,
    required this.imageUploadRepository,
    this.pickProfileImage,
  });

  final AuthUser user;
  final AuthRepository authRepository;
  final ImageUploadRepository imageUploadRepository;
  final ProfileImagePicker? pickProfileImage;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _introductionController;
  ImageUploadFile? _selectedImage;
  bool _deleteProfileImage = false;
  bool _isPicking = false;
  bool _isSaving = false;

  bool get _isBusy => _isPicking || _isSaving;
  bool get _hasOriginalProfileImage =>
      widget.user.profileImageUrl?.trim().isNotEmpty == true;
  bool get _hasVisibleProfileImage =>
      _selectedImage != null ||
      (!_deleteProfileImage && _hasOriginalProfileImage);

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.user.nickname)
      ..addListener(_refreshCounter);
    _introductionController = TextEditingController(
      text: widget.user.introduction ?? '',
    )..addListener(_refreshCounter);
  }

  @override
  void dispose() {
    _nicknameController
      ..removeListener(_refreshCounter)
      ..dispose();
    _introductionController
      ..removeListener(_refreshCounter)
      ..dispose();
    super.dispose();
  }

  void _refreshCounter() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBusy,
      child: Scaffold(
        appBar: CenteredPageAppBar(
          title: '프로필 수정',
          backButtonKey: const Key('profile_edit_back'),
          backEnabled: !_isBusy,
          actions: [
            TextButton(
              key: const Key('profile_edit_complete'),
              onPressed: _isBusy ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '완료',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        backgroundColor: AppColors.surface,
        body: SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: _EditableProfileImage(
                      imageBytes: _selectedImage?.bytes,
                      imageUrl: _deleteProfileImage
                          ? null
                          : widget.user.profileImageUrl,
                      isPicking: _isPicking,
                      onTap: _isBusy ? null : _showImageActions,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _ProfileTextField(
                    fieldKey: const Key('profile_edit_nickname'),
                    label: '닉네임',
                    controller: _nicknameController,
                    maxLength: 20,
                    hintText: '닉네임을 입력해 주세요.',
                  ),
                  const SizedBox(height: 24),
                  _ProfileTextField(
                    fieldKey: const Key('profile_edit_introduction'),
                    label: '한줄 소개',
                    controller: _introductionController,
                    maxLength: 30,
                    hintText: '자신을 한줄로 소개해 주세요.',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showImageActions() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final action = await showModalBottomSheet<_ProfileImageAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('profile_edit_change_image'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('사진 변경'),
              onTap: () => Navigator.of(sheetContext).pop(
                _ProfileImageAction.change,
              ),
            ),
            if (_hasVisibleProfileImage)
              ListTile(
                key: const Key('profile_edit_use_default_image'),
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.error,
                ),
                title: const Text(
                  '기본 이미지로 변경',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.of(sheetContext).pop(
                  _ProfileImageAction.useDefault,
                ),
              ),
            ListTile(
              key: const Key('profile_edit_cancel_image_action'),
              leading: const Icon(Icons.close_rounded),
              title: const Text('취소'),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _ProfileImageAction.change:
        await _pickImage();
      case _ProfileImageAction.useDefault:
        setState(() {
          _selectedImage = null;
          _deleteProfileImage = _hasOriginalProfileImage;
        });
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isPicking = true);

    Object? pickError;
    ImageUploadFile? selectedImage;
    try {
      final file = widget.pickProfileImage == null
          ? await ImagePicker().pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
            )
          : await widget.pickProfileImage!();
      if (file != null) {
        final contentType = _resolveImageContentType(file.mimeType, file.name);
        if (contentType == null) {
          throw const ImageUploadException(
            'JPG, PNG, WEBP 이미지만 선택할 수 있습니다.',
          );
        }
        selectedImage = ImageUploadFile(
          name: file.name.trim().isEmpty
              ? _defaultFileName(contentType)
              : file.name,
          contentType: contentType,
          bytes: await file.readAsBytes(),
        );
      }
    } on Object catch (error) {
      pickError = error;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPicking = false;
      if (selectedImage != null) {
        _selectedImage = selectedImage;
        _deleteProfileImage = false;
      }
    });

    if (pickError != null) {
      _showMessage(
        pickError is ImageUploadException
            ? pickError.message
            : '프로필 사진을 불러오지 못했습니다.',
      );
    }
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    final introduction = _introductionController.text.trim();
    if (nickname.length < 2 || nickname.length > 20) {
      _showMessage('닉네임은 2자 이상 20자 이하여야 합니다.');
      return;
    }
    if (introduction.length > 30) {
      _showMessage('한줄 소개는 30자 이하여야 합니다.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSaving = true);

    late final AuthUser updatedUser;
    try {
      updatedUser = await widget.authRepository.updateProfile(
        nickname: nickname,
        introduction: introduction,
      );
    } on Exception catch (error) {
      _handleSaveFailure(error);
      return;
    }

    try {
      var profileImageUrl = widget.user.profileImageUrl;
      final selectedImage = _selectedImage;
      if (selectedImage != null) {
        final uploadedImage = await widget.imageUploadRepository
            .uploadProfileImage(selectedImage);
        profileImageUrl = uploadedImage.fileUrl;
      } else if (_deleteProfileImage) {
        await widget.imageUploadRepository.deleteProfileImage();
        profileImageUrl = null;
      }

      await _completeProfileEdit(
        updatedUser.copyWith(
          profileImageUrl: profileImageUrl,
          clearProfileImageUrl: _deleteProfileImage,
        ),
        '프로필을 수정했습니다.',
      );
    } on Exception {
      await _completeProfileEdit(
        updatedUser,
        '프로필 정보는 저장했지만 사진을 변경하지 못했습니다.',
      );
    }
  }

  Future<void> _completeProfileEdit(AuthUser user, String message) async {
    if (!mounted) {
      return;
    }
    widget.authRepository.synchronizeUser(user);
    setState(() => _isSaving = false);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(
      ProfileEditResult(user: user, message: message),
    );
  }

  void _handleSaveFailure(Exception error) {
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    final message = switch (error) {
      ImageUploadException(:final message) => message,
      AuthException(:final message) => message,
      _ => '프로필을 저장하지 못했습니다.',
    };
    _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _resolveImageContentType(String? mimeType, String fileName) {
    final normalizedMimeType = mimeType?.trim().toLowerCase();
    if (normalizedMimeType != null && normalizedMimeType.isNotEmpty) {
      return switch (normalizedMimeType) {
        'image/jpeg' || 'image/png' || 'image/webp' => normalizedMimeType,
        _ => null,
      };
    }

    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  String _defaultFileName(String contentType) {
    return switch (contentType) {
      'image/jpeg' => 'profile.jpg',
      'image/webp' => 'profile.webp',
      _ => 'profile.png',
    };
  }
}

class _EditableProfileImage extends StatelessWidget {
  const _EditableProfileImage({
    this.imageBytes,
    this.imageUrl,
    required this.isPicking,
    required this.onTap,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool isPicking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fallback = _fallback();
    final currentImageUrl = imageUrl?.trim();

    return SizedBox.square(
      dimension: 136,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.softSurface,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes!,
                      key: const Key('profile_edit_selected_preview'),
                      fit: BoxFit.cover,
                      cacheWidth: 272,
                      cacheHeight: 272,
                    )
                  : currentImageUrl != null && currentImageUrl.isNotEmpty
                      ? NetworkImageWithSkeleton(
                          imageKey: const Key('profile_edit_current_preview'),
                          imageUrl: currentImageUrl,
                          width: 136,
                          height: 136,
                          fit: BoxFit.cover,
                          cacheWidth: 272,
                          cacheHeight: 272,
                          skeleton: fallback,
                          errorWidget: fallback,
                        )
                      : fallback,
            ),
          ),
          Positioned(
            right: 2,
            bottom: 5,
            child: IconButton.filled(
              key: const Key('profile_edit_image_picker'),
              tooltip: '프로필 사진 선택',
              onPressed: onTap,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.muted,
                foregroundColor: Colors.white,
                minimumSize: const Size.square(38),
                fixedSize: const Size.square(38),
                padding: EdgeInsets.zero,
                side: const BorderSide(color: Colors.white, width: 3),
              ),
              icon: isPicking
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.photo_camera_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return const Center(
      child: Icon(Icons.person, color: AppColors.primary, size: 64),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.maxLength,
    required this.hintText,
    this.maxLines = 1,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final int maxLength;
  final String hintText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${controller.text.length}/$maxLength',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          key: fieldKey,
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: 1,
          textInputAction:
              maxLines == 1 ? TextInputAction.next : TextInputAction.done,
          decoration: InputDecoration(
            hintText: hintText,
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
