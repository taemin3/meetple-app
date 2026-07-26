import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/meeting.dart';
import '../../models/meeting_engagement.dart';
import '../requests/meeting_participation_management_page.dart';
import 'meeting_edit_page.dart';
import '../../widgets/map/meeting_location_map.dart';
import '../../widgets/meeting_photo.dart';
import '../../widgets/primary_gradient_button.dart';

class MeetingDetailPage extends StatefulWidget {
  const MeetingDetailPage({
    super.key,
    required this.meeting,
    this.meetingRepository = const MockMeetingRepository(),
  });

  final Meeting meeting;
  final MeetingRepository meetingRepository;

  @override
  State<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends State<MeetingDetailPage> {
  MeetingEngagement? _engagement;
  bool _isLoading = true;
  bool _engagementLoadFailed = false;
  bool _isBusy = false;
  bool _isFavoriteBusy = false;

  bool get _isClosed =>
      widget.meeting.status == 'COMPLETED' ||
      widget.meeting.status == 'CANCELED';

  @override
  void initState() {
    super.initState();
    _loadEngagement();
  }

  Future<void> _loadEngagement() async {
    setState(() {
      _isLoading = true;
      _engagementLoadFailed = false;
    });
    final meetingId = widget.meeting.id;
    if (meetingId == null) {
      setState(() {
        _engagement = const MeetingEngagement(
          isHost: false,
          isBookmarked: false,
        );
        _isLoading = false;
      });
      return;
    }

    try {
      final engagement =
          await widget.meetingRepository.getEngagement(meetingId);
      if (!mounted) return;
      setState(() {
        _engagement = engagement;
        _isLoading = false;
        _engagementLoadFailed = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _engagement = null;
        _isLoading = false;
        _engagementLoadFailed = true;
      });
      _showError(error);
    }
  }

  Future<void> _toggleFavorite() async {
    final meetingId = widget.meeting.id;
    final engagement = _engagement;
    if (meetingId == null ||
        engagement == null ||
        engagement.isHost ||
        _isFavoriteBusy) {
      return;
    }

    final next = !engagement.isBookmarked;
    setState(() {
      _engagement = engagement.copyWith(isBookmarked: next);
      _isFavoriteBusy = true;
    });
    try {
      await widget.meetingRepository.setBookmarked(meetingId, next);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _engagement = engagement;
      });
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isFavoriteBusy = false);
      }
    }
  }

  Future<void> _requestParticipation() async {
    final meetingId = widget.meeting.id;
    if (meetingId == null || _isBusy) return;

    final controller = TextEditingController();
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '참여 신청',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('모임장에게 전할 메시지가 있다면 적어주세요. (선택)'),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLength: 500,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '신청 메시지를 입력해 주세요.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('신청하기'),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (message == null || !mounted) return;

    await _runAction(() async {
      final participation = await widget.meetingRepository.applyParticipation(
        meetingId,
        message: message,
      );
      _engagement = _engagement?.copyWith(participation: participation);
    }, successMessage: '참여 신청이 전송되었습니다.');
  }

  Future<void> _cancelParticipation() async {
    final participation = _engagement?.participation;
    final meetingId = widget.meeting.id;
    if (participation == null || meetingId == null) return;

    if (participation.status == ParticipationStatus.approved) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('참여를 취소할까요?'),
          content: const Text('승인된 참여를 취소하면 참여 인원에서 제외됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('아니요'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('참여 취소'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    await _runAction(() async {
      final canceled = await widget.meetingRepository.cancelParticipation(
        meetingId,
        participation.id,
      );
      _engagement = _engagement?.copyWith(participation: canceled);
    }, successMessage: '참여 신청이 취소되었습니다.');
  }

  Future<void> _openParticipationManagement() async {
    final meetingId = widget.meeting.id;
    if (meetingId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MeetingParticipationManagementPage(
          meeting: widget.meeting,
          meetingRepository: widget.meetingRepository,
        ),
      ),
    );
    await _loadEngagement();
  }

  Future<void> _openEditMeeting() async {
    final updated = await Navigator.of(context).push<Meeting>(
      MaterialPageRoute(
        builder: (_) => MeetingEditPage(
          meeting: widget.meeting,
          meetingRepository: widget.meetingRepository,
        ),
      ),
    );
    if (updated != null && mounted) {
      Navigator.of(context).pop(updated);
    }
  }

  Future<void> _showHostMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('모임 완료'),
              onTap: () => Navigator.of(context).pop('complete'),
            ),
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: const Text('모임 취소'),
              onTap: () => Navigator.of(context).pop('cancel'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('모임 삭제'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'complete':
        final succeeded = await _runAction(
          () => widget.meetingRepository.completeMeeting(widget.meeting.id!),
          successMessage: '모임을 완료 처리했습니다.',
        );
        if (succeeded && mounted) {
          Navigator.of(context).pop(
            widget.meeting.copyWith(status: 'COMPLETED'),
          );
        }
      case 'cancel':
        await _cancelMeeting();
      case 'delete':
        await _deleteMeeting();
    }
  }

  Future<void> _cancelMeeting() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모임 취소 사유'),
        content: TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 4,
          decoration: const InputDecoration(hintText: '참여자에게 보여줄 사유를 입력해 주세요.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('모임 취소'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    final succeeded = await _runAction(
      () => widget.meetingRepository.cancelMeeting(widget.meeting.id!, reason),
      successMessage: '모임을 취소했습니다.',
    );
    if (succeeded && mounted) {
      Navigator.of(context).pop(
        widget.meeting.copyWith(
          status: 'CANCELED',
          cancelReason: reason,
        ),
      );
    }
  }

  Future<void> _deleteMeeting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모임을 삭제할까요?'),
        content: const Text('참여 신청 내역이 없는 모집 중 모임만 삭제할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니요'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final succeeded = await _runAction(
      () => widget.meetingRepository.deleteMeeting(widget.meeting.id!),
      successMessage: '모임을 삭제했습니다.',
    );
    if (succeeded && mounted) Navigator.of(context).pop(true);
  }

  Future<bool> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_isBusy) return false;
    setState(() => _isBusy = true);
    try {
      await action();
      if (!mounted) return true;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
      return true;
    } on Exception catch (error) {
      if (mounted) _showError(error);
      return false;
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _showError(Object error) {
    final message = error is ApiException ? error.message : '요청을 처리하지 못했습니다.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;
    final engagement = _engagement;
    final isHost = engagement?.isHost == true;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              DetailHero(meeting: meeting),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MeetingMetaSummary(meeting: meeting),
                    const SizedBox(height: 24),
                    MeetingInfoSection(meeting: meeting),
                    const SizedBox(height: 28),
                    const DetailSectionTitle('모임 소개'),
                    const SizedBox(height: 10),
                    Text(
                      meeting.description,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        height: 1.65,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const DetailSectionTitle('모임장'),
                    const SizedBox(height: 12),
                    HostProfileCard(meeting: meeting),
                    const SizedBox(height: 28),
                    const DetailSectionTitle('모임 위치'),
                    const SizedBox(height: 12),
                    MeetingLocationCard(meeting: meeting),
                    const SizedBox(height: 28),
                    const DetailSectionTitle('참여 멤버'),
                    const SizedBox(height: 14),
                    MemberAvatars(
                      meeting: meeting,
                      members: engagement?.members ?? const [],
                    ),
                  ],
                ),
              ),
            ],
          ),
          DetailFloatingHeader(
            isFavorite: engagement?.isBookmarked == true,
            isHost: isHost,
            showAction: engagement != null && (!isHost || !_isClosed),
            onFavoritePressed: _isFavoriteBusy ? null : _toggleFavorite,
            onHostMenuPressed: _isBusy ? null : _showHostMenu,
          ),
        ],
      ),
      bottomNavigationBar: _isLoading
          ? const SizedBox(height: 84)
          : _engagementLoadFailed
              ? DetailUnavailableBottomBar(
                  label: '참여 상태를 불러오지 못했습니다.',
                  actionLabel: '다시 시도',
                  onPressed: _loadEngagement,
                )
              : isHost
                  ? _isClosed
                      ? const DetailUnavailableBottomBar(
                          label: '종료된 모임은 관리할 수 없습니다.',
                        )
                      : HostDetailBottomBar(
                          onEditPressed: _isBusy ? null : _openEditMeeting,
                          onManagePressed:
                              _isBusy ? null : _openParticipationManagement,
                        )
                  : DetailBottomBar(
                      isFavorite: engagement?.isBookmarked == true,
                      onFavoritePressed:
                          _isFavoriteBusy ? null : _toggleFavorite,
                      participationLabel: _participationLabel,
                      onParticipationPressed: _participationAction,
                      isBusy: _isBusy,
                    ),
    );
  }

  String get _participationLabel {
    switch (_engagement?.participation?.status) {
      case ParticipationStatus.pending:
        return '승인 대기 중 · 신청 취소';
      case ParticipationStatus.approved:
        return '참여 확정 · 참여 취소';
      case ParticipationStatus.rejected:
        return '참여 신청이 거절되었습니다';
      case ParticipationStatus.canceled:
      case null:
        if (widget.meeting.status == 'FULL') return '모집 마감';
        if (widget.meeting.status == 'COMPLETED') return '완료된 모임';
        if (widget.meeting.status == 'CANCELED') return '취소된 모임';
        return '참여 신청하기';
    }
  }

  VoidCallback? get _participationAction {
    if (_isBusy) return null;
    final status = _engagement?.participation?.status;
    if (status == ParticipationStatus.pending ||
        status == ParticipationStatus.approved) {
      return _cancelParticipation;
    }
    if (status == ParticipationStatus.rejected ||
        widget.meeting.status == 'FULL' ||
        widget.meeting.status == 'COMPLETED' ||
        widget.meeting.status == 'CANCELED') {
      return null;
    }
    return _requestParticipation;
  }
}

