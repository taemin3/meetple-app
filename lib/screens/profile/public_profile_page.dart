import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/moderation_repository.dart';
import '../../models/moderation.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/network_image_with_skeleton.dart';
import '../moderation/report_sheet.dart';

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({
    super.key,
    required this.memberId,
    required this.currentMemberId,
    required this.moderationRepository,
  });

  final int memberId;
  final int currentMemberId;
  final ModerationRepository moderationRepository;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late Future<PublicMemberProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.moderationRepository.getPublicProfile(widget.memberId);
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.memberId == widget.currentMemberId;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: '프로필',
              trailing: isMine
                  ? null
                  : PopupMenuButton<String>(
                      key: const Key('public-profile-more'),
                      onSelected: _handleAction,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'report', child: Text('사용자 신고')),
                      ],
                    ),
            ),
            Expanded(
              child: FutureBuilder<PublicMemberProfile>(
                future: _profile,
                builder: (context, snapshot) {
                  if (!snapshot.hasData &&
                      snapshot.connectionState != ConnectionState.done) {
                    return const AppLoadingView(message: '프로필을 불러오는 중입니다.');
                  }
                  if (snapshot.hasError) {
                    return AppErrorView(
                      message: snapshot.error is ApiException
                          ? (snapshot.error! as ApiException).message
                          : '프로필을 불러오지 못했습니다.',
                      onRetry: () => setState(() => _profile = widget
                          .moderationRepository
                          .getPublicProfile(widget.memberId)),
                    );
                  }
                  final profile = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _ProfileAvatar(profile: profile),
                        const SizedBox(height: 18),
                        Text(profile.nickname,
                            key: const Key('public-profile-nickname'),
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Text(
                            profile.introduction?.trim().isNotEmpty == true
                                ? profile.introduction!.trim()
                                : '작성한 자기소개가 없습니다.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 15,
                                height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(String action) async {
    if (action == 'report') {
      await showReportSheet(context,
          repository: widget.moderationRepository,
          targetType: ReportTargetType.member,
          targetId: widget.memberId);
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});
  final PublicMemberProfile profile;
  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
        radius: 52,
        backgroundColor: AppColors.softSurface,
        child: Text(
            profile.nickname.isEmpty ? 'M' : profile.nickname.characters.first,
            style: const TextStyle(
                fontSize: 32,
                color: AppColors.primary,
                fontWeight: FontWeight.w900)));
    final url = profile.profileImageUrl;
    return SizedBox.square(
        dimension: 104,
        child: url == null
            ? fallback
            : ClipOval(
                child: NetworkImageWithSkeleton(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    skeleton: fallback,
                    errorWidget: fallback),
              ));
  }
}
