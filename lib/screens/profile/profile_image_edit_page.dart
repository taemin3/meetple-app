import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/image_upload_repository.dart';
import '../../widgets/network_image_with_skeleton.dart';
import '../../widgets/primary_button.dart';

typedef ProfileImagePicker = Future<XFile?> Function();

class ProfileImageEditPage extends StatefulWidget {
  const ProfileImageEditPage({
    super.key,
    required this.currentImageUrl,
    required this.imageUploadRepository,
    this.pickProfileImage,
  });

  final String? currentImageUrl;
  final ImageUploadRepository imageUploadRepository;
  final ProfileImagePicker? pickProfileImage;

  @override
  State<ProfileImageEditPage> createState() => _ProfileImageEditPageState();
}

class _ProfileImageEditPageState extends State<ProfileImageEditPage> {
  ImageUploadFile? _selectedImage;
  bool _isPicking = false;
  bool _isSaving = false;

  bool get _isBusy => _isPicking || _isSaving;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 사진 수정')),
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Column(
            children: [
              _ProfileImagePreview(
                imageBytes: _selectedImage?.bytes,
                imageUrl: widget.currentImageUrl,
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                key: const Key('profile_image_picker'),
                onPressed: _isBusy ? null : _pickImage,
                icon: _isPicking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined),
                label: Text(_selectedImage == null ? '사진 선택' : '다른 사진 선택'),
              ),
              const SizedBox(height: 12),
              const Text(
                'JPG, PNG, WEBP 형식의 이미지를 선택해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                key: const Key('profile_image_save'),
                label: '저장',
                loading: _isSaving,
                onPressed:
                    _selectedImage == null || _isBusy ? null : _saveImage,
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _saveImage() async {
    final selectedImage = _selectedImage;
    if (selectedImage == null || _isBusy) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uploadedImage =
          await widget.imageUploadRepository.uploadProfileImage(selectedImage);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(uploadedImage.fileUrl);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showMessage(
        error is ImageUploadException ? error.message : '프로필 사진을 저장하지 못했습니다.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _resolveImageContentType(String? mimeType, String fileName) {
    final normalizedMimeType = mimeType?.toLowerCase();
    if (normalizedMimeType == 'image/jpeg' ||
        normalizedMimeType == 'image/png' ||
        normalizedMimeType == 'image/webp') {
      return normalizedMimeType;
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

class _ProfileImagePreview extends StatelessWidget {
  const _ProfileImagePreview({this.imageBytes, this.imageUrl});

  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = _fallback();
    final currentImageUrl = imageUrl?.trim();

    return Container(
      width: 132,
      height: 132,
      decoration: const BoxDecoration(
        color: AppColors.softSurface,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageBytes != null
          ? Image.memory(
              imageBytes!,
              key: const Key('profile_image_selected_preview'),
              fit: BoxFit.cover,
            )
          : currentImageUrl != null && currentImageUrl.isNotEmpty
              ? NetworkImageWithSkeleton(
                  imageKey: const Key('profile_image_current_preview'),
                  imageUrl: currentImageUrl,
                  width: 132,
                  height: 132,
                  fit: BoxFit.cover,
                  cacheWidth: 264,
                  cacheHeight: 264,
                  skeleton: fallback,
                  errorWidget: fallback,
                )
              : fallback,
    );
  }

  Widget _fallback() {
    return const Center(
      child: Icon(Icons.person, color: AppColors.primary, size: 58),
    );
  }
}
