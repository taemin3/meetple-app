import 'package:flutter/material.dart';

import '../core/ui/meeting_style.dart';
import '../models/meeting.dart';
import 'loading_skeleton.dart';
import 'network_image_with_skeleton.dart';

class MeetingPhoto extends StatelessWidget {
  const MeetingPhoto({
    super.key,
    required this.meeting,
    this.height = 120,
    this.borderRadius = 18,
    this.showIcon = true,
  });

  final Meeting meeting;
  final double height;
  final double borderRadius;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = meeting.primaryImageUrl;
    final fallback = _MeetingPhotoFallback(
      meeting: meeting,
      height: height,
      showIcon: showIcon,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: imageUrl == null
            ? fallback
            : NetworkImageWithSkeleton(
                imageUrl: imageUrl,
                imageKey: const Key('meeting-photo-network'),
                width: double.infinity,
                height: height,
                fit: BoxFit.cover,
                skeleton: SkeletonBox(
                  key: const Key('meeting-photo-loading-skeleton'),
                  width: double.infinity,
                  height: height,
                  borderRadius: BorderRadius.zero,
                ),
                errorWidget: fallback,
              ),
      ),
    );
  }
}

class _MeetingPhotoFallback extends StatelessWidget {
  const _MeetingPhotoFallback({
    required this.meeting,
    required this.height,
    required this.showIcon,
  });

  final Meeting meeting;
  final double height;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final colors = meetingPhotoColors(meeting);

    return Container(
      key: const Key('meeting-photo-fallback'),
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: MeetingPhotoPainter(meeting: meeting)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),
          if (showIcon)
            Center(
              child: Icon(
                meetingIcon(meeting),
                color: Colors.white.withOpacity(0.84),
                size: height * 0.32,
              ),
            ),
        ],
      ),
    );
  }
}

class MeetingPhotoPainter extends CustomPainter {
  MeetingPhotoPainter({required this.meeting});

  final Meeting meeting;

  @override
  void paint(Canvas canvas, Size size) {
    final sunPaint = Paint()..color = Colors.white.withOpacity(0.22);
    final groundPaint = Paint()..color = Colors.black.withOpacity(0.16);
    final personPaint = Paint()
      ..color = Colors.black.withOpacity(0.34)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
        Offset(size.width * 0.78, size.height * 0.22), 24, sunPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
        const Radius.circular(0),
      ),
      groundPaint,
    );

    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.18 + i * 0.18);
      final y = size.height * (0.58 + (i.isEven ? 0 : 0.05));
      canvas.drawCircle(Offset(x, y - 16), 5, personPaint);
      canvas.drawLine(Offset(x, y - 10), Offset(x, y + 14), personPaint);
      canvas.drawLine(Offset(x, y), Offset(x - 10, y + 12), personPaint);
      canvas.drawLine(Offset(x, y), Offset(x + 11, y + 10), personPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MeetingPhotoPainter oldDelegate) {
    return oldDelegate.meeting != meeting;
  }
}
