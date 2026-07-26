import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_navigation.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/image_upload_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_category_repository.dart';
import '../../data/repositories/mock_image_upload_repository.dart';
import '../../data/repositories/mock_location_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/location_search_result.dart';
import '../../models/meeting.dart';
import '../../models/meeting_category.dart';
import '../../screens/location_picker/location_picker_page.dart';
import '../../widgets/primary_gradient_button.dart';

class CreateMeetingPage extends StatelessWidget {
  const CreateMeetingPage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
    this.categoryRepository = const MockCategoryRepository(),
    this.locationRepository = const MockLocationRepository(),
    this.imageUploadRepository = const MockImageUploadRepository(),
    this.imagePicker,
  });

  final MeetingRepository meetingRepository;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final ImageUploadRepository imageUploadRepository;
  final ImagePicker? imagePicker;

  @override
  Widget build(BuildContext context) {
    return MeetingFormPage(
      meetingRepository: meetingRepository,
      categoryRepository: categoryRepository,
      locationRepository: locationRepository,
      imageUploadRepository: imageUploadRepository,
      imagePicker: imagePicker,
    );
  }
}

class MeetingFormPage extends StatefulWidget {
  const MeetingFormPage({
    super.key,
    required this.meetingRepository,
    required this.categoryRepository,
    required this.locationRepository,
    required this.imageUploadRepository,
    this.initialMeeting,
    this.imagePicker,
  });

  final MeetingRepository meetingRepository;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final ImageUploadRepository imageUploadRepository;
  final Meeting? initialMeeting;
  final ImagePicker? imagePicker;

  bool get isEditing => initialMeeting != null;

  @override
  State<MeetingFormPage> createState() => _MeetingFormPageState();
}

