import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class MainTabHeader extends StatelessWidget {
  const MainTabHeader({
    super.key,
    required this.title,
    this.titleTrailing,
    this.actions = const [],
  });

  final String title;
  final Widget? titleTrailing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvas,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 6),
                      titleTrailing!,
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
