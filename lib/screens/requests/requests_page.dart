import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/section_title.dart';
import '../../widgets/surface_panel.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: const [
        SectionTitle(title: '참여 신청 관리', action: '2건'),
        SizedBox(height: 14),
        RequestCard(
          name: '도윤',
          meeting: '한강 러닝 5km',
          message: '러닝은 처음이지만 꾸준히 참여하고 싶어요.',
          color: AppColors.primary,
        ),
        RequestCard(
          name: '하린',
          meeting: '토요일 알고리즘 스터디',
          message: '자바로 코테 준비 중입니다.',
          color: AppColors.blue,
        ),
      ],
    );
  }
}

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.name,
    required this.meeting,
    required this.message,
    required this.color,
  });

  final String name;
  final String meeting;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfacePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.14),
                  foregroundColor: color,
                  child: Text(name.substring(0, 1)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name 님',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        meeting,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('거절'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('승인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
