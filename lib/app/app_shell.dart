import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/image_upload_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/mock_category_repository.dart';
import '../data/repositories/mock_image_upload_repository.dart';
import '../data/repositories/mock_location_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';
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
    this.categoryRepository = const MockCategoryRepository(),
    this.locationRepository = const MockLocationRepository(),
    this.imageUploadRepository = const MockImageUploadRepository(),
    this.onSignedOut,
  });

  final AuthRepository? authRepository;
  final MeetingRepository meetingRepository;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final ImageUploadRepository imageUploadRepository;
  final VoidCallback? onSignedOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab currentTab = AppTab.home;
  late AuthRepository _authRepository;

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
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: _buildPage(currentTab),
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
    setState(() => currentTab = tab);
  }

  void _selectDestination(int index) {
    if (index == 2) {
      AppRoutes.openCreateMeeting<void>(
        context,
        meetingRepository: widget.meetingRepository,
        categoryRepository: widget.categoryRepository,
        locationRepository: widget.locationRepository,
        imageUploadRepository: widget.imageUploadRepository,
      );
      return;
    }

    _selectTab(_tabAt(index));
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

  Widget _buildPage(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return HomePage(
          meetingRepository: widget.meetingRepository,
          categoryRepository: widget.categoryRepository,
          locationRepository: widget.locationRepository,
        );
      case AppTab.discover:
        return DiscoverPage(
          meetingRepository: widget.meetingRepository,
          categoryRepository: widget.categoryRepository,
        );
      case AppTab.chat:
        return const ChatPage();
      case AppTab.profile:
        return ProfilePage(
          authRepository: _authRepository,
          meetingRepository: widget.meetingRepository,
          onSignedOut: widget.onSignedOut,
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
