import 'package:flutter/material.dart';

import '../core/ui/meetup_style.dart';
import '../models/meetup.dart';

class MeetupPhoto extends StatelessWidget {
  const MeetupPhoto({
    super.key,
    required this.meetup,
    this.height = 120,
    this.borderRadius = 18,
    this.showIcon = true,
  });

  final Meetup meetup;
  final double height;
  final double borderRadius;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final colors = meetupPhotoColors(meetup);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
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
            CustomPaint(painter: MeetupPhotoPainter(meetup: meetup)),
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
                  meetupIcon(meetup),
                  color: Colors.white.withOpacity(0.84),
                  size: height * 0.32,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MeetupPhotoPainter extends CustomPainter {
  MeetupPhotoPainter({required this.meetup});

  final Meetup meetup;

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
  bool shouldRepaint(covariant MeetupPhotoPainter oldDelegate) {
    return oldDelegate.meetup != meetup;
  }
}
