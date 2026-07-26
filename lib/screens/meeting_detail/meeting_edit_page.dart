import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_dependencies.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/image_upload_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../models/meeting.dart';
import '../create_meeting/create_meeting_page.dart';

class MeetingEditPage extends StatefulWidget {
  const MeetingEditPage({
    super.key,
    required this.meeting,
    required this.meetingRepository,
    this.categoryRepository,
    this.locationRepository,
    this.imageUploadRepository,
    this.imagePicker,
  });

  final Meeting meeting;
  final MeetingRepository meetingRepository;
  final CategoryRepository? categoryRepository;
  final LocationRepository? locationRepository;
  final ImageUploadRepository? imageUploadRepository;
  final ImagePicker? imagePicker;

  @override
  State<MeetingEditPage> createState() => _MeetingEditPageState();
}

class _MeetingEditPageState extends State<MeetingEditPage> {
  late final CategoryRepository _categoryRepository =
      widget.categoryRepository ?? createCategoryRepository();
  late final LocationRepository _locationRepository =
      widget.locationRepository ?? createLocationRepository();
  late final ImageUploadRepository _imageUploadRepository =
      widget.imageUploadRepository ?? createImageUploadRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: MeetingFormPage(
          meetingRepository: widget.meetingRepository,
          categoryRepository: _categoryRepository,
          locationRepository: _locationRepository,
          imageUploadRepository: _imageUploadRepository,
          initialMeeting: widget.meeting,
          imagePicker: widget.imagePicker,
        ),
      ),
    );
  }
}
