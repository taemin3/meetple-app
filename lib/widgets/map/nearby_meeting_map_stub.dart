import 'package:flutter/widgets.dart';

import '../../models/meeting.dart';
import 'nearby_meeting_map_fallback.dart';

const isNearbyMeetingMapSupported = false;

typedef NearbyMapCameraIdleCallback = void Function(
  NearbyMapCoordinate coordinate,
  double zoom,
);

class NearbyMapCoordinate {
  const NearbyMapCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

abstract interface class NearbyMeetingMapController {
  NearbyMapCoordinate get cameraTarget;

  Future<bool> moveTo(NearbyMapCoordinate coordinate, {double zoom = 14});

  Future<NearbyMapCoordinate?> requestCurrentLocation();
}

class NearbyMeetingMap extends StatefulWidget {
  const NearbyMeetingMap({
    super.key,
    required this.enabled,
    required this.initialCoordinate,
    required this.meetings,
    required this.selectedMeeting,
    required this.onMapReady,
    required this.onMapTapped,
    required this.onMeetingTapped,
    required this.onMeetingGroupTapped,
    required this.onCameraIdle,
    this.onLocationPermissionDenied,
  });

  final bool enabled;
  final NearbyMapCoordinate initialCoordinate;
  final List<Meeting> meetings;
  final Meeting? selectedMeeting;
  final ValueChanged<NearbyMeetingMapController> onMapReady;
  final VoidCallback onMapTapped;
  final ValueChanged<Meeting> onMeetingTapped;
  final ValueChanged<List<Meeting>> onMeetingGroupTapped;
  final NearbyMapCameraIdleCallback onCameraIdle;
  final ValueChanged<bool>? onLocationPermissionDenied;

  @override
  State<NearbyMeetingMap> createState() => _NearbyMeetingMapState();
}

class _NearbyMeetingMapState extends State<NearbyMeetingMap>
    implements NearbyMeetingMapController {
  late NearbyMapCoordinate _cameraTarget = widget.initialCoordinate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onMapReady(this);
      }
    });
  }

  @override
  NearbyMapCoordinate get cameraTarget => _cameraTarget;

  @override
  Future<bool> moveTo(
    NearbyMapCoordinate coordinate, {
    double zoom = 14,
  }) async {
    _cameraTarget = coordinate;
    widget.onCameraIdle(coordinate, zoom);
    return false;
  }

  @override
  Future<NearbyMapCoordinate?> requestCurrentLocation() async => null;

  @override
  Widget build(BuildContext context) {
    return NearbyMeetingMapFallback(
      meetings: widget.meetings,
      selectedMeeting: widget.selectedMeeting,
      onMeetingTapped: widget.onMeetingTapped,
      onMeetingGroupTapped: widget.onMeetingGroupTapped,
      onMapTapped: widget.onMapTapped,
    );
  }
}
