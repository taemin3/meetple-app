import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/meeting.dart';
import '../meeting_photo.dart';

class NearbyMeetingMapFallback extends StatelessWidget {
  const NearbyMeetingMapFallback({
    super.key,
    required this.meetings,
    required this.selectedMeeting,
    required this.onMeetingTapped,
    required this.onMeetingGroupTapped,
    required this.onMapTapped,
  });

  final List<Meeting> meetings;
  final Meeting? selectedMeeting;
  final ValueChanged<Meeting> onMeetingTapped;
  final ValueChanged<List<Meeting>> onMeetingGroupTapped;
  final VoidCallback onMapTapped;

  static const _positions = <Alignment>[
    Alignment(-0.68, -0.48),
    Alignment(0.62, -0.34),
    Alignment(-0.20, 0.02),
    Alignment(0.56, 0.40),
    Alignment(-0.62, 0.48),
    Alignment(0.04, 0.72),
  ];

  @override
  Widget build(BuildContext context) {
    final groups = _groupMeetings();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onMapTapped,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFF), Color(0xFFEFF5F2)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _FallbackMapPainter()),
            for (var index = 0; index < groups.length; index++)
              Align(
                alignment: _positions[index % _positions.length],
                child: groups[index].meetings.length == 1
                    ? _FallbackMeetingMarker(
                        meeting: groups[index].meetings.single,
                        selected: _isSelected(groups[index].meetings.single),
                        onTap: () =>
                            onMeetingTapped(groups[index].meetings.single),
                      )
                    : _FallbackMeetingGroupMarker(
                        count: groups[index].meetings.length,
                        onTap: () =>
                            onMeetingGroupTapped(groups[index].meetings),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  List<_FallbackMeetingGroup> _groupMeetings() {
    final groups = <String, List<Meeting>>{};
    for (var index = 0; index < meetings.length; index++) {
      final meeting = meetings[index];
      final latitude = meeting.latitude;
      final longitude = meeting.longitude;
      final key = latitude == null || longitude == null
          ? 'meeting-$index'
          : '${latitude.toStringAsFixed(5)}:'
              '${longitude.toStringAsFixed(5)}';
      groups.putIfAbsent(key, () => <Meeting>[]).add(meeting);
    }
    return groups.values
        .map((meetings) => _FallbackMeetingGroup(meetings))
        .toList(growable: false);
  }

  bool _isSelected(Meeting meeting) {
    final selectedId = selectedMeeting?.id;
    if (selectedId != null) {
      return meeting.id == selectedId;
    }
    return identical(meeting, selectedMeeting);
  }
}

class _FallbackMeetingGroup {
  const _FallbackMeetingGroup(this.meetings);

  final List<Meeting> meetings;
}

class _FallbackMeetingGroupMarker extends StatelessWidget {
  const _FallbackMeetingGroupMarker({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('meeting-group-marker'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
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
          child: Text(
            count > 9 ? '10+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackMeetingMarker extends StatelessWidget {
  const _FallbackMeetingMarker({
    required this.meeting,
    required this.selected,
    required this.onTap,
  });

  final Meeting meeting;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 52 : 42,
          height: selected ? 52 : 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: selected ? AppColors.primary : Colors.white,
              width: selected ? 3 : 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3017151F),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: ClipOval(
            child: MeetingPhoto(
              meeting: meeting,
              height: selected ? 44 : 34,
              borderRadius: 999,
              showIcon: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final river = Paint()..color = const Color(0xFFCFE6FA);
    final park = Paint()..color = const Color(0xFFDCEEDC);
    final majorRoad = Paint()
      ..color = Colors.white.withOpacity(0.96)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final minorRoad = Paint()
      ..color = Colors.white.withOpacity(0.72)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(-20, size.height * 0.48)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.36,
        size.width * 0.54,
        size.height * 0.62,
        size.width + 20,
        size.height * 0.44,
      )
      ..lineTo(size.width + 20, size.height * 0.61)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.76,
        size.width * 0.28,
        size.height * 0.54,
        -20,
        size.height * 0.68,
      )
      ..close();
    canvas.drawPath(riverPath, river);

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.18,
        size.width * 0.28,
        size.height * 0.18,
      ),
      park,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.62,
        size.height * 0.66,
        size.width * 0.30,
        size.height * 0.16,
      ),
      park,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.23),
      Offset(size.width, size.height * 0.34),
      majorRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.32, 0),
      Offset(size.width * 0.48, size.height),
      majorRoad,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.82),
      Offset(size.width, size.height * 0.68),
      majorRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.74, 0),
      Offset(size.width * 0.66, size.height),
      minorRoad,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.40),
      Offset(size.width, size.height * 0.18),
      minorRoad,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
