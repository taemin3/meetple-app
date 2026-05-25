import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/meeting_style.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/meeting.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/meeting_photo.dart';
import '../../widgets/primary_gradient_button.dart';
import '../../widgets/section_title.dart';
import '../meeting_detail/meeting_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
  });

  final MeetingRepository meetingRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Meeting>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _meetingsFuture = widget.meetingRepository.findAll();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meetingRepository != widget.meetingRepository) {
      _meetingsFuture = widget.meetingRepository.findAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        const HomeGreeting(),
        const SizedBox(height: 24),
        const HomeSearchField(),
        const SizedBox(height: 24),
        const CategoryShortcutRow(),
        const SizedBox(height: 30),
        const SectionTitle(title: '추천 모임', action: '전체보기 >'),
        const SizedBox(height: 14),
        FutureBuilder<List<Meeting>>(
          future: _meetingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const MeetingListStatus(message: '모임을 불러오는 중입니다.');
            }

            if (snapshot.hasError) {
              return const MeetingListStatus(message: '모임을 불러오지 못했습니다.');
            }

            final meetings = snapshot.data ?? const <Meeting>[];
            if (meetings.isEmpty) {
              return const MeetingListStatus(message: '추천 모임이 없습니다.');
            }

            return Column(
              children: [
                for (final meeting in meetings.take(3))
                  HomeMeetingTile(meeting: meeting),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const CreateMeetingBanner(),
      ],
    );
  }
}

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '새로운 모임,',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '함께할 사람을\n찾아보세요 👋',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 26,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
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

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: '모임, 장소, 키워드 검색',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class CategoryShortcutRow extends StatelessWidget {
  const CategoryShortcutRow({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('전체', Icons.grid_view_rounded, true),
      ('운동', Icons.directions_run, false),
      ('스터디', Icons.menu_book_outlined, false),
      ('취미', Icons.palette_outlined, false),
      ('여행', Icons.flight_takeoff, false),
      ('봉사', Icons.favorite_border, false),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      item.$3 ? AppColors.primary : AppColors.softSurface,
                  child: Icon(
                    item.$2,
                    color: item.$3 ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),
          ],
        ],
      ),
    );
  }
}

class MeetingListStatus extends StatelessWidget {
  const MeetingListStatus({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class HomeMeetingTile extends StatelessWidget {
  const HomeMeetingTile({super.key, required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final color = meetingAccent(meeting);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MeetingDetailPage(meeting: meeting),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  child: MeetingPhoto(
                    meeting: meeting,
                    height: 92,
                    borderRadius: 14,
                    showIcon: false,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in meeting.tags.take(3))
                            CategoryPill(label: tag, color: color),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${meeting.date} ${meeting.time} · ${meeting.area}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meeting.joined}/${meeting.capacity}명',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.bookmark_border, color: AppColors.subtle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateMeetingBanner extends StatelessWidget {
  const CreateMeetingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.violet],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '모임을 직접\n만들어보세요!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '관심사에 맞는 모임을 열어보세요',
                  style: TextStyle(
                    color: Color(0xFFE8E1FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: PrimaryGradientButton(
              label: '+',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
