import 'package:flutter/widgets.dart';

import 'meeting_location_map_fallback.dart';

const isMeetingLocationMapSupported = false;

class MeetingLocationMap extends StatelessWidget {
  const MeetingLocationMap({
    super.key,
    required this.enabled,
    required this.latitude,
    required this.longitude,
  });

  final bool enabled;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return const MeetingLocationMapFallback();
  }
}
