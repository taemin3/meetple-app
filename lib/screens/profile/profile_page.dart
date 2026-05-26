import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../models/auth_session.dart';
import '../../models/auth_user.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/primary_gradient_button.dart';
import '../../widgets/surface_panel.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.authRepository = const MockAuthRepository(),
  });

  final AuthRepository authRepository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<AuthSession?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authRepository != widget.authRepository) {
      _loadSession();
    }
  }

  void _loadSession() {
    _sessionFuture = widget.authRepository.restoreSession();
  }

  void _reloadSession() {
    setState(_loadSession);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthSession?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingView(message: '내 정보를 불러오는 중입니다.');
        }

        if (snapshot.hasError) {
          return AppErrorView(
            message: '내 정보를 불러오지 못했습니다.',
            onRetry: _reloadSession,
          );
        }

        final session = snapshot.data;
        if (session == null) {
          return SignedOutProfile(
            authRepository: widget.authRepository,
            onSignedIn: _showSession,
          );
        }

        return ProfileContent(user: session.user);
      },
    );
  }

  void _showSession(AuthSession session) {
    setState(() {
      _sessionFuture = Future.value(session);
    });
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        ProfileHeader(user: user),
        const SizedBox(height: 24),
        ProfileStatsCard(user: user),
        const SizedBox(height: 18),
        const ProfileMenuGroup(
          items: [
            (Icons.event_available_outlined, '내가 만든 모임'),
            (Icons.group_outlined, '참여 중인 모임'),
            (Icons.favorite_border, '찜한 모임'),
            (Icons.history, '최근 본 모임'),
          ],
        ),
        const SizedBox(height: 18),
        const ProfileMenuGroup(
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
  const ProfileHeader({super.key, required this.user});

  final AuthUser user;

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.nickname,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.handle}',
                style: const TextStyle(
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
  const ProfileStatsCard({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 정보',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ProfileStat(
                  label: '내가 만든 모임',
                  value: user.createdMeetingsCount.toString(),
                ),
              ),
              Expanded(
                child: ProfileStat(
                  label: '참여 중인 모임',
                  value: user.joinedMeetingsCount.toString(),
                ),
              ),
              Expanded(
                child: ProfileStat(
                  label: '찜한 모임',
                  value: user.likedMeetingsCount.toString(),
                ),
              ),
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

class SignedOutProfile extends StatelessWidget {
  const SignedOutProfile({
    super.key,
    required this.authRepository,
    required this.onSignedIn,
  });

  final AuthRepository authRepository;
  final ValueChanged<AuthSession> onSignedIn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        const SizedBox(height: 72),
        const Icon(Icons.person_outline, color: AppColors.primary, size: 58),
        const SizedBox(height: 18),
        const Text(
          '로그인이 필요합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '모임 참여와 마이페이지를 사용하려면 먼저 로그인해 주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 26),
        PrimaryGradientButton(
          label: '로그인하기',
          onPressed: () => _openLogin(context),
        ),
      ],
    );
  }

  Future<void> _openLogin(BuildContext context) async {
    final session = await AppRoutes.openLogin(
      context,
      authRepository: authRepository,
    );

    if (session != null) {
      onSignedIn(session);
    }
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
