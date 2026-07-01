import 'package:flutter/material.dart';

import '../../app/app_navigation.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_category_repository.dart';
import '../../data/repositories/mock_location_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/location_search_result.dart';
import '../../models/meeting_category.dart';
import '../../screens/location_picker/location_picker_page.dart';
import '../../widgets/primary_gradient_button.dart';

class CreateMeetingPage extends StatefulWidget {
  const CreateMeetingPage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
    this.categoryRepository = const MockCategoryRepository(),
    this.locationRepository = const MockLocationRepository(),
  });

  final MeetingRepository meetingRepository;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;

  @override
  State<CreateMeetingPage> createState() => _CreateMeetingPageState();
}

class _CreateMeetingPageState extends State<CreateMeetingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _capacityController = TextEditingController(text: '2');
  final _descriptionController = TextEditingController();

  String? _category;
  List<MeetingCategory> _categories = const [];
  Object? _categoryError;
  bool _isLoadingCategories = true;
  int _categoryLoadGeneration = 0;
  DateTime? _scheduledAt;
  LocationSearchResult? _selectedLocation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories(showLoading: false);
  }

  @override
  void didUpdateWidget(covariant CreateMeetingPage oldWidget) {
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
          const CreateHeader(),
          const SizedBox(height: 24),
          const ImageUploadBox(),
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
            label: _isSubmitting ? '만드는 중...' : '모임 만들기',
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

      _categories = categories;
      if (categories.isEmpty) {
        _category = null;
        return;
      }

      final hasSelectedCategory = categories.any(
        (category) => category.name == _category,
      );
      if (!hasSelectedCategory) {
        _category = categories.first.name;
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
    if (_isSubmitting) {
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
    try {
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
        ),
      );
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

    _showSnackBar('모임을 만들었습니다.');

    final navigation = AppNavigation.maybeOf(context);
    if (navigation != null) {
      navigation.selectTab(AppTab.home);
      return;
    }

    Navigator.of(context).maybePop();
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
    if (capacity == null || capacity < 2 || capacity > 100) {
      return '인원은 2명부터 100명까지 입력해주세요.';
    }

    return null;
  }

  String _submitErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return '모임을 만들지 못했습니다.';
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

class CreateHeader extends StatelessWidget {
  const CreateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _close(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const Expanded(
          child: Text(
            '모임 만들기',
            textAlign: TextAlign.center,
            style: TextStyle(
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

  void _close(BuildContext context) {
    final navigation = AppNavigation.maybeOf(context);
    if (navigation != null) {
      navigation.selectTab(AppTab.home);
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

class ImageUploadBox extends StatelessWidget {
  const ImageUploadBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.primary,
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            '모임 이미지를 추가해주세요',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
