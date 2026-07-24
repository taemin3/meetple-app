import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../core/theme/app_colors.dart';
import '../../models/meeting.dart';
import 'nearby_meeting_map_fallback.dart';

const isNearbyMeetingMapSupported = true;

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

class _NearbyMeetingMapState extends State<NearbyMeetingMap> {
  NaverMapController? _controller;
  NOverlayImage? _meetingMarkerIcon;
  NOverlayImage? _clusterMarkerIcon;
  final Set<NOverlayInfo> _meetingOverlayInfos = {};
  final Map<String, Meeting> _meetingByMarkerId = {};
  NDefaultMyLocationTracker? _locationTracker;

  @override
  void didUpdateWidget(covariant NearbyMeetingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meetings != widget.meetings ||
        oldWidget.selectedMeeting != widget.selectedMeeting) {
      _syncMeetingMarkers();
    }
  }

  @override
  void dispose() {
    _locationTracker?.disposeLocationService();
    _locationTracker?.unbindAppLifecycleChange();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return NearbyMeetingMapFallback(
        meetings: widget.meetings,
        selectedMeeting: widget.selectedMeeting,
        onMeetingTapped: widget.onMeetingTapped,
        onMeetingGroupTapped: widget.onMeetingGroupTapped,
        onMapTapped: widget.onMapTapped,
      );
    }

    return NaverMap(
      key: const Key('nearby_meeting_map'),
      forceGesture: true,
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: widget.initialCoordinate.toNLatLng(),
          zoom: 14,
        ),
        consumeSymbolTapEvents: false,
        indoorLevelPickerEnable: false,
        locationButtonEnable: false,
        scaleBarEnable: false,
        compassEnable: false,
        logoAlign: NLogoAlign.leftBottom,
        logoMargin: const EdgeInsets.fromLTRB(12, 0, 0, 264),
        contentPadding: const EdgeInsets.only(bottom: 250),
      ),
      clusterOptions: NaverMapClusteringOptions(
        mergeStrategy: const NClusterMergeStrategy(
          willMergedScreenDistance: {
            NaverMapClusteringOptions.defaultClusteringZoomRange: 42,
          },
        ),
        clusterMarkerBuilder: (info, clusterMarker) {
          if (_clusterMarkerIcon != null) {
            clusterMarker.setIcon(_clusterMarkerIcon);
            clusterMarker.setSize(const Size(44, 44));
          } else {
            clusterMarker.setIconTintColor(AppColors.primary);
          }
          clusterMarker.setCaptionAligns(const [NAlign.center]);
          clusterMarker.setCaption(
            NOverlayCaption(
              text: info.size > 9 ? '10+' : info.size.toString(),
              textSize: 12,
              color: Colors.white,
              haloColor: Colors.transparent,
            ),
          );
          final clusteredMeetings = info.children
              .map((child) => _meetingByMarkerId[child.id])
              .whereType<Meeting>()
              .toList(growable: false);
          clusterMarker.setOnTapListener((_) {
            if (clusteredMeetings.length == 1) {
              widget.onMeetingTapped(clusteredMeetings.single);
            } else if (clusteredMeetings.isNotEmpty) {
              widget.onMeetingGroupTapped(clusteredMeetings);
            }
          });
        },
      ),
      onMapReady: _handleMapReady,
      onMapTapped: (_, __) => widget.onMapTapped(),
      onCameraIdle: () {
        final target = _controller?.nowCameraPosition.target;
        final zoom = _controller?.nowCameraPosition.zoom;
        if (target != null && zoom != null) {
          widget.onCameraIdle(target.toNearbyMapCoordinate(), zoom);
        }
      },
    );
  }

  Future<void> _handleMapReady(NaverMapController controller) async {
    _controller = controller;
    final locationTracker = _locationTracker ??= NDefaultMyLocationTracker(
      onPermissionDenied: (isForeverDenied) {
        widget.onLocationPermissionDenied?.call(isForeverDenied);
      },
    );
    controller.setMyLocationTracker(locationTracker);
    await _createMarkerImages();
    await _syncMeetingMarkers();

    if (!mounted || _controller != controller) {
      return;
    }

    widget.onMapReady(
      _NaverNearbyMeetingMapController(
        controller,
        locationTracker,
      ),
    );
  }

  Future<void> _createMarkerImages() async {
    if (_meetingMarkerIcon != null && _clusterMarkerIcon != null) {
      return;
    }

    final images = await Future.wait([
      NOverlayImage.fromWidget(
        widget: const _MeetingMarkerGlyph(),
        size: const Size(38, 38),
        context: context,
      ),
      NOverlayImage.fromWidget(
        widget: const _ClusterMarkerGlyph(),
        size: const Size(44, 44),
        context: context,
      ),
    ]);
    _meetingMarkerIcon = images[0];
    _clusterMarkerIcon = images[1];
  }

  Future<void> _syncMeetingMarkers() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    for (final info in _meetingOverlayInfos.toList(growable: false)) {
      await controller.deleteOverlay(info);
    }
    _meetingOverlayInfos.clear();
    _meetingByMarkerId.clear();

    final markers = <NClusterableMarker>{};
    for (var index = 0; index < widget.meetings.length; index++) {
      final meeting = widget.meetings[index];
      final latitude = meeting.latitude;
      final longitude = meeting.longitude;
      if (latitude == null || longitude == null) {
        continue;
      }

      final selected = _isSelected(meeting);
      final markerId = 'meeting-${meeting.id ?? index}';
      final marker = NClusterableMarker(
        id: markerId,
        position: NLatLng(latitude, longitude),
        icon: _meetingMarkerIcon,
        size: Size.square(selected ? 46 : 38),
        caption: selected
            ? NOverlayCaption(
                text: meeting.title,
                textSize: 11,
                color: AppColors.ink,
                haloColor: Colors.white,
              )
            : null,
        captionOffset: 5,
        isForceShowIcon: selected,
        isForceShowCaption: selected,
      );
      marker.setOnTapListener((_) {
        widget.onMeetingTapped(meeting);
      });
      markers.add(marker);
      _meetingOverlayInfos.add(marker.info);
      _meetingByMarkerId[markerId] = meeting;
    }

    if (markers.isNotEmpty) {
      await controller.addOverlayAll(markers);
    }
  }

  bool _isSelected(Meeting meeting) {
    final selectedId = widget.selectedMeeting?.id;
    if (selectedId != null) {
      return meeting.id == selectedId;
    }
    return identical(meeting, widget.selectedMeeting);
  }
}

