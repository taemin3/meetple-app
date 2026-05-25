import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../screens/chat/chat_page.dart';
import '../screens/create_meeting/create_meeting_page.dart';
import '../screens/discover/discover_page.dart';
import '../screens/home/home_page.dart';
import '../screens/profile/profile_page.dart';
import 'app_navigation.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab currentTab = AppTab.home;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(),
      const DiscoverPage(),
      const CreateMeetingPage(),
      const ChatPage(),
      const ProfilePage(),
    ];

    return AppNavigation(
      currentTab: currentTab,
      selectTab: _selectTab,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: pages[currentTab.index],
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
                      selectedIndex: currentTab.index,
                      onDestinationSelected: (value) {
                        _selectTab(AppTab.values[value]);
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
}
