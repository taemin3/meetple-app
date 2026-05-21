import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/meetup.dart';

class CapacityBar extends StatelessWidget {
  const CapacityBar({
    super.key,
    required this.meetup,
    required this.color,
  });

  final Meetup meetup;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = meetup.joined / meetup.capacity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '참여 ${meetup.joined}/${meetup.capacity}명',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '모임장 ${meetup.host}',
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
