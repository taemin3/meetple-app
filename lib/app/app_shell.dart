import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';
import '../screens/chat/chat_page.dart';
import '../screens/create_meeting/create_meeting_page.dart';
import '../screens/discover/discover_page.dart';
import '../screens/home/home_page.dart';
import '../screens/profile/profile_page.dart';
import 'app_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
  });

  final MeetingRepository meetingRepository;

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

  @override
  Widget build(BuildContext context) {
    return AppNavigation(
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
        return HomePage(meetingRepository: widget.meetingRepository);
      case AppTab.discover:
        return DiscoverPage(meetingRepository: widget.meetingRepository);
      case AppTab.createMeeting:
        return const CreateMeetingPage();
      case AppTab.chat:
        return const ChatPage();
      case AppTab.profile:
        return const ProfilePage();
    }
  }
}
