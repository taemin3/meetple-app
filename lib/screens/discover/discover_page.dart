import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/meeting_style.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/meeting.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/meeting_photo.dart';
import '../../widgets/tag_chip.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
  });

  final MeetingRepository meetingRepository;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late Future<List<Meeting>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  @override
  void didUpdateWidget(covariant DiscoverPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meetingRepository != widget.meetingRepository) {
      _loadMeetings();
    }
  }

  void _loadMeetings() {
    _meetingsFuture = widget.meetingRepository.findAll();
  }

  void _reloadMeetings() {
    setState(_loadMeetings);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: MapCanvas()),
        SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
            children: [
              const MapTopBar(),
              const SizedBox(height: 18),
              const MapSearchRow(),
              const SizedBox(height: 16),
              const CategoryFilterRow(),
              const SizedBox(height: 270),
              FutureBuilder<List<Meeting>>(
                future: _meetingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const NearbyMeetingStateSheet(
                      child: AppLoadingView(
                        message: '모임을 불러오는 중입니다.',
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return NearbyMeetingStateSheet(
                      child: AppErrorView(
                        message: '모임을 불러오지 못했습니다.',
                        onRetry: _reloadMeetings,
                      ),
                    );
                  }

                  final meetings = snapshot.data ?? const <Meeting>[];
                  if (meetings.isEmpty) {
                    return const NearbyMeetingStateSheet(
                      child: AppEmptyView(
                        message: '주변 모임이 없습니다.',
                      ),
                    );
                  }

                  return NearbyMeetingSheet(meetings: meetings);
                },
              ),
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

class NearbyMeetingStateSheet extends StatelessWidget {
  const NearbyMeetingStateSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
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
      child: child,
    );
  }
}

class NearbyMeetingSheet extends StatelessWidget {
  const NearbyMeetingSheet({super.key, required this.meetings});

  final List<Meeting> meetings;

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
              itemCount: meetings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return MapMeetingCard(meeting: meetings[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MapMeetingCard extends StatelessWidget {
  const MapMeetingCard({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final color = meetingAccent(meeting);

    return SizedBox(
      width: 172,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => AppRoutes.openMeetingDetail(context, meeting),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MeetingPhoto(meeting: meeting, height: 104, borderRadius: 18),
              const SizedBox(height: 10),
              Text(
                meeting.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              CategoryPill(label: meeting.category, color: color),
              const SizedBox(height: 8),
              Text(
                '${meeting.date} · ${meeting.area}',
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
                    meeting.distance,
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
