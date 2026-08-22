import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/image_upload_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/meeting.dart';
import '../../models/meeting_engagement.dart';
import '../requests/meeting_participation_management_page.dart';
import 'meeting_edit_page.dart';
import '../../widgets/map/meeting_location_map.dart';
import '../../widgets/meeting_image_gallery.dart';
import '../../widgets/network_image_with_skeleton.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

part 'widgets/meeting_detail_bottom_bars.dart';

class MeetingDetailPage extends StatefulWidget {
  const MeetingDetailPage({
    super.key,
    required this.meeting,
    this.meetingRepository = const MockMeetingRepository(),
    this.categoryRepository,
    this.locationRepository,
    this.imageUploadRepository,
  });

  final Meeting meeting;
  final MeetingRepository meetingRepository;
  final CategoryRepository? categoryRepository;
  final LocationRepository? locationRepository;
  final ImageUploadRepository? imageUploadRepository;

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

    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ParticipationRequestSheet(),
    );
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
    final wasApproved = participation.status == ParticipationStatus.approved;

    if (wasApproved) {
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
      final engagement = _engagement;
      _engagement = engagement?.copyWith(
        participation: canceled,
        members: wasApproved
            ? engagement.members
                .where((member) => member.memberId != participation.memberId)
                .toList(growable: false)
            : engagement.members,
      );
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
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final meetingId = widget.meeting.id;
      final meeting = meetingId == null
          ? widget.meeting
          : await widget.meetingRepository.findById(meetingId);
      if (!mounted) return;

      final updated = await Navigator.of(context).push<Meeting>(
        MaterialPageRoute(
          builder: (_) => MeetingEditPage(
            meeting: meeting,
            meetingRepository: widget.meetingRepository,
            categoryRepository: widget.categoryRepository,
            locationRepository: widget.locationRepository,
            imageUploadRepository: widget.imageUploadRepository,
          ),
        ),
      );
      if (updated != null && mounted) {
        Navigator.of(context).pop(updated);
      }
    } on Exception catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
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
    final joined = engagement != null && engagement.members.isNotEmpty
        ? engagement.members.length
        : meeting.joined;

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
                    MeetingInfoSection(meeting: meeting, joined: joined),
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
                    HostInfoCard(meeting: meeting),
                    const SizedBox(height: 28),
                    const DetailSectionTitle('모임 위치'),
                    const SizedBox(height: 12),
                    MeetingLocationCard(meeting: meeting),
                    const SizedBox(height: 28),
                    MeetingMembersSection(
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

class _ParticipationRequestSheet extends StatefulWidget {
  const _ParticipationRequestSheet();

  @override
  State<_ParticipationRequestSheet> createState() =>
      _ParticipationRequestSheetState();
}

class _ParticipationRequestSheetState
    extends State<_ParticipationRequestSheet> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(_messageController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            controller: _messageController,
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
              onPressed: _submit,
              child: const Text('신청하기'),
            ),
          ),
        ],
      ),
    );
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
          MeetingImageGallery(
            meeting: meeting,
            height: 300,
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.36),
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 76,
            bottom: 22,
            child: IgnorePointer(
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

class MeetingInfoSection extends StatelessWidget {
  const MeetingInfoSection({super.key, required this.meeting, this.joined});

  final Meeting meeting;
  final int? joined;

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
          value: _meetingScheduleLabel(meeting),
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
          value: '${joined ?? meeting.joined} / ${meeting.capacity}명',
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

String _meetingScheduleLabel(Meeting meeting) {
  final scheduledAt = meeting.scheduledAt?.toLocal();
  if (scheduledAt == null) {
    return '${meeting.date} ${meeting.time}';
  }

  final startLabel =
      '${scheduledAt.month}/${scheduledAt.day} ${_twoDigits(scheduledAt.hour)}:${_twoDigits(scheduledAt.minute)}';
  final endsAt = meeting.endsAt?.toLocal();
  if (endsAt == null) {
    return '$startLabel 시작 · 종료 미정';
  }

  final endTime = '${_twoDigits(endsAt.hour)}:${_twoDigits(endsAt.minute)}';
  if (_isSameDate(scheduledAt, endsAt)) {
    return '$startLabel ~ $endTime';
  }
  return '$startLabel ~ ${endsAt.month}/${endsAt.day} $endTime';
}

bool _isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

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

class HostInfoCard extends StatelessWidget {
  const HostInfoCard({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = meeting.hostProfileImageUrl?.trim();
    final introduction = meeting.hostIntroduction?.trim();
    const avatarPlaceholder = CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.softSurface,
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: 30,
      ),
    );

    return Container(
      key: const Key('meeting-host-info-card'),
      padding: const EdgeInsets.all(16),
      decoration: detailCardDecoration,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: profileImageUrl == null || profileImageUrl.isEmpty
                    ? const KeyedSubtree(
                        key: Key('meeting-host-profile-placeholder'),
                        child: avatarPlaceholder,
                      )
                    : ClipOval(
                        child: NetworkImageWithSkeleton(
                          imageKey: const Key('meeting-host-profile-image'),
                          imageUrl: profileImageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          cacheWidth: 168,
                          cacheHeight: 168,
                          skeleton: avatarPlaceholder,
                          errorWidget: avatarPlaceholder,
                        ),
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
                if (introduction != null && introduction.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    introduction,
                    key: const Key('meeting-host-introduction'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
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
                interactive: false,
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
                            interactive: true,
                            showMarker: true,
                          ),
                          if (!_isLiveMapEnabled)
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

class MeetingMembersSection extends StatelessWidget {
  const MeetingMembersSection({
    super.key,
    required this.meeting,
    this.members = const [],
  });

  final Meeting meeting;
  final List<MeetingMember> members;

  @override
  Widget build(BuildContext context) {
    final memberCount = members.isEmpty ? meeting.joined : members.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailSectionTitle('참여 멤버 $memberCount / ${meeting.capacity}'),
        const SizedBox(height: 14),
        MemberAvatars(meeting: meeting, members: members),
      ],
    );
  }
}

class MemberAvatars extends StatelessWidget {
  const MemberAvatars({
    super.key,
    required this.meeting,
    this.members = const [],
  });

  final Meeting meeting;
  final List<MeetingMember> members;

  static const _avatarColors = [
    AppColors.primary,
    AppColors.orange,
    AppColors.blue,
    AppColors.mint,
  ];

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

    final orderedMembers = _orderedMembers;
    final memberCount =
        orderedMembers.isEmpty ? meeting.joined : orderedMembers.length;
    final visibleCount = math.min(memberCount, 5);
    final remainingCount = memberCount - visibleCount;
    final avatarClusterWidth =
        visibleCount == 0 ? 0.0 : 40.0 + ((visibleCount - 1) * 28.0);

    return Semantics(
      button: members.isNotEmpty,
      label: members.isNotEmpty ? '전체 참여 멤버 보기' : null,
      child: InkWell(
        key: const Key('meeting-members-summary'),
        onTap: members.isEmpty ? null : () => _showMemberList(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: avatarClusterWidth,
                height: 40,
                child: Stack(
                  children: [
                    for (var index = 0; index < visibleCount; index++)
                      Positioned(
                        left: index * 28,
                        child: _MemberAvatar(
                          key: ValueKey('meeting-member-avatar-$index'),
                          member: orderedMembers.isEmpty
                              ? null
                              : orderedMembers[index],
                          fallbackHost: index == 0,
                          color: _avatarColors[index % _avatarColors.length],
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ),
              if (remainingCount > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '+$remainingCount',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              if (members.isNotEmpty) ...[
                const Spacer(),
                const Text(
                  '전체보기',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberList(BuildContext context) {
    final orderedMembers = _orderedMembers;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.68,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '참여 멤버 ${orderedMembers.length}명',
                          key: const Key('meeting-members-sheet-title'),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('meeting-members-sheet-close'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.muted,
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    key: const Key('meeting-members-list'),
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                    itemCount: orderedMembers.length,
                    itemBuilder: (context, index) {
                      final member = orderedMembers[index];
                      final introduction = member.introduction?.trim();
                      return ListTile(
                        key: ValueKey('meeting-member-row-${member.memberId}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: _MemberAvatar(
                          member: member,
                          color: _avatarColors[index % _avatarColors.length],
                          size: 44,
                        ),
                        title: Text(
                          member.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: introduction == null || introduction.isEmpty
                            ? null
                            : Text(
                                introduction,
                                key: ValueKey(
                                  'meeting-member-introduction-${member.memberId}',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        trailing: member.isHost
                            ? Container(
                                key: const Key('meeting-member-host-badge'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.softSurface,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '모임장',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<MeetingMember> get _orderedMembers => [
        ...members.where((member) => member.isHost),
        ...members.where((member) => !member.isHost),
      ];
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    super.key,
    this.member,
    this.fallbackHost = false,
    required this.color,
    required this.size,
  });

  final MeetingMember? member;
  final bool fallbackHost;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = member?.profileImageUrl?.trim();
    final isHost = member?.isHost ?? fallbackHost;
    final placeholder = Container(
      width: size,
      height: size,
      color: color.withOpacity(0.14),
      alignment: Alignment.center,
      child: Icon(
        isHost ? Icons.workspace_premium_rounded : Icons.person_rounded,
        color: color,
        size: size * 0.52,
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1817151F),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: profileImageUrl == null || profileImageUrl.isEmpty
            ? placeholder
            : NetworkImageWithSkeleton(
                imageUrl: profileImageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                cacheHeight: (size * 3).round(),
                skeleton: placeholder,
                errorWidget: placeholder,
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