class _MeetingFormPageState extends State<MeetingFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _scheduleController;
  late final TextEditingController _locationNameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _descriptionController;

  String? _category;
  List<MeetingCategory> _categories = const [];
  Object? _categoryError;
  bool _isLoadingCategories = true;
  int _categoryLoadGeneration = 0;
  DateTime? _scheduledAt;
  LocationSearchResult? _selectedLocation;
  bool _isSubmitting = false;
  bool _isPickingImages = false;
  final List<_SelectedMeetingImage> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    final meeting = widget.initialMeeting;
    _scheduledAt = _initialSchedule(meeting);
    _selectedLocation = _initialLocation(meeting);
    _category = meeting?.category;
    _titleController = TextEditingController(text: meeting?.title);
    _scheduleController = TextEditingController(
      text: _scheduledAt == null ? '' : _formatSchedule(_scheduledAt!),
    );
    _locationNameController = TextEditingController(
      text: _selectedLocation?.name ?? meeting?.area ?? '',
    );
    _capacityController = TextEditingController(
      text: (meeting?.capacity ?? 2).toString(),
    );
    _descriptionController = TextEditingController(
      text: meeting?.description,
    );
    _selectedImages.addAll(
      _initialImageUrls(meeting).map(_SelectedMeetingImage.remote),
    );
    _loadCategories(showLoading: false);
    unawaited(_restoreLostImages());
  }

  @override
  void didUpdateWidget(covariant MeetingFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryRepository != widget.categoryRepository) {
      _loadCategories();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scheduleController.dispose();
    _locationNameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          MeetingFormHeader(
            title: widget.isEditing ? '모임 수정' : '모임 만들기',
            onClose: _close,
          ),
          const SizedBox(height: 24),
          _ImageUploadBox(
            images: _selectedImages,
            isBusy: _isSubmitting || _isPickingImages,
            onPick: _pickImages,
            onRemove: _removeImage,
          ),
          const SizedBox(height: 26),
          CreateField(
            key: const Key('create_meeting_title'),
            controller: _titleController,
            label: '모임 제목',
            hint: 'ex) 같이 책 읽는 모임',
            textInputAction: TextInputAction.next,
            validator: (value) => _required(value, '모임 제목을 입력해주세요.'),
          ),
          _CategoryField(
            value: _category,
            categories: _categories,
            isLoading: _isLoadingCategories,
            error: _categoryError,
            onRetry: _loadCategories,
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() => _category = value);
            },
          ),
          CreateField(
            key: const Key('create_meeting_schedule'),
            controller: _scheduleController,
            label: '일시',
            hint: '날짜와 시간을 선택해주세요',
            readOnly: true,
            suffix: Icons.calendar_today_outlined,
            onTap: _pickSchedule,
            validator: (value) =>
                _scheduledAt == null ? '모임 일시를 선택해주세요.' : null,
          ),
          CreateField(
            key: const Key('create_meeting_location_name'),
            controller: _locationNameController,
            label: '장소',
            hint: '장소를 검색해서 선택해주세요',
            readOnly: true,
            suffix: Icons.search,
            onTap: _openLocationPicker,
            validator: (_) => _selectedLocation == null ? '장소를 선택해주세요.' : null,
          ),
          if (_selectedLocation != null) ...[
            _SelectedLocationPanel(location: _selectedLocation!),
            const SizedBox(height: 18),
          ],
          CreateField(
            key: const Key('create_meeting_capacity'),
            controller: _capacityController,
            label: '인원',
            hint: '모집 인원을 입력해주세요',
            suffixText: '명',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: _capacityValidator,
          ),
          CreateTextArea(
            key: const Key('create_meeting_description'),
            controller: _descriptionController,
          ),
          const SizedBox(height: 12),
          PrimaryGradientButton(
            key: const Key('create_meeting_submit'),
            label: _isSubmitting
                ? widget.isEditing
                    ? '수정하는 중...'
                    : '만드는 중...'
                : widget.isEditing
                    ? '수정 완료'
                    : '모임 만들기',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _loadCategories({bool showLoading = true}) async {
    final generation = ++_categoryLoadGeneration;
    if (showLoading) {
      setState(() {
        _isLoadingCategories = true;
        _categoryError = null;
      });
    }

    List<MeetingCategory> categories = const [];
    Object? categoryError;
    try {
      categories = await widget.categoryRepository.findAll();
    } on Object catch (error) {
      categoryError = error;
    }

    if (!mounted || generation != _categoryLoadGeneration) {
      return;
    }

    setState(() {
      _isLoadingCategories = false;
      _categoryError = categoryError;

      if (categoryError != null) {
        return;
      }

      final initialCategory = widget.initialMeeting?.category;
      _categories = initialCategory != null &&
              categories.every((category) => category.name != initialCategory)
          ? [
              MeetingCategory(id: -1, name: initialCategory),
              ...categories,
            ]
          : categories;
      if (_categories.isEmpty) {
        _category = null;
        return;
      }

      final hasSelectedCategory = _categories.any(
        (category) => category.name == _category,
      );
      if (!hasSelectedCategory) {
        _category = _categories.first.name;
      }
    });
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = firstDate.add(const Duration(days: 365));
    final initialDate = _clampDate(
      _scheduledAt ?? firstDate.add(const Duration(days: 1)),
      firstDate,
      lastDate,
    );
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null || !mounted) {
      return;
    }

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (!selected.isAfter(DateTime.now())) {
      _showSnackBar('현재 이후의 일시를 선택해주세요.');
      return;
    }

    setState(() {
      _scheduledAt = selected;
      _scheduleController.text = _formatSchedule(selected);
    });
  }

  Future<void> _openLocationPicker() async {
    FocusScope.of(context).unfocus();

    final selected = await Navigator.of(context).push<LocationSearchResult>(
      MaterialPageRoute<LocationSearchResult>(
        builder: (_) => LocationPickerPage(
          locationRepository: widget.locationRepository,
        ),
        fullscreenDialog: true,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLocation = selected;
      _locationNameController.text = selected.name;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isPickingImages) {
      return;
    }

    FocusScope.of(context).unfocus();

    final category = _category;
    final selectedLocation = _selectedLocation;
    if (_formKey.currentState?.validate() != true ||
        _scheduledAt == null ||
        category == null ||
        selectedLocation == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    Object? submitError;
    Meeting? updatedMeeting;
    try {
      final localImages = [
        for (final image in _selectedImages)
          if (image.bytes != null)
            ImageUploadFile(
              name: image.name,
              contentType: image.contentType,
              bytes: image.bytes!,
            ),
      ];
      final uploadedImageUrls =
          await widget.imageUploadRepository.uploadMeetingImages(
        localImages,
      );
      final imageUrls = [
        for (final image in _selectedImages)
          if (image.remoteUrl != null) image.remoteUrl!,
        ...uploadedImageUrls,
      ];

      if (widget.initialMeeting case final meeting?) {
        updatedMeeting = await widget.meetingRepository.updateMeetingDetails(
          meeting.id!,
          UpdateMeetingInput(
            title: _titleController.text.trim(),
            category: category,
            locationName: selectedLocation.name,
            address: selectedLocation.address,
            latitude: selectedLocation.latitude,
            longitude: selectedLocation.longitude,
            scheduledAt: _scheduledAt!,
            capacity: int.parse(_capacityController.text.trim()),
            description: _descriptionController.text.trim(),
            imageUrls: imageUrls,
          ),
        );
      } else {
        await widget.meetingRepository.createMeeting(
          CreateMeetingInput(
            title: _titleController.text.trim(),
            category: category,
            locationName: selectedLocation.name,
            address: selectedLocation.address,
            latitude: selectedLocation.latitude,
            longitude: selectedLocation.longitude,
            scheduledAt: _scheduledAt!,
            capacity: int.parse(_capacityController.text.trim()),
            description: _descriptionController.text.trim(),
            imageUrls: imageUrls,
          ),
        );
      }
    } on Object catch (error) {
      submitError = error;
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (submitError != null) {
      _showSnackBar(_submitErrorMessage(submitError));
      return;
    }

    if (widget.isEditing) {
      Navigator.of(context).pop(updatedMeeting);
      return;
    }

    _showSnackBar('모임을 만들었습니다.');

    final navigation = AppNavigation.maybeOf(context);
    if (navigation != null) {
      navigation.selectTab(AppTab.home);
      return;
    }

    Navigator.of(context).maybePop();
  }

  Future<void> _pickImages() async {
    if (_isSubmitting || _isPickingImages) {
      return;
    }

    if (_selectedImages.length >= 10) {
      _showSnackBar('이미지는 최대 10장까지 선택할 수 있습니다.');
      return;
    }

    setState(() => _isPickingImages = true);

    List<XFile> pickedFiles = const [];
    Object? pickError;
    try {
      pickedFiles = await (widget.imagePicker ?? ImagePicker()).pickMultiImage(
        imageQuality: 85,
      );
    } on Object catch (error) {
      pickError = error;
    }

    if (!mounted) {
      return;
    }

    final remaining = 10 - _selectedImages.length;
    final nextImages = <_SelectedMeetingImage>[];
    var hasUnsupportedImage = false;
    try {
      for (final file in pickedFiles.take(remaining)) {
        final bytes = await file.readAsBytes();
        final contentType = _resolveImageContentType(file.mimeType, file.name);
        if (contentType == null) {
          hasUnsupportedImage = true;
          continue;
        }

        nextImages.add(
          _SelectedMeetingImage(
            name: file.name,
            contentType: contentType,
            bytes: bytes,
          ),
        );
      }
    } on Object catch (error) {
      pickError = error;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPickingImages = false;
      _selectedImages.addAll(nextImages);
    });

    if (pickError != null) {
      _showSnackBar('이미지를 불러오지 못했습니다.');
      return;
    }

    if (pickedFiles.length > remaining) {
      _showSnackBar('이미지는 최대 10장까지 선택할 수 있습니다.');
      return;
    }

    if (hasUnsupportedImage) {
      _showSnackBar('jpg, png, webp 이미지만 업로드할 수 있습니다.');
    }
  }

  Future<void> _restoreLostImages() async {
    LostDataResponse response;
    try {
      response = await (widget.imagePicker ?? ImagePicker()).retrieveLostData();
    } on Object {
      return;
    }

    if (!mounted || response.isEmpty) {
      return;
    }

    final files = response.files;
    final lostFiles = files == null || files.isEmpty
        ? [if (response.file != null) response.file!]
        : files;
    if (lostFiles.isEmpty || _selectedImages.length >= 10) {
      return;
    }

    setState(() => _isPickingImages = true);

    Object? restoreError;
    var hasUnsupportedImage = false;
    final remaining = 10 - _selectedImages.length;
    final nextImages = <_SelectedMeetingImage>[];
    try {
      for (final file in lostFiles.take(remaining)) {
        final bytes = await file.readAsBytes();
        final contentType = _resolveImageContentType(file.mimeType, file.name);
        if (contentType == null) {
          hasUnsupportedImage = true;
          continue;
        }

        nextImages.add(
          _SelectedMeetingImage(
            name: file.name,
            contentType: contentType,
            bytes: bytes,
          ),
        );
      }
    } on Object catch (error) {
      restoreError = error;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPickingImages = false;
      _selectedImages.addAll(nextImages);
    });

    if (restoreError != null) {
      _showSnackBar('이미지를 불러오지 못했습니다.');
      return;
    }

    if (lostFiles.length > remaining) {
      _showSnackBar('이미지는 최대 10장까지 선택할 수 있습니다.');
      return;
    }

    if (hasUnsupportedImage) {
      _showSnackBar('jpg, png, webp 이미지만 업로드할 수 있습니다.');
    }
  }

  void _removeImage(int index) {
    if (_isSubmitting || index < 0 || index >= _selectedImages.length) {
      return;
    }

    setState(() => _selectedImages.removeAt(index));
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  String? _capacityValidator(String? value) {
    final requiredMessage = _required(value, '모집 인원을 입력해주세요.');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final capacity = int.tryParse(value!.trim());
    final joined = widget.initialMeeting?.joined ?? 0;
    final minimumCapacity = joined > 2 ? joined : 2;
    if (capacity == null || capacity < minimumCapacity || capacity > 100) {
      if (joined > 2) {
        return '현재 참여 인원 이상, 100명 이하로 입력해주세요.';
      }
      return '인원은 2명부터 100명까지 입력해주세요.';
    }

    return null;
  }

  String _submitErrorMessage(Object error) {
    if (error is ImageUploadException) {
      return error.message;
    }

    if (error is ApiException) {
      return error.message;
    }

    return widget.isEditing ? '모임을 수정하지 못했습니다.' : '모임을 만들지 못했습니다.';
  }

  String? _resolveImageContentType(String? mimeType, String fileName) {
    final normalizedMimeType = mimeType?.toLowerCase();
    if (_isSupportedImageContentType(normalizedMimeType)) {
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

  bool _isSupportedImageContentType(String? contentType) {
    return contentType == 'image/jpeg' ||
        contentType == 'image/png' ||
        contentType == 'image/webp';
  }

  DateTime _clampDate(DateTime value, DateTime firstDate, DateTime lastDate) {
    if (value.isBefore(firstDate)) {
      return firstDate;
    }

    if (value.isAfter(lastDate)) {
      return lastDate;
    }

    return value;
  }

  String _formatSchedule(DateTime dateTime) {
    return '${dateTime.year}.${_twoDigits(dateTime.month)}.${_twoDigits(dateTime.day)} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _close() {
    if (widget.isEditing) {
      Navigator.of(context).maybePop();
      return;
    }

    final navigation = AppNavigation.maybeOf(context);
    if (navigation != null) {
      navigation.selectTab(AppTab.home);
      return;
    }

    Navigator.of(context).maybePop();
  }

  List<String> _initialImageUrls(Meeting? meeting) {
    if (meeting == null) return const [];
    final imageUrls = [
      for (final imageUrl in meeting.imageUrls)
        if (imageUrl.trim().isNotEmpty) imageUrl.trim(),
    ];
    if (imageUrls.isNotEmpty) return imageUrls;
    final primaryImageUrl = meeting.primaryImageUrl;
    return primaryImageUrl == null ? const [] : [primaryImageUrl];
  }

  LocationSearchResult? _initialLocation(Meeting? meeting) {
    if (meeting == null || !meeting.hasCoordinate) return null;
    return LocationSearchResult(
      id: 'meeting-${meeting.id ?? 'edit'}',
      type: 'PLACE',
      name: meeting.area,
      category: meeting.category,
      address: meeting.address ?? meeting.area,
      latitude: meeting.latitude!,
      longitude: meeting.longitude!,
      provider: 'MEETING',
    );
  }

  DateTime? _initialSchedule(Meeting? meeting) {
    final scheduledAt = meeting?.scheduledAt;
    if (scheduledAt != null) return scheduledAt;
    if (meeting == null) return null;

    final dateMatch = RegExp(r'(\d{1,2})/(\d{1,2})').firstMatch(meeting.date);
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(meeting.time);
    if (dateMatch == null || timeMatch == null) return null;

    final now = DateTime.now();
    var candidate = DateTime(
      now.year,
      int.parse(dateMatch.group(1)!),
      int.parse(dateMatch.group(2)!),
      int.parse(timeMatch.group(1)!),
      int.parse(timeMatch.group(2)!),
    );
    if (!candidate.isAfter(now)) {
      candidate = DateTime(
        now.year + 1,
        candidate.month,
        candidate.day,
        candidate.hour,
        candidate.minute,
      );
    }
    return candidate;
  }
}

class _SelectedLocationPanel extends StatelessWidget {
  const _SelectedLocationPanel({required this.location});

  final LocationSearchResult location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  location.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${location.latitude.toStringAsFixed(5)}, '
                  '${location.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MeetingFormHeader extends StatelessWidget {
  const MeetingFormHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _SelectedMeetingImage {
  const _SelectedMeetingImage({
    required this.name,
    required this.contentType,
    required this.bytes,
  }) : remoteUrl = null;

  const _SelectedMeetingImage.remote(this.remoteUrl)
      : name = '',
        contentType = '',
        bytes = null;

  final String name;
  final String contentType;
  final Uint8List? bytes;
  final String? remoteUrl;
}

class _ImageUploadBox extends StatelessWidget {
  const _ImageUploadBox({
    required this.images,
    required this.isBusy,
    required this.onPick,
    required this.onRemove,
  });

  final List<_SelectedMeetingImage> images;
  final bool isBusy;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('create_meeting_pick_images'),
          onTap: isBusy ? null : onPick,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  isBusy ? '이미지를 불러오는 중입니다.' : '모임 이미지를 추가해주세요',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '모임 이미지',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              if (index == images.length) {
                return _AddImageTile(
                  isBusy: isBusy,
                  onTap: onPick,
                );
              }

              return _SelectedImageTile(
                image: images[index],
                isRepresentative: index == 0,
                onRemove: () => onRemove(index),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: images.length < 10 ? images.length + 1 : images.length,
          ),
        ),
      ],
    );
  }
}

