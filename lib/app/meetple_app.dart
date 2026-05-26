import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';
import 'app_shell.dart';

class MeetpleApp extends StatelessWidget {
  const MeetpleApp({
    super.key,
    this.authRepository,
    this.meetingRepository = const MockMeetingRepository(),
  });

  final AuthRepository? authRepository;
  final MeetingRepository meetingRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meetple',
      theme: AppTheme.light(),
      home: AppShell(
        authRepository: authRepository,
        meetingRepository: meetingRepository,
      ),
    );
  }
}
