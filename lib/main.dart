import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/meetple_app.dart';
import 'core/config/app_config.dart';
import 'core/map/naver_map_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final pushNotificationService = createPushNotificationService();
  await pushNotificationService.initialize();

  if (AppConfig.hasNaverMapClientId) {
    await initializeNaverMap(
      clientId: AppConfig.naverMapClientId,
      onAuthFailed: (error) {
        debugPrint('Naver Map auth failed: $error');
      },
    );
  }

  runApp(
    MeetpleApp(
      authRepository: createAuthRepository(
        logoutDeviceIdProvider: pushNotificationService.deviceId,
      ),
      pushNotificationService: pushNotificationService,
      meetingRepository: createMeetingRepository(),
      chatRepository: createChatRepository(),
      chatRealtimeClient: createChatRealtimeClient(),
      categoryRepository: createCategoryRepository(),
      locationRepository: createLocationRepository(),
      imageUploadRepository: createImageUploadRepository(),
    ),
  );
}
