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
import '../screens/create_meeting/create_meeting_page.dart';
import '../screens/discover/discover_page.dart';
import '../screens/home/home_page.dart';
import '../screens/profile/profile_page.dart';
import 'app_navigation.dart';
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
  static const _tabs = <AppTab>[
    AppTab.home,
    AppTab.discover,
    AppTab.createMeeting,
    AppTab.chat,
    AppTab.profile,
  ];

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
      child: AppNavigation(
        currentTab: currentTab,
        selectTab: _selectTab,
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: _buildPage(currentTab),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: SizedBox(
              height: 82,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: NavigationBar(
                        height: 66,
                        elevation: 0,
                        backgroundColor: Colors.white,
                        indicatorColor: AppColors.softSurface,
                        selectedIndex: _indexOfTab(currentTab),
                        onDestinationSelected: (value) {
                          _selectTab(_tabAt(value));
                        },
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
                            icon: Icon(Icons.add_circle_outline),
                            selectedIcon: Icon(Icons.add_circle),
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
                ),
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

  int _indexOfTab(AppTab tab) {
    return _tabs.indexOf(tab);
  }

  AppTab _tabAt(int index) {
    return _tabs[index];
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
      case AppTab.createMeeting:
        return CreateMeetingPage(
          meetingRepository: widget.meetingRepository,
          categoryRepository: widget.categoryRepository,
          locationRepository: widget.locationRepository,
          imageUploadRepository: widget.imageUploadRepository,
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
