import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_category_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';
import 'auth_entry_gate.dart';

class MeetpleApp extends StatelessWidget {
  const MeetpleApp({
    super.key,
    this.authRepository,
    this.meetingRepository = const MockMeetingRepository(),
    this.categoryRepository = const MockCategoryRepository(),
  });

  final AuthRepository? authRepository;
  final MeetingRepository meetingRepository;
  final CategoryRepository categoryRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meetple',
      theme: AppTheme.light(),
      home: AuthEntryGate(
        authRepository: authRepository,
        meetingRepository: meetingRepository,
        categoryRepository: categoryRepository,
      ),
    );
  }
}
