import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/surface_panel.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: const [
        ProfileHeader(),
        SizedBox(height: 24),
        ProfileStatsCard(),
        SizedBox(height: 18),
        ProfileMenuGroup(
          items: [
            (Icons.event_available_outlined, '내가 만든 모임'),
            (Icons.group_outlined, '참여 중인 모임'),
            (Icons.favorite_border, '찜한 모임'),
            (Icons.history, '최근 본 모임'),
          ],
        ),
        SizedBox(height: 18),
        ProfileMenuGroup(
          items: [
            (Icons.notifications_none_rounded, '알림'),
            (Icons.settings_outlined, '설정'),
            (Icons.support_agent, '고객센터'),
          ],
        ),
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.softSurface,
          child: Icon(Icons.person, color: AppColors.primary, size: 34),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '김모임',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '@gather_together',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 정보',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: ProfileStat(label: '내가 만든 모임', value: '12')),
              Expanded(child: ProfileStat(label: '참여 중인 모임', value: '28')),
              Expanded(child: ProfileStat(label: '찜한 모임', value: '15')),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class ProfileMenuGroup extends StatelessWidget {
  const ProfileMenuGroup({super.key, required this.items});

  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ProfileMenuItem(icon: items[i].$1, label: items[i].$2),
            if (i != items.length - 1)
              const Divider(height: 22, color: AppColors.line),
          ],
        ],
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.subtle),
      ],
    );
  }
}