class DetailHero extends StatelessWidget {
  const DetailHero({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MeetingPhoto(
            meeting: meeting,
            height: 300,
            borderRadius: 0,
            showIcon: false,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.36),
                  Colors.transparent,
                  Colors.black.withOpacity(0.72),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in meeting.tags.take(2))
                      HeroTagPill(label: tag),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  meeting.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailFloatingHeader extends StatelessWidget {
  const DetailFloatingHeader({
    super.key,
    required this.isFavorite,
    required this.isHost,
    required this.showAction,
    required this.onFavoritePressed,
    required this.onHostMenuPressed,
  });

  final bool isFavorite;
  final bool isHost;
  final bool showAction;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onHostMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x73000000), Color(0x00000000)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Row(
              children: [
                TransparentHeroIconButton(
                  key: const Key('meeting-detail-back-button'),
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: '뒤로가기',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                if (showAction)
                  TransparentHeroIconButton(
                    key: const Key('meeting-detail-hero-favorite-button'),
                    icon: isHost
                        ? Icons.more_vert_rounded
                        : isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                    tooltip: isHost ? '모임 관리' : '찜하기',
                    onPressed: isHost ? onHostMenuPressed : onFavoritePressed,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TransparentHeroIconButton extends StatelessWidget {
  const TransparentHeroIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white54,
        shadowColor: Colors.transparent,
      ),
      icon: Icon(
        icon,
        color: Colors.white,
        shadows: const [
          Shadow(
            color: Color(0x99000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class HeroTagPill extends StatelessWidget {
  const HeroTagPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          '#$label',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class MeetingMetaSummary extends StatelessWidget {
  const MeetingMetaSummary({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          color: AppColors.muted,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${meeting.date} · ${meeting.time}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(Icons.star_rounded, color: AppColors.orange, size: 18),
        const SizedBox(width: 4),
        Text(
          meeting.reviewCount == 0
              ? '후기 없음'
              : '${meeting.rating} (${meeting.reviewCount})',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class MeetingInfoSection extends StatelessWidget {
  const MeetingInfoSection({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DetailSectionTitle('모임 정보'),
        const SizedBox(height: 14),
        DetailInfoItem(
          icon: Icons.schedule_rounded,
          label: '일시',
          value: '${meeting.date}  ${meeting.time}',
        ),
        DetailInfoItem(
          icon: Icons.location_on_outlined,
          label: '장소',
          value: meeting.area,
          supportingText: meeting.address,
        ),
        DetailInfoItem(
          icon: Icons.group_outlined,
          label: '모집 인원',
          value: '${meeting.joined} / ${meeting.capacity}명',
        ),
        DetailInfoItem(
          icon: Icons.payments_outlined,
          label: '참가비',
          value: meeting.fee,
        ),
      ],
    );
  }
}

class DetailInfoItem extends StatelessWidget {
  const DetailInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.supportingText,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final normalizedSupportingText = supportingText?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Icon(icon, color: AppColors.muted, size: 18),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 66,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (normalizedSupportingText != null &&
                    normalizedSupportingText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    normalizedSupportingText,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailSectionTitle extends StatelessWidget {
  const DetailSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class HostProfileCard extends StatelessWidget {
  const HostProfileCard({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: detailCardDecoration,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.softSurface,
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '모임장',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        meeting.host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '함께 즐거운 모임을 만들어가요.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      meeting.reviewCount == 0
                          ? '아직 받은 후기가 없어요'
                          : '평점 ${meeting.rating} · 후기 ${meeting.reviewCount}개',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모임장 프로필은 준비 중입니다.')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.muted,
              side: const BorderSide(color: AppColors.line),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '프로필 보기',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class MeetingLocationCard extends StatelessWidget {
  const MeetingLocationCard({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: detailCardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 148,
          child: Stack(
            key: const Key('meeting-location-preview'),
            fit: StackFit.expand,
            children: [
              MeetingLocationMap(
                enabled: _isLiveMapEnabled,
                latitude: _latitude,
                longitude: _longitude,
              ),
              Align(
                alignment: const Alignment(0, -0.16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 38,
                    ),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 190),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2417151F),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        meeting.address?.trim().isNotEmpty == true
                            ? meeting.address!
                            : meeting.area,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: FilledButton(
                  key: const Key('meeting-location-full-map-button'),
                  onPressed: () => _showFullMap(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
                    elevation: 2,
                    shadowColor: const Color(0x3217151F),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '지도 전체보기',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_new_rounded, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullMap(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final sheetHeight = math.min(
          MediaQuery.sizeOf(context).height * 0.72,
          560.0,
        );

        return SafeArea(
          top: false,
          child: SizedBox(
            height: sheetHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DetailSectionTitle('모임 위치'),
                  const SizedBox(height: 6),
                  Text(
                    meeting.address?.trim().isNotEmpty == true
                        ? meeting.address!
                        : meeting.area,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MeetingLocationMap(
                            enabled: _isLiveMapEnabled,
                            latitude: _latitude,
                            longitude: _longitude,
                          ),
                          const Center(
                            child: Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: 48,
                            ),
                          ),
                        ],
                      ),
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

  bool get _isLiveMapEnabled =>
      AppConfig.hasNaverMapClientId &&
      isMeetingLocationMapSupported &&
      meeting.hasCoordinate;

  double get _latitude => meeting.latitude ?? 37.5283;

  double get _longitude => meeting.longitude ?? 126.9326;
}

class MemberAvatars extends StatelessWidget {
  const MemberAvatars({
    super.key,
    required this.meeting,
    this.members = const [],
  });

  final Meeting meeting;
  final List<MeetingMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty && meeting.joined <= 0) {
      return const Text(
        '아직 참여한 멤버가 없습니다.',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final colors = [
      AppColors.primary,
      AppColors.orange,
      AppColors.blue,
      AppColors.mint,
    ];
    final memberCount = members.isEmpty ? meeting.joined : members.length;
    final visibleCount = math.min(memberCount, 5);
    final remainingCount = memberCount - visibleCount;

    return Row(
      children: [
        for (var index = 0; index < visibleCount; index++) ...[
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[index % colors.length].withOpacity(0.14),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1817151F),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: members.isNotEmpty &&
                    members[index].profileImageUrl?.isNotEmpty == true
                ? ClipOval(
                    child: Image.network(
                      members[index].profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        members[index].isHost
                            ? Icons.workspace_premium_rounded
                            : Icons.person_rounded,
                        color: colors[index % colors.length],
                        size: 21,
                      ),
                    ),
                  )
                : Icon(
                    members.isNotEmpty && members[index].isHost
                        ? Icons.workspace_premium_rounded
                        : Icons.person_rounded,
                    color: colors[index % colors.length],
                    size: 21,
                  ),
          ),
        ],
        if (remainingCount > 0)
          Text(
            '+$remainingCount',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onParticipationPressed,
    required this.participationLabel,
    this.isBusy = false,
  });

  final bool isFavorite;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onParticipationPressed;
  final String participationLabel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1417151F),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 56,
              child: OutlinedButton(
                key: const Key('meeting-detail-bottom-favorite-button'),
                onPressed: onFavoritePressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.line),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Icon(
                  isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 23,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryGradientButton(
                label: isBusy ? '처리 중...' : participationLabel,
                onPressed: onParticipationPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HostDetailBottomBar extends StatelessWidget {
  const HostDetailBottomBar({
    super.key,
    required this.onEditPressed,
    required this.onManagePressed,
  });

  final VoidCallback? onEditPressed;
  final VoidCallback? onManagePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: onEditPressed,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('수정'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryGradientButton(
                label: '참여 신청 관리',
                onPressed: onManagePressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailUnavailableBottomBar extends StatelessWidget {
  const DetailUnavailableBottomBar({
    super.key,
    required this.label,
    this.actionLabel,
    this.onPressed,
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const detailCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(18)),
  border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
  boxShadow: [
    BoxShadow(
      color: Color(0x1017151F),
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ],
);
