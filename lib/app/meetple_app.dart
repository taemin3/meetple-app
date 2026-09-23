import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../core/push/push_notification_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/image_upload_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/moderation_repository.dart';
import '../data/repositories/mock_moderation_repository.dart';
import '../data/repositories/mock_notification_repository.dart';
import '../data/repositories/mock_category_repository.dart';
import '../data/repositories/mock_chat_repository.dart';
import '../data/repositories/mock_image_upload_repository.dart';
import '../data/repositories/mock_location_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/realtime/chat_realtime_client.dart';
import '../data/realtime/mock_chat_realtime_client.dart';
import 'app_route_observer.dart';
import 'auth_entry_gate.dart';

class MeetpleApp extends StatelessWidget {
  const MeetpleApp({
    super.key,
    this.authRepository,
    this.authSessionExpired,
    this.pushNotificationService = const NoopPushNotificationService(),
    this.meetingRepository = const MockMeetingRepository(),
    ModerationRepository? moderationRepository,
    this.notificationRepository = const MockNotificationRepository(),
    this.chatRepository = const MockChatRepository(),
    this.chatRealtimeClient = const MockChatRealtimeClient(),
    this.categoryRepository = const MockCategoryRepository(),
    this.locationRepository = const MockLocationRepository(),
    this.imageUploadRepository = const MockImageUploadRepository(),
  }) : moderationRepository =
            moderationRepository ?? const MockModerationRepository();

  final AuthRepository? authRepository;
  final Stream<void>? authSessionExpired;
  final PushNotificationService pushNotificationService;
  final MeetingRepository meetingRepository;
  final ModerationRepository moderationRepository;
  final NotificationRepository notificationRepository;
  final ChatRepository chatRepository;
  final ChatRealtimeClient chatRealtimeClient;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final ImageUploadRepository imageUploadRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '밋플',
      theme: AppTheme.light(),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemUiOverlayStyle,
        child: child ?? const SizedBox.shrink(),
      ),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      navigatorObservers: [appRouteObserver],
      home: AuthEntryGate(
        authRepository: authRepository,
        authSessionExpired: authSessionExpired,
        pushNotificationService: pushNotificationService,
        meetingRepository: meetingRepository,
        moderationRepository: moderationRepository,
        notificationRepository: notificationRepository,
        chatRepository: chatRepository,
        chatRealtimeClient: chatRealtimeClient,
        categoryRepository: categoryRepository,
        locationRepository: locationRepository,
        imageUploadRepository: imageUploadRepository,
      ),
    );
  }
}