class _NaverNearbyMeetingMapController implements NearbyMeetingMapController {
  const _NaverNearbyMeetingMapController(
    this._controller,
    this._locationTracker,
  );

  final NaverMapController _controller;
  final NDefaultMyLocationTracker _locationTracker;

  @override
  NearbyMapCoordinate get cameraTarget {
    return _controller.nowCameraPosition.target.toNearbyMapCoordinate();
  }

  @override
  Future<bool> moveTo(
    NearbyMapCoordinate coordinate, {
    double zoom = 14,
  }) {
    return _controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: coordinate.toNLatLng(),
        zoom: zoom,
      ),
    );
  }

  @override
  Future<NearbyMapCoordinate?> requestCurrentLocation() async {
    try {
      await _locationTracker.requestLocationPermission();
      final position = await _locationTracker.getCurrentPositionOnce();
      final locationOverlay = _controller.getLocationOverlay();
      locationOverlay
        ..setPosition(position)
        ..setIsVisible(true);
      _controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
      return position.toNearbyMapCoordinate();
    } catch (_) {
      return null;
    }
  }
}

class _MeetingMarkerGlyph extends StatelessWidget {
  const _MeetingMarkerGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.violet, AppColors.primary],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4017151F),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 19),
    );
  }
}

class _ClusterMarkerGlyph extends StatelessWidget {
  const _ClusterMarkerGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.violet, AppColors.primary],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4017151F),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
    );
  }
}

extension on NearbyMapCoordinate {
  NLatLng toNLatLng() => NLatLng(latitude, longitude);
}

extension on NLatLng {
  NearbyMapCoordinate toNearbyMapCoordinate() {
    return NearbyMapCoordinate(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
