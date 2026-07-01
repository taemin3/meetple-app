import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/mock_category_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';
import '../models/auth_session.dart';
import '../models/meeting.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/signup_page.dart';
import '../screens/create_meeting/create_meeting_page.dart';
import '../screens/meeting_detail/meeting_detail_page.dart';
import 'app_route_names.dart';

abstract final class AppRoutes {
  static Future<AuthSession?> openLogin(
    BuildContext context, {
    AuthRepository? authRepository,
  }) {
    return Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        settings: const RouteSettings(name: AppRouteNames.login),
        builder: (_) => LoginPage(
          authRepository: authRepository ?? MockAuthRepository(),
        ),
      ),
    );
  }

  static Future<AuthSession?> openSignUp(
    BuildContext context, {
    AuthRepository? authRepository,
  }) {
    return Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        settings: const RouteSettings(name: AppRouteNames.signUp),
        builder: (_) => SignUpPage(
          authRepository: authRepository ?? MockAuthRepository(),
        ),
      ),
    );
  }

  static Future<T?> openCreateMeeting<T>(
    BuildContext context, {
    MeetingRepository? meetingRepository,
    CategoryRepository? categoryRepository,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(name: AppRouteNames.createMeeting),
        builder: (_) => CreateMeetingPage(
          meetingRepository: meetingRepository ?? const MockMeetingRepository(),
          categoryRepository:
              categoryRepository ?? const MockCategoryRepository(),
        ),
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
