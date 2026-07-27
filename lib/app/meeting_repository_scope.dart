import 'package:flutter/widgets.dart';

import '../data/repositories/category_repository.dart';
import '../data/repositories/image_upload_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/meeting_repository.dart';

class MeetingRepositoryScope extends InheritedWidget {
  const MeetingRepositoryScope({
    super.key,
    required this.repository,
    required this.categoryRepository,
    required this.locationRepository,
    required this.imageUploadRepository,
    required super.child,
  });

  final MeetingRepository repository;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final ImageUploadRepository imageUploadRepository;

  static MeetingRepositoryScope? maybeScopeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MeetingRepositoryScope>();
  }

  static MeetingRepository? maybeOf(BuildContext context) {
    return maybeScopeOf(context)?.repository;
  }

  @override
  bool updateShouldNotify(MeetingRepositoryScope oldWidget) {
    return repository != oldWidget.repository ||
        categoryRepository != oldWidget.categoryRepository ||
        locationRepository != oldWidget.locationRepository ||
        imageUploadRepository != oldWidget.imageUploadRepository;
  }
}
