import 'package:flutter/widgets.dart';

enum AppTab {
  home,
  discover,
  createMeeting,
  chat,
  profile,
}

class AppNavigation extends InheritedWidget {
  const AppNavigation({
    super.key,
    required this.currentTab,
    required this.selectTab,
    required super.child,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> selectTab;

  static AppNavigation? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppNavigation>();
  }

  static AppNavigation of(BuildContext context) {
    final navigation = maybeOf(context);
    assert(navigation != null, 'No AppNavigation found in context.');
    return navigation!;
  }

  @override
  bool updateShouldNotify(AppNavigation oldWidget) {
    return currentTab != oldWidget.currentTab;
  }
}
