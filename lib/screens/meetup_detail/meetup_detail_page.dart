import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/meetup.dart';
import '../../widgets/meetup_photo.dart';
import '../../widgets/primary_gradient_button.dart';
import '../../widgets/surface_panel.dart';
import '../../widgets/tag_chip.dart';

class MeetupDetailPage extends StatelessWidget {
  const MeetupDetailPage({super.key, required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          DetailHero(meetup: meetup),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in meetup.tags) TagChip(label: tag),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  meetup.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${meetup.joined} / ${meetup.capacity}명',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.star_rounded,
                        color: AppColors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${meetup.rating} (${meetup.reviewCount})',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                DetailInfoRow(meetup: meetup),
                const SizedBox(height: 28),
                const Text(
                  '모임 소개',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  meetup.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.65,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  '활동 위치',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const MiniMapCard(),
                const SizedBox(height: 28),
                const Text(
                  '참여 멤버',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                const MemberAvatars(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 18),
        child: PrimaryGradientButton(
          label: '참여하기',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('참여 신청이 전송되었습니다.')),
          ),
        ),
      ),
    );
  }
}

class DetailHero extends StatelessWidget {
  const DetailHero({super.key, required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MeetupPhoto(
              meetup: meetup, height: 330, borderRadius: 0, showIcon: false),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.46),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  CircleIconButton(
                      icon: Icons.ios_share_rounded, onPressed: () {}),
                  const SizedBox(width: 10),
                  CircleIconButton(
                      icon: Icons.bookmark_border, onPressed: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.ink),
      ),
    );
  }
}

class DetailInfoRow extends StatelessWidget {
  const DetailInfoRow({super.key, required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('일시', '${meetup.date}\n${meetup.time}'),
      ('장소', '${meetup.area}\n서울 영등포구'),
      ('참가비', meetup.fee),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: SurfacePanel(
              child: SizedBox(
                height: 74,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[i].$1,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      items[i].$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class MiniMapCard extends StatelessWidget {
  const MiniMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: MiniMapPainter()),
            const Center(
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.place_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEAF1FF);
    final park = Paint()..color = const Color(0xFFD9F0DF);
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .1, 20, size.width * .38, 90),
      park,
    );
    canvas.drawLine(const Offset(18, 40), Offset(size.width - 24, 110), road);
    canvas.drawLine(const Offset(34, 118), Offset(size.width - 40, 36), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MemberAvatars extends StatelessWidget {
  const MemberAvatars({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      AppColors.orange,
      AppColors.blue,
      AppColors.mint,
    ];

    return Row(
      children: [
        for (var i = 0; i < colors.length; i++)
          Align(
            widthFactor: 0.72,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: colors[i].withOpacity(0.18),
              child: Icon(Icons.person, color: colors[i]),
            ),
          ),
        const SizedBox(width: 18),
        const Text(
          '+7',
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
