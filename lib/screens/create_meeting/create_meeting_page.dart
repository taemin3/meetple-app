import 'package:flutter/material.dart';

import '../../app/app_navigation.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../widgets/primary_gradient_button.dart';

class CreateMeetingPage extends StatefulWidget {
  const CreateMeetingPage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
  });

  final MeetingRepository meetingRepository;

  @override
  State<CreateMeetingPage> createState() => _CreateMeetingPageState();
}

class _CreateMeetingPageState extends State<CreateMeetingPage> {
  static const _categoryOptions = <_MeetingCategoryOption>[
    _MeetingCategoryOption(label: '운동', value: 'exercise'),
    _MeetingCategoryOption(label: '스터디', value: 'study'),
    _MeetingCategoryOption(label: '취미', value: 'hobby'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _capacityController = TextEditingController(text: '2');
  final _descriptionController = TextEditingController();

  String _category = _categoryOptions.first.value;
  DateTime? _scheduledAt;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _scheduleController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
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
            options: _categoryOptions,
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
            label: '장소명',
            hint: 'ex) 여의도공원',
            textInputAction: TextInputAction.next,
            suffix: Icons.place_outlined,
            validator: (value) => _required(value, '장소명을 입력해주세요.'),
          ),
          CreateField(
            key: const Key('create_meeting_address'),
            controller: _addressController,
            label: '주소',
            hint: 'ex) 서울 영등포구 여의공원로 68',
            textInputAction: TextInputAction.next,
            validator: (value) => _required(value, '주소를 입력해주세요.'),
          ),
          Row(
            children: [
              Expanded(
                child: CreateField(
                  key: const Key('create_meeting_latitude'),
                  controller: _latitudeController,
                  label: '위도',
                  hint: '37.5219',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _numberInRange(
                    value,
                    min: -90,
                    max: 90,
                    emptyMessage: '위도를 입력해주세요.',
                    rangeMessage: '위도는 -90부터 90까지 입력해주세요.',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CreateField(
                  key: const Key('create_meeting_longitude'),
                  controller: _longitudeController,
                  label: '경도',
                  hint: '126.9245',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _numberInRange(
                    value,
                    min: -180,
                    max: 180,
                    emptyMessage: '경도를 입력해주세요.',
                    rangeMessage: '경도는 -180부터 180까지 입력해주세요.',
                  ),
                ),
              ),
            ],
          ),
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

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initialDate = _scheduledAt ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? initialDate),
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

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true || _scheduledAt == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    Object? submitError;
    try {
      await widget.meetingRepository.createMeeting(
        CreateMeetingInput(
          title: _titleController.text.trim(),
          category: _category,
          locationName: _locationNameController.text.trim(),
          address: _addressController.text.trim(),
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
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

  String? _numberInRange(
    String? value, {
    required double min,
    required double max,
    required String emptyMessage,
    required String rangeMessage,
  }) {
    final requiredMessage = _required(value, emptyMessage);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final number = double.tryParse(value!.trim());
    if (number == null || number < min || number > max) {
      return rangeMessage;
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

    final message = error.toString();
    if (message.isEmpty) {
      return '모임을 만들지 못했습니다.';
    }

    return message;
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
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<_MeetingCategoryOption> options;
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
          DropdownButtonFormField<String>(
            key: const Key('create_meeting_category'),
            value: value,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              for (final option in options)
                DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
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

class _MeetingCategoryOption {
  const _MeetingCategoryOption({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
