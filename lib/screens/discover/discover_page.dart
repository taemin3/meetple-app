import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/meetup_style.dart';
import '../../data/mock/mock_meetups.dart';
import '../../models/meetup.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/meetup_photo.dart';
import '../../widgets/tag_chip.dart';
import '../meetup_detail/meetup_detail_page.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: MapCanvas()),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
            children: const [
              MapTopBar(),
              SizedBox(height: 18),
              MapSearchRow(),
              SizedBox(height: 16),
              CategoryFilterRow(),
              SizedBox(height: 270),
              NearbyMeetupSheet(),
            ],
          ),
        ),
        const Positioned(left: 54, top: 246, child: CountPin(label: '5')),
        const Positioned(right: 76, top: 300, child: CountPin(label: '3')),
        const Positioned(left: 166, top: 374, child: CountPin(label: '2')),
        const Positioned(right: 96, top: 470, child: CountPin(label: '4')),
        Positioned(
          right: 28,
          top: 548,
          child: FloatingActionButton.small(
            heroTag: 'target-location',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.ink,
            elevation: 2,
            onPressed: () {},
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

class MapTopBar extends StatelessWidget {
  const MapTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu_rounded),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '지도',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class MapSearchRow extends StatelessWidget {
  const MapSearchRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '모임, 장소, 키워드 검색',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F17151F),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}

class CategoryFilterRow extends StatelessWidget {
  const CategoryFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['전체', '운동', '스터디', '취미', '여행', '봉사'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            TagChip(label: items[i], selected: i == 0),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class MapCanvas extends StatelessWidget {
  const MapCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBFAFF), Color(0xFFF3F6FF)],
        ),
      ),
      child: CustomPaint(painter: MapBackgroundPainter()),
    );
  }
}

class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final minorRoad = Paint()
      ..color = const Color(0xFFE1E7F2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final park = Paint()..color = const Color(0xFFDDF3E6);
    final water = Paint()..color = const Color(0xFFDDEBFF);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, 185, size.width * 0.34, 130),
        const Radius.circular(30),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.54, 430, size.width * 0.38, 96),
        const Radius.circular(24),
      ),
      water,
    );

    canvas.drawLine(const Offset(10, 330), Offset(size.width - 20, 260), road);
    canvas.drawLine(const Offset(40, 520), Offset(size.width - 30, 460), road);
    canvas.drawLine(
        Offset(size.width * .38, 180), Offset(size.width * .58, 580), road);
    canvas.drawLine(
        const Offset(20, 410), Offset(size.width - 20, 390), minorRoad);
    canvas.drawLine(
        const Offset(60, 610), Offset(size.width - 30, 720), minorRoad);
    canvas.drawLine(
        Offset(size.width * .72, 170), Offset(size.width * .6, 760), minorRoad);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CountPin extends StatelessWidget {
  const CountPin({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.violet, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class NearbyMeetupSheet extends StatelessWidget {
  const NearbyMeetupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1717151F),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: Text(
                  '이 지역 인기 모임 🔥',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '전체보기 >',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mockMeetups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return MapMeetupCard(meetup: mockMeetups[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MapMeetupCard extends StatelessWidget {
  const MapMeetupCard({super.key, required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    final color = meetupAccent(meetup);

    return SizedBox(
      width: 172,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MeetupDetailPage(meetup: meetup),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MeetupPhoto(meetup: meetup, height: 104, borderRadius: 18),
              const SizedBox(height: 10),
              Text(
                meetup.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              CategoryPill(label: meetup.category, color: color),
              const SizedBox(height: 8),
              Text(
                '${meetup.date} · ${meetup.area}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    meetup.distance,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.bookmark_border,
                      size: 18, color: AppColors.subtle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
