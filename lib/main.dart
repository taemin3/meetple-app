import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/meetple_app.dart';

void main() {
  runApp(
    MeetpleApp(
      authRepository: createAuthRepository(),
      meetingRepository: createMeetingRepository(),
      categoryRepository: createCategoryRepository(),
      locationRepository: createLocationRepository(),
    ),
  );
}
