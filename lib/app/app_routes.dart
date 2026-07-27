import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/image_upload_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/mock_category_repository.dart';
import '../data/repositories/mock_image_upload_repository.dart';
import '../data/repositories/mock_location_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';
import '../models/auth_session.dart';
import '../models/meeting.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/signup_page.dart';
import '../screens/create_meeting/create_meeting_page.dart';
import '../screens/meeting_detail/meeting_detail_page.dart';
import 'app_route_names.dart';
import 'meeting_repository_scope.dart';

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
    LocationRepository? locationRepository,
    ImageUploadRepository? imageUploadRepository,
  }) {
    final repositoryScope = MeetingRepositoryScope.maybeScopeOf(context);
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(name: AppRouteNames.createMeeting),
        builder: (_) => CreateMeetingPage(
          meetingRepository: meetingRepository ??
              repositoryScope?.repository ??
              const MockMeetingRepository(),
          categoryRepository: categoryRepository ??
              repositoryScope?.categoryRepository ??
              const MockCategoryRepository(),
          locationRepository: locationRepository ??
              repositoryScope?.locationRepository ??
              const MockLocationRepository(),
          imageUploadRepository: imageUploadRepository ??
              repositoryScope?.imageUploadRepository ??
              const MockImageUploadRepository(),
        ),
      ),
    );
  }

  static Future<T?> openMeetingDetail<T>(
    BuildContext context,
    Meeting meeting, {
    MeetingRepository? meetingRepository,
    CategoryRepository? categoryRepository,
    LocationRepository? locationRepository,
    ImageUploadRepository? imageUploadRepository,
  }) {
    final repositoryScope = MeetingRepositoryScope.maybeScopeOf(context);
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(name: AppRouteNames.meetingDetail),
        builder: (_) => MeetingDetailPage(
          meeting: meeting,
          meetingRepository: meetingRepository ??
              repositoryScope?.repository ??
              const MockMeetingRepository(),
          categoryRepository:
              categoryRepository ?? repositoryScope?.categoryRepository,
          locationRepository:
              locationRepository ?? repositoryScope?.locationRepository,
          imageUploadRepository:
              imageUploadRepository ?? repositoryScope?.imageUploadRepository,
        ),
      ),
    );
  }
}
