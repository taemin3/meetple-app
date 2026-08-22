import 'package:flutter/widgets.dart';

import 'meeting_location_map_fallback.dart';

const isMeetingLocationMapSupported = false;

class MeetingLocationMap extends StatelessWidget {
  const MeetingLocationMap({
    super.key,
    required this.enabled,
    required this.latitude,
    required this.longitude,
    this.interactive = false,
    this.showMarker = false,
  });

  final bool enabled;
  final double latitude;
  final double longitude;
  final bool interactive;
  final bool showMarker;

  @override
  Widget build(BuildContext context) {
    return const MeetingLocationMapFallback();
  }
}
