import 'package:flutter/widgets.dart';

enum AppTab {
  home,
  discover,
  chat,
  profile,
}

class DiscoverOpenRequest {
  const DiscoverOpenRequest({
    required this.id,
    this.category,
    this.focusSearch = false,
  });

  final int id;
  final String? category;
  final bool focusSearch;
}

typedef OpenDiscover = void Function({
  String? category,
  bool focusSearch,
});

class AppNavigation extends InheritedWidget {
  const AppNavigation({
    super.key,
    required this.currentTab,
    required this.selectTab,
    required this.openDiscover,
    required super.child,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> selectTab;
  final OpenDiscover openDiscover;

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
