import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/meeting.dart';

class CapacityBar extends StatelessWidget {
  const CapacityBar({
    super.key,
    required this.meeting,
    required this.color,
  });

  final Meeting meeting;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = meeting.joined / meeting.capacity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '참여 ${meeting.joined}/${meeting.capacity}명',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '모임장 ${meeting.host}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: progress,
            backgroundColor: const Color(0xFFECEFE8),
            color: color,
          ),
        ),
      ],
    );
  }
}
