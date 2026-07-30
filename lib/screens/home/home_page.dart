import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/meeting_style.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_category_repository.dart';
import '../../data/repositories/mock_location_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/meeting.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/category_pill.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/meeting_photo.dart';
import '../../widgets/primary_gradient_button.dart';
import '../../widgets/section_title.dart';
import '../notifications/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
    this.categoryRepository = const MockCategoryRepository(),
    this.locationRepository = const MockLocationRepository(),
    this.refreshToken = 0,
    this.onMeetingCreated,
    this.onMeetingChanged,
  });

  final MeetingRepository meetingRepository;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final int refreshToken;
  final VoidCallback? onMeetingCreated;
  final VoidCallback? onMeetingChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Meeting>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meetingRepository != widget.meetingRepository ||
        oldWidget.refreshToken != widget.refreshToken) {
      _loadMeetings();
    }
  }

  void _loadMeetings() {
    _meetingsFuture = widget.meetingRepository.findAll();
  }

  void _reloadMeetings() {
    setState(_loadMeetings);
  }

  Future<void> _openMeetingDetail(Meeting meeting) async {
    final result = await AppRoutes.openMeetingDetail<Object>(
      context,
      meeting,
      meetingRepository: widget.meetingRepository,
    );
    if (result != null && mounted) {
      (widget.onMeetingChanged ?? _reloadMeetings)();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        HomeGreeting(meetingRepository: widget.meetingRepository),
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
            final isLoading = snapshot.connectionState != ConnectionState.done;
            if (isLoading && !snapshot.hasData) {
              return const _HomeMeetingSkeletonList();
            }

            if (snapshot.hasError) {
              return AppErrorView(
                message: '모임을 불러오지 못했습니다.',
                onRetry: _reloadMeetings,
              );
            }

            final meetings = snapshot.data ?? const <Meeting>[];
            if (meetings.isEmpty) {
              return const AppEmptyView(message: '추천 모임이 없습니다.');
            }

            return Column(
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                for (final meeting in meetings.take(3))
                  HomeMeetingTile(
                    meeting: meeting,
                    onTap: () => _openMeetingDetail(meeting),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        CreateMeetingBanner(
          meetingRepository: widget.meetingRepository,
          categoryRepository: widget.categoryRepository,
          locationRepository: widget.locationRepository,
          onMeetingCreated: widget.onMeetingCreated ?? _reloadMeetings,
        ),
      ],
    );
  }
}

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({
    super.key,
    required this.meetingRepository,
  });

  final MeetingRepository meetingRepository;

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
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => NotificationsPage(
                meetingRepository: meetingRepository,
              ),
            ),
          ),
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

class HomeMeetingTile extends StatelessWidget {
  const HomeMeetingTile({
    super.key,
    required this.meeting,
    required this.onTap,
  });

  final Meeting meeting;
  final VoidCallback onTap;

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
          onTap: onTap,
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

class _HomeMeetingSkeletonList extends StatelessWidget {
  const _HomeMeetingSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('home-meeting-skeleton-list'),
      container: true,
      liveRegion: true,
      label: '추천 모임을 불러오는 중입니다.',
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var index = 0; index < 3; index++)
              _HomeMeetingSkeletonTile(
                key: ValueKey('home-meeting-skeleton-$index'),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeMeetingSkeletonTile extends StatelessWidget {
  const _HomeMeetingSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            SkeletonBox(
              width: 112,
              height: 92,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 138, height: 16),
                  SizedBox(height: 10),
                  SkeletonBox(width: 86, height: 22),
                  SizedBox(height: 10),
                  SkeletonBox(height: 12),
                  SizedBox(height: 7),
                  SkeletonBox(width: 58, height: 12),
                ],
              ),
            ),
            SizedBox(width: 14),
            SkeletonBox(
              width: 20,
              height: 24,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateMeetingBanner extends StatelessWidget {
  const CreateMeetingBanner({
    super.key,
    required this.meetingRepository,
    required this.categoryRepository,
    required this.locationRepository,
    required this.onMeetingCreated,
  });

  final MeetingRepository meetingRepository;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final VoidCallback onMeetingCreated;

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
              onPressed: () => _openCreateMeeting(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateMeeting(BuildContext context) async {
    final createdMeeting = await AppRoutes.openCreateMeeting<Meeting>(
      context,
      meetingRepository: meetingRepository,
      categoryRepository: categoryRepository,
      locationRepository: locationRepository,
    );
    if (createdMeeting != null) {
      onMeetingCreated();
    }
  }
}
