import 'package:flutter/material.dart';

import '../models/meeting.dart';
import '../screens/create_meeting/create_meeting_page.dart';
import '../screens/meeting_detail/meeting_detail_page.dart';

abstract final class AppRouteNames {
  static const home = '/';
  static const discover = '/discover';
  static const createMeeting = '/meetings/create';
  static const meetingDetail = '/meetings/detail';
  static const chat = '/chat';
  static const profile = '/profile';
}

abstract final class AppRoutes {
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
