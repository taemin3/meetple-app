import 'package:flutter/material.dart';

import '../../app/app_navigation.dart';
import '../../app/app_routes.dart';
import '../../core/config/app_config.dart';
import '../../core/map/nearby_location_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_notification_repository.dart';
import '../../data/repositories/mock_category_repository.dart';
import '../../data/repositories/mock_location_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../models/meeting.dart';
import '../../models/meeting_category.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/meeting_list_card.dart';
import '../../widgets/section_title.dart';
import '../notifications/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
    this.notificationRepository = const MockNotificationRepository(),
    this.categoryRepository = const MockCategoryRepository(),
    this.locationRepository = const MockLocationRepository(),
    this.refreshToken = 0,
    this.onMeetingCreated,
    this.onMeetingChanged,
    this.onOpenDiscover,
    this.nearbyLocationProvider,
  });

  final MeetingRepository meetingRepository;
  final NotificationRepository notificationRepository;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final int refreshToken;
  final VoidCallback? onMeetingCreated;
  final VoidCallback? onMeetingChanged;
  final OpenDiscover? onOpenDiscover;
  final NearbyLocationProvider? nearbyLocationProvider;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Meeting>> _meetingsFuture;
  late Future<List<MeetingCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meetingRepository != widget.meetingRepository ||
        oldWidget.nearbyLocationProvider != widget.nearbyLocationProvider ||
        oldWidget.refreshToken != widget.refreshToken) {
      _loadMeetings();
    }
    if (oldWidget.categoryRepository != widget.categoryRepository) {
      _loadCategories();
    }
  }

  void _loadHomeData() {
    _loadMeetings();
    _loadCategories();
  }

  void _loadMeetings() {
    _meetingsFuture = _findRecommendedMeetings();
  }

  void _loadCategories() {
    _categoriesFuture = widget.categoryRepository.findAll();
  }

  Future<List<Meeting>> _findRecommendedMeetings() async {
    final injectedProvider = widget.nearbyLocationProvider;
    if (injectedProvider == null && !AppConfig.hasNaverMapClientId) {
      return widget.meetingRepository.findAll();
    }

    final location = await (injectedProvider ?? createNearbyLocationProvider())
        .requestCurrentLocation();
    if (location == null) {
      return widget.meetingRepository.findAll();
    }

    return widget.meetingRepository.findNearby(
      NearbyMeetingQuery(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusMeters: 5000,
        size: 3,
      ),
    );
  }

  void _reloadMeetings() {
    setState(_loadMeetings);
  }

  void _openDiscover({
    String? category,
    bool focusSearch = false,
  }) {
    final openDiscover =
        widget.onOpenDiscover ?? AppNavigation.maybeOf(context)?.openDiscover;
    openDiscover?.call(category: category, focusSearch: focusSearch);
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
        HomeGreeting(
          meetingRepository: widget.meetingRepository,
          notificationRepository: widget.notificationRepository,
          onMeetingChanged: widget.onMeetingChanged ?? _reloadMeetings,
        ),
        const SizedBox(height: 24),
        HomeSearchField(
          onTap: () => _openDiscover(focusSearch: true),
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<MeetingCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            final categories = snapshot.data ?? const <MeetingCategory>[];
            return CategoryShortcutRow(
              categories: categories,
              onSelected: (category) => _openDiscover(category: category),
            );
          },
        ),
        const SizedBox(height: 30),
        SectionTitle(
          title: '추천 모임',
          action: '전체보기 >',
          actionKey: const Key('home-recommendations-view-all'),
          onActionTap: () => _openDiscover(),
        ),
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
    required this.notificationRepository,
    this.onMeetingChanged,
  });

  final MeetingRepository meetingRepository;
  final NotificationRepository notificationRepository;
  final VoidCallback? onMeetingChanged;

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
                notificationRepository: notificationRepository,
                onMeetingChanged: onMeetingChanged,
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
  const HomeSearchField({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('home-search-field'),
      readOnly: true,
      onTap: onTap,
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
  const CategoryShortcutRow({
    super.key,
    required this.categories,
    required this.onSelected,
  });

  final List<MeetingCategory> categories;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData)>[
      ('전체', Icons.grid_view_rounded),
      for (final category in categories)
        (category.name, _iconForCategory(category.name)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            InkWell(
              key: ValueKey('home-category-${item.$1}'),
              onTap: () => onSelected(item.$1 == '전체' ? null : item.$1),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: item.$1 == '전체'
                          ? AppColors.primary
                          : AppColors.softSurface,
                      child: Icon(
                        item.$2,
                        color:
                            item.$1 == '전체' ? Colors.white : AppColors.primary,
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
              ),
            ),
            const SizedBox(width: 18),
          ],
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category.trim()) {
      case '운동':
        return Icons.directions_run;
      case '스터디':
        return Icons.menu_book_outlined;
      case '취미':
        return Icons.palette_outlined;
      case '여행':
        return Icons.flight_takeoff;
      case '봉사':
        return Icons.favorite_border;
      default:
        return Icons.interests_outlined;
    }
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MeetingListCard(
        meeting: meeting,
        onTap: onTap,
        trailing: const Icon(
          Icons.bookmark_border,
          color: AppColors.subtle,
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
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: const Offset(0, 6),
                    child: Image.asset(
                      'assets/images/create_meeting_people.png',
                      key: const Key('home-create-meeting-people'),
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      cacheWidth: 360,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  child: Semantics(
                    button: true,
                    label: '모임 만들기',
                    child: Material(
                      color: Colors.white,
                      elevation: 6,
                      shadowColor: const Color(0x4D2F1A66),
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const Key('home-create-meeting-button'),
                        onTap: () => _openCreateMeeting(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox.square(
                          dimension: 54,
                          child: Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                            size: 31,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