class _SelectedImageTile extends StatelessWidget {
  const _SelectedImageTile({
    required this.image,
    required this.isRepresentative,
    required this.onRemove,
  });

  final _SelectedMeetingImage image;
  final bool isRepresentative;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: image.remoteUrl == null
                ? Image.memory(
                    image.bytes!,
                    width: 132,
                    height: 132,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    image.remoteUrl!,
                    width: 132,
                    height: 132,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.softSurface,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
          ),
          if (isRepresentative)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '대표',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 6,
            top: 6,
            child: IconButton.filled(
              onPressed: onRemove,
              constraints: const BoxConstraints.tightFor(
                width: 32,
                height: 32,
              ),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.48),
              ),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({
    required this.isBusy,
    required this.onTap,
  });

  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          color: AppColors.softSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.35),
            width: 1.2,
          ),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.primary,
          size: 32,
        ),
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.value,
    required this.categories,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onChanged,
  });

  final String? value;
  final List<MeetingCategory> categories;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '카테고리',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const _CategoryStatusField(
              message: '카테고리를 불러오는 중입니다.',
              validatorMessage: '카테고리를 불러오는 중입니다.',
            )
          else if (error != null)
            _CategoryStatusField(
              message: '카테고리를 불러오지 못했습니다.',
              validatorMessage: '카테고리를 다시 불러와주세요.',
              onRetry: onRetry,
            )
          else if (categories.isEmpty)
            const _CategoryStatusField(
              message: '사용할 수 있는 카테고리가 없습니다.',
              validatorMessage: '사용할 수 있는 카테고리가 없습니다.',
            )
          else
            DropdownButtonFormField<String>(
              key: const Key('create_meeting_category'),
              value: value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '카테고리를 선택해주세요.';
                }

                return null;
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final category in categories)
                  DropdownMenuItem<String>(
                    value: category.name,
                    child: Text(category.name),
                  ),
              ],
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _CategoryStatusField extends StatelessWidget {
  const _CategoryStatusField({
    required this.message,
    required this.validatorMessage,
    this.onRetry,
  });

  final String message;
  final String validatorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => validatorMessage,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('재시도'),
                    ),
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class CreateField extends StatelessWidget {
  const CreateField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.suffix,
    this.suffixText,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? suffix;
  final String? suffixText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffix != null ? Icon(suffix) : null,
              suffixText: suffixText,
            ),
          ),
        ],
      ),
    );
  }
}

class CreateTextArea extends StatelessWidget {
  const CreateTextArea({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '소개',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            maxLines: 5,
            maxLength: 1000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '모임 소개를 입력해주세요.';
              }

              return null;
            },
            decoration: const InputDecoration(
              hintText: '모임을 소개해주세요 :)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}
