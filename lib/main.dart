import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/meetple_app.dart';

void main() {
  runApp(MeetpleApp(meetingRepository: createMeetingRepository()));
}
