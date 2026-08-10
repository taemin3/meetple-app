import 'dart:async';

import 'package:flutter/material.dart';

import '../core/push/push_notification_service.dart';
import '../core/theme/app_colors.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/image_upload_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_notification_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/mock_category_repository.dart';
import '../data/repositories/mock_chat_repository.dart';
import '../data/repositories/mock_image_upload_repository.dart';
import '../data/repositories/mock_location_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/realtime/chat_realtime_client.dart';
import '../data/realtime/mock_chat_realtime_client.dart';
import '../models/meeting.dart';
import '../screens/chat/chat_page.dart';
import '../screens/discover/discover_page.dart';
import '../screens/home/home_page.dart';
import '../screens/profile/profile_page.dart';
import 'app_navigation.dart';
import 'app_routes.dart';
import 'meeting_repository_scope.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.authRepository,
    this.meetingRepository = const MockMeetingRepository(),
    this.notificationRepository = const MockNotificationRepository(),
    this.chatRepository = const MockChatRepository(),
    this.chatRealtimeClient = const MockChatRealtimeClient(),
    required this.currentMemberId,
    this.categoryRepository = const MockCategoryRepository(),
    this.locationRepository = const MockLocationRepository(),
    this.imageUploadRepository = const MockImageUploadRepository(),
    this.meetingRefreshToken = 0,
    this.externalChatRefreshToken = 0,
    this.pushNotificationService = const NoopPushNotificationService(),
    this.onSignedOut,
  });

  final AuthRepository? authRepository;
  final MeetingRepository meetingRepository;
  final NotificationRepository notificationRepository;
  final ChatRepository chatRepository;
  final ChatRealtimeClient chatRealtimeClient;
  final int currentMemberId;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final ImageUploadRepository imageUploadRepository;
  final int meetingRefreshToken;
  final int externalChatRefreshToken;
  final PushNotificationService pushNotificationService;
  final VoidCallback? onSignedOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab currentTab = AppTab.home;
  late AuthRepository _authRepository;
  final Set<AppTab> _visitedTabs = <AppTab>{AppTab.home};
  final Set<AppTab> _staleTabs = <AppTab>{};
  int _homeRefreshToken = 0;
  int _discoverRefreshToken = 0;
  int _chatRefreshToken = 0;
  int _discoverOpenRequestId = 0;
  DiscoverOpenRequest? _discoverOpenRequest;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? MockAuthRepository();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authRepository != widget.authRepository &&
        widget.authRepository != null) {
      _authRepository = widget.authRepository!;
    }
    if (oldWidget.meetingRefreshToken != widget.meetingRefreshToken) {
      _applyMeetingTabsInvalidation();
    }
    if (oldWidget.externalChatRefreshToken != widget.externalChatRefreshToken &&
        _visitedTabs.contains(AppTab.chat)) {
      _refreshTab(AppTab.chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeetingRepositoryScope(
      repository: widget.meetingRepository,
      categoryRepository: widget.categoryRepository,
      locationRepository: widget.locationRepository,
      imageUploadRepository: widget.imageUploadRepository,
      child: AppNavigation(
        currentTab: currentTab,
        selectTab: _selectTab,
        openDiscover: _openDiscover,
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              key: const Key('app-tab-stack'),
              sizing: StackFit.expand,
              index: _stackIndexOfTab(currentTab),
              children: [
                _buildTabSlot(AppTab.home),
                _buildTabSlot(AppTab.discover),
                _buildTabSlot(AppTab.chat),
                _buildTabSlot(AppTab.profile),
              ],
            ),
          ),
          bottomNavigationBar: DecoratedBox(
            key: const Key('app-bottom-navigation'),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: NavigationBar(
                height: 70,
                elevation: 0,
                backgroundColor: Colors.white,
                indicatorColor: AppColors.softSurface,
                selectedIndex: _indexOfTab(currentTab),
                onDestinationSelected: _selectDestination,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: '홈',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search),
                    selectedIcon: Icon(Icons.search),
                    label: '탐색',
                  ),
                  NavigationDestination(
                    icon: _CreateMeetingAction(),
                    selectedIcon: _CreateMeetingAction(),
                    label: '모임 만들기',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble),
                    label: '채팅',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: '마이',
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: AppColors.canvas,
        ),
      ),
    );
  }

  void _selectTab(AppTab tab) {
    if (currentTab == tab) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      currentTab = tab;
      final wasVisited = _visitedTabs.contains(tab);
      _visitedTabs.add(tab);
      if (wasVisited && (tab == AppTab.chat || _staleTabs.remove(tab))) {
        _refreshTab(tab);
      }
    });
  }

  void _selectDestination(int index) {
    if (index == 2) {
      FocusManager.instance.primaryFocus?.unfocus();
      unawaited(_openCreateMeeting());
      return;
    }

    _selectTab(_tabAt(index));
  }

  void _openDiscover({
    String? category,
    bool focusSearch = false,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      currentTab = AppTab.discover;
      _visitedTabs.add(AppTab.discover);
      _staleTabs.remove(AppTab.discover);
      _discoverOpenRequest = DiscoverOpenRequest(
        id: ++_discoverOpenRequestId,
        category: category,
        focusSearch: focusSearch,
      );
    });
  }

  Future<void> _openCreateMeeting() async {
    final createdMeeting = await AppRoutes.openCreateMeeting<Meeting>(
      context,
      meetingRepository: widget.meetingRepository,
      categoryRepository: widget.categoryRepository,
      locationRepository: widget.locationRepository,
      imageUploadRepository: widget.imageUploadRepository,
    );
    if (createdMeeting == null || !mounted) {
      return;
    }

    _invalidateMeetingTabs();
  }

  void _invalidateMeetingTabs() {
    if (!mounted) {
      return;
    }

    setState(_applyMeetingTabsInvalidation);
  }

  void _applyMeetingTabsInvalidation() {
    for (final tab in const [AppTab.home, AppTab.discover]) {
      if (!_visitedTabs.contains(tab)) {
        continue;
      }
      if (tab == currentTab) {
        _refreshTab(tab);
      } else {
        _staleTabs.add(tab);
      }
    }
  }

  Widget _buildTabSlot(AppTab tab) {
    return TickerMode(
      key: ValueKey('app-tab-ticker-${tab.name}'),
      enabled: currentTab == tab,
      child: _buildTab(tab),
    );
  }

  void _refreshTab(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        _homeRefreshToken++;
        break;
      case AppTab.discover:
        _discoverRefreshToken++;
        break;
      case AppTab.chat:
        _chatRefreshToken++;
        break;
      case AppTab.profile:
        break;
    }
  }

  int _indexOfTab(AppTab tab) {
    return switch (tab) {
      AppTab.home => 0,
      AppTab.discover => 1,
      AppTab.chat => 3,
      AppTab.profile => 4,
    };
  }

  AppTab _tabAt(int index) {
    return switch (index) {
      0 => AppTab.home,
      1 => AppTab.discover,
      3 => AppTab.chat,
      4 => AppTab.profile,
      _ => throw RangeError.index(index, const <int>[0, 1, 3, 4]),
    };
  }

  int _stackIndexOfTab(AppTab tab) {
    return switch (tab) {
      AppTab.home => 0,
      AppTab.discover => 1,
      AppTab.chat => 2,
      AppTab.profile => 3,
    };
  }

  Widget _buildTab(AppTab tab) {
    if (!_visitedTabs.contains(tab)) {
      return const SizedBox.shrink();
    }

    switch (tab) {
      case AppTab.home:
        return HomePage(
          meetingRepository: widget.meetingRepository,
          notificationRepository: widget.notificationRepository,
          categoryRepository: widget.categoryRepository,
          locationRepository: widget.locationRepository,
          refreshToken: _homeRefreshToken,
          onMeetingCreated: _invalidateMeetingTabs,
          onMeetingChanged: _invalidateMeetingTabs,
          onOpenDiscover: _openDiscover,
        );
      case AppTab.discover:
        return DiscoverPage(
          meetingRepository: widget.meetingRepository,
          categoryRepository: widget.categoryRepository,
          refreshToken: _discoverRefreshToken,
          onMeetingChanged: _invalidateMeetingTabs,
          openRequest: _discoverOpenRequest,
        );
      case AppTab.chat:
        return ChatPage(
          chatRepository: widget.chatRepository,
          chatRealtimeClient: widget.chatRealtimeClient,
          currentMemberId: widget.currentMemberId,
          refreshToken: _chatRefreshToken,
          pushNotificationService: widget.pushNotificationService,
        );
      case AppTab.profile:
        return ProfilePage(
          authRepository: _authRepository,
          meetingRepository: widget.meetingRepository,
          notificationRepository: widget.notificationRepository,
          isActive: currentTab == AppTab.profile,
          onSignedOut: widget.onSignedOut,
          onMeetingChanged: _invalidateMeetingTabs,
        );
    }
  }
}

class _CreateMeetingAction extends StatelessWidget {
  const _CreateMeetingAction();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('bottom-create-meeting-action'),
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x407B61FF),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.add_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}
