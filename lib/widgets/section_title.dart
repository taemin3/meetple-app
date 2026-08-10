import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
    this.actionKey,
  });

  final String title;
  final String? action;
  final VoidCallback? onActionTap;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            key: actionKey,
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action!,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }
}
