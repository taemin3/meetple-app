import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../models/auth_session.dart';
import '../models/meeting.dart';
import '../screens/create_meeting/create_meeting_page.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/signup_page.dart';
import '../screens/meeting_detail/meeting_detail_page.dart';

abstract final class AppRouteNames {
  static const home = '/';
  static const login = '/auth/login';
  static const signUp = '/auth/signup';
  static const discover = '/discover';
  static const createMeeting = '/meetings/create';
  static const meetingDetail = '/meetings/detail';
  static const chat = '/chat';
  static const profile = '/profile';
}

abstract final class AppRoutes {
  static Future<AuthSession?> openLogin(
    BuildContext context, {
    AuthRepository authRepository = const MockAuthRepository(),
  }) {
    return Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        settings: const RouteSettings(name: AppRouteNames.login),
        builder: (_) => LoginPage(authRepository: authRepository),
      ),
    );
  }

  static Future<AuthSession?> openSignUp(
    BuildContext context, {
    AuthRepository authRepository = const MockAuthRepository(),
  }) {
    return Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        settings: const RouteSettings(name: AppRouteNames.signUp),
        builder: (_) => SignUpPage(authRepository: authRepository),
      ),
    );
  }

  static Future<T?> openCreateMeeting<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(name: AppRouteNames.createMeeting),
        builder: (_) => const CreateMeetingPage(),
      ),
    );
  }

  static Future<T?> openMeetingDetail<T>(
    BuildContext context,
    Meeting meeting,
  ) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(name: AppRouteNames.meetingDetail),
        builder: (_) => MeetingDetailPage(meeting: meeting),
      ),
    );
  }
}
