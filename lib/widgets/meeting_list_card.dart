import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/ui/meeting_style.dart';
import '../models/meeting.dart';
import 'category_pill.dart';
import 'meeting_photo.dart';

class MeetingListCard extends StatelessWidget {
  const MeetingListCard({
    super.key,
    required this.meeting,
    required this.onTap,
    this.trailing,
    this.showDistance = false,
  });

  final Meeting meeting;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    final endAdornment =
        trailing ?? const Icon(Icons.bookmark_border, color: AppColors.subtle);

    return LayoutBuilder(
      builder: (context, constraints) {
        final photoWidth = (constraints.maxWidth * 0.38).clamp(92.0, 136.0);

        return Material(
          color: Colors.white,
          elevation: 1,
          shadowColor: const Color(0x18000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE9E9ED)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: photoWidth,
                    child: MeetingPhoto(
                      meeting: meeting,
                      height: 112,
                      borderRadius: 12,
                      showIcon: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CategoryPill(
                              label: meeting.category,
                              color: meetingAccent(meeting),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: endAdornment,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          meeting.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (showDistance &&
                            meeting.distance.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            meeting.distance,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        SizedBox(height: showDistance ? 14 : 28),
                        _MeetingCardMeta(
                          icon: Icons.calendar_today_outlined,
                          text: '${meeting.date} ${meeting.time}',
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: _MeetingCardMeta(
                                icon: Icons.location_on_outlined,
                                text: meeting.area,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _MeetingCardMeta(
                              icon: Icons.people_alt_outlined,
                              text: '${meeting.joined}/${meeting.capacity}명',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MeetingCardMeta extends StatelessWidget {
  const _MeetingCardMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
