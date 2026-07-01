import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'app/app_dependencies.dart';
import 'app/meetple_app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasNaverMapClientId) {
    await FlutterNaverMap().init(
      clientId: AppConfig.naverMapClientId,
      onAuthFailed: (error) {
        debugPrint('Naver Map auth failed: $error');
      },
    );
  }

  runApp(
    MeetpleApp(
      authRepository: createAuthRepository(),
      meetingRepository: createMeetingRepository(),
      categoryRepository: createCategoryRepository(),
      locationRepository: createLocationRepository(),
    ),
  );
}
