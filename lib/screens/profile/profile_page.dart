import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/auth_session.dart';
import '../../models/auth_user.dart';
import '../../models/meeting.dart';
import '../../models/meeting_list_filter.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/surface_panel.dart';
import '../auth/auth_form_widgets.dart';
import '../notifications/notifications_page.dart';
import 'bookmarked_meetings_page.dart';
import 'my_applications_page.dart';
import 'my_meetings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.authRepository,
    this.meetingRepository = const MockMeetingRepository(),
    this.isActive = true,
    this.onSignedOut,
    this.onMeetingChanged,
  });

  final AuthRepository? authRepository;
  final MeetingRepository meetingRepository;
  final bool isActive;
  final VoidCallback? onSignedOut;
  final VoidCallback? onMeetingChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<AuthSession?> _sessionFuture;
  late AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? MockAuthRepository();
    _loadSession(forceRefresh: widget.isActive);
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authRepository != widget.authRepository &&
        widget.authRepository != null) {
      _authRepository = widget.authRepository!;
      _loadSession(forceRefresh: widget.isActive);
    } else if (!oldWidget.isActive && widget.isActive) {
      _reloadSession(forceRefresh: true);
    }
  }

  void _loadSession({bool forceRefresh = false}) {
    _sessionFuture = forceRefresh
        ? _authRepository.refreshSession()
        : _authRepository.restoreSession();
  }

  void _reloadSession({bool forceRefresh = false}) {
    setState(() => _loadSession(forceRefresh: forceRefresh));
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
            authRepository: _authRepository,
            onSignedIn: _showSession,
          );
        }

        return ProfileContent(
          user: session.user,
          authRepository: _authRepository,
          meetingRepository: widget.meetingRepository,
          onSignedOut: _showSignedOut,
          onMeetingChanged: widget.onMeetingChanged,
        );
      },
    );
  }

  void _showSession(AuthSession session) {
    setState(() {
      _sessionFuture = Future.value(session);
    });
  }

  void _showSignedOut() {
    setState(() {
      _sessionFuture = Future.value(null);
    });
    widget.onSignedOut?.call();
  }
}

class ProfileContent extends StatefulWidget {
  const ProfileContent({
    super.key,
    required this.user,
    required this.authRepository,
    required this.meetingRepository,
    required this.onSignedOut,
    this.onMeetingChanged,
  });

  final AuthUser user;
  final AuthRepository authRepository;
  final MeetingRepository meetingRepository;
  final VoidCallback onSignedOut;
  final VoidCallback? onMeetingChanged;

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        ProfileHeader(user: widget.user),
        const SizedBox(height: 24),
        ProfileStatsCard(user: widget.user),
        const SizedBox(height: 18),
        ProfileMenuGroup(
          items: [
            (
              Icons.event_available_outlined,
              '내가 만든 모임',
              () => _openMeetings(
                    title: '내가 만든 모임',
                    emptyMessage: '아직 만든 모임이 없습니다.',
                    loader: widget.meetingRepository.getHostedMeetings,
                    filters: const [
                      MeetingListFilter.all,
                      MeetingListFilter.ongoing,
                      MeetingListFilter.ended,
                    ],
                  ),
            ),
            (
              Icons.group_outlined,
              '참여 중인 모임',
              () => _openMeetings(
                    title: '참여 중인 모임',
                    emptyMessage: '참여한 모임이 없습니다.',
                    loader: widget.meetingRepository.getJoinedMeetings,
                    filters: const [
                      MeetingListFilter.all,
                      MeetingListFilter.ended,
                    ],
                  ),
            ),
            (
              Icons.assignment_outlined,
              '내 신청 내역',
              () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => MyApplicationsPage(
                        meetingRepository: widget.meetingRepository,
                      ),
                    ),
                  ),
            ),
            (
              Icons.favorite_border,
              '찜한 모임',
              () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => BookmarkedMeetingsPage(
                        meetingRepository: widget.meetingRepository,
                      ),
                    ),
                  ),
            ),
            (Icons.history, '최근 본 모임', null),
          ],
        ),
        const SizedBox(height: 18),
        ProfileMenuGroup(
          items: [
            (
              Icons.notifications_none_rounded,
              '알림',
              () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => NotificationsPage(
                        meetingRepository: widget.meetingRepository,
                        onMeetingChanged: widget.onMeetingChanged,
                      ),
                    ),
                  ),
            ),
            (Icons.settings_outlined, '설정', null),
            (Icons.support_agent, '고객센터', null),
          ],
        ),
        const SizedBox(height: 18),
        SurfacePanel(
          child: ProfileMenuItem(
            key: const Key('profile_sign_out'),
            icon: Icons.logout_rounded,
            label: _isSigningOut
                ? '\uB85C\uADF8\uC544\uC6C3 \uC911...'
                : '\uB85C\uADF8\uC544\uC6C3',
            foregroundColor: AppColors.error,
            showChevron: false,
            trailing: _isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _isSigningOut ? null : _signOut,
          ),
        ),
      ],
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(() => _isSigningOut = true);

    Exception? signOutError;
    try {
      await widget.authRepository.signOut();
    } on Exception catch (error) {
      signOutError = error;
    }

    if (!mounted) {
      return;
    }

    if (signOutError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(signOutError))),
      );
    }

    widget.onSignedOut();
  }

  void _openMeetings({
    required String title,
    required String emptyMessage,
    required Future<List<Meeting>> Function() loader,
    required List<MeetingListFilter> filters,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MyMeetingsPage(
          title: title,
          emptyMessage: emptyMessage,
          meetingRepository: widget.meetingRepository,
          loader: loader,
          filters: filters,
        ),
      ),
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
        PrimaryButton(
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

  final List<(IconData, String, VoidCallback?)> items;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ProfileMenuItem(
              icon: items[i].$1,
              label: items[i].$2,
              onTap: items[i].$3,
            ),
            if (i != items.length - 1)
              const Divider(height: 22, color: AppColors.line),
          ],
        ],
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.foregroundColor,
    this.showChevron = true,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? foregroundColor;
  final bool showChevron;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textColor = foregroundColor ?? AppColors.ink;
    final iconColor = foregroundColor ?? AppColors.primary;
    final row = Row(
      children: [
        Icon(icon, color: iconColor, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (showChevron)
          const Icon(Icons.chevron_right, color: AppColors.subtle),
      ],
    );

    if (onTap == null) {
      return row;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: row,
      ),
    );
  }
}
