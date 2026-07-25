import 'package:flutter/material.dart';

class MeetingLocationMapFallback extends StatelessWidget {
  const MeetingLocationMapFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      key: Key('meeting-location-map-fallback'),
      painter: _MeetingLocationMapPainter(),
    );
  }
}

class _MeetingLocationMapPainter extends CustomPainter {
  const _MeetingLocationMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFF2F6F2);
    final water = Paint()..color = const Color(0xFFCDE7F8);
    final park = Paint()..color = const Color(0xFFDCEFD6);
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final smallRoad = Paint()
      ..color = Colors.white.withOpacity(0.72)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(Offset.zero & size, background);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.05,
        0,
        size.width * 0.78,
        size.height * 0.68,
      ),
      park,
    );

    final waterPath = Path()
      ..moveTo(size.width * 0.72, -10)
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.48,
        size.width + 20,
        size.height * 0.38,
      )
      ..lineTo(size.width + 20, -10)
      ..close();
    canvas.drawPath(waterPath, water);

    canvas.drawLine(
      Offset(-10, size.height * 0.78),
      Offset(size.width + 10, size.height * 0.34),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.24, -10),
      Offset(size.width * 0.44, size.height + 10),
      road,
    );
    canvas.drawLine(
      Offset(-10, size.height * 0.30),
      Offset(size.width + 10, size.height * 0.62),
      smallRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, -10),
      Offset(size.width * 0.58, size.height + 10),
      smallRoad,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
