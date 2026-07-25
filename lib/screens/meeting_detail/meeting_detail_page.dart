import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/meeting.dart';
import '../../widgets/map/meeting_location_map.dart';
import '../../widgets/meeting_photo.dart';
import '../../widgets/primary_gradient_button.dart';

class MeetingDetailPage extends StatefulWidget {
  const MeetingDetailPage({super.key, required this.meeting});

  final Meeting meeting;

  @override
  State<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends State<MeetingDetailPage> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
  }

  void _requestParticipation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('참여 신청이 전송되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          DetailHero(
            meeting: meeting,
            isFavorite: _isFavorite,
            onFavoritePressed: _toggleFavorite,
          ),
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
                MemberAvatars(meeting: meeting),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DetailBottomBar(
        isFavorite: _isFavorite,
        onFavoritePressed: _toggleFavorite,
        onParticipationPressed: _requestParticipation,
      ),
    );
  }
}

class DetailHero extends StatelessWidget {
  const DetailHero({
    super.key,
    required this.meeting,
    required this.isFavorite,
    required this.onFavoritePressed,
  });

  final Meeting meeting;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;

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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TransparentHeroIconButton(
                    key: const Key('meeting-detail-back-button'),
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: '뒤로가기',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  TransparentHeroIconButton(
                    key: const Key('meeting-detail-hero-favorite-button'),
                    icon: isFavorite
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    tooltip: '찜하기',
                    onPressed: onFavoritePressed,
                  ),
                ],
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

class TransparentHeroIconButton extends StatelessWidget {
  const TransparentHeroIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
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
          showDivider: false,
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
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? supportingText;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final normalizedSupportingText = supportingText?.trim();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: AppColors.line, width: 0.8),
              )
            : null,
      ),
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
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 300,
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
  const MemberAvatars({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    if (meeting.joined <= 0) {
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
    final visibleCount = math.min(meeting.joined, colors.length);
    final remainingCount = meeting.joined - visibleCount;

    return Row(
      children: [
        for (var index = 0; index < visibleCount; index++) ...[
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[index].withOpacity(0.14),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1817151F),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              color: colors[index],
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
  });

  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onParticipationPressed;

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
                label: '참여 신청하기',
                onPressed: onParticipationPressed,
              ),
            ),
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
