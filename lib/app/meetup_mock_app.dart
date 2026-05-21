import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_shell.dart';

class MeetupMockApp extends StatelessWidget {
  const MeetupMockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'meetple',
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
