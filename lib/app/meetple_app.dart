import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_shell.dart';

class MeetpleApp extends StatelessWidget {
  const MeetpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meetple',
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
