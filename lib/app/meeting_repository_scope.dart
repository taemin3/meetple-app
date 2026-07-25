import 'package:flutter/widgets.dart';

import '../data/repositories/meeting_repository.dart';

class MeetingRepositoryScope extends InheritedWidget {
  const MeetingRepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final MeetingRepository repository;

  static MeetingRepository? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MeetingRepositoryScope>()
        ?.repository;
  }

  @override
  bool updateShouldNotify(MeetingRepositoryScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
