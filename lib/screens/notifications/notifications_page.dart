import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/section_title.dart';
import '../../widgets/surface_panel.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        '참여 승인',
        '한강 러닝 5km 참여가 승인되었습니다.',
        Icons.check_circle_outline,
        AppColors.primary
      ),
      ('새 신청', '도윤 님이 모임 참여를 신청했습니다.', Icons.person_add_alt, AppColors.blue),
      (
        '채팅',
        '필름 카메라 산책 채팅방에 새 메시지가 있습니다.',
        Icons.chat_bubble_outline,
        AppColors.orange
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        const SectionTitle(title: '알림', action: '3개'),
        const SizedBox(height: 14),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfacePanel(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: item.$4.withOpacity(0.12),
                    foregroundColor: item.$4,
                    child: Icon(item.$3, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
