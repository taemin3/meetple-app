import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.message,
    this.height = 104,
    this.icon,
    this.iconColor,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final double height;
  final IconData? icon;
  final Color? iconColor;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;

    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress) ...[
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
                const SizedBox(height: 12),
              ] else if (icon != null) ...[
                Icon(icon, color: iconColor ?? AppColors.primary, size: 28),
                const SizedBox(height: 10),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    required this.message,
    this.height = 104,
  });

  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      message: message,
      height: height,
      showProgress: true,
    );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.height = 128,
    this.onRetry,
  });

  final String message;
  final double height;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      message: message,
      height: height,
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
      actionLabel: onRetry == null ? null : '다시 시도',
      onAction: onRetry,
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.message,
    this.height = 104,
  });

  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      message: message,
      height: height,
      icon: Icons.event_busy_outlined,
      iconColor: AppColors.subtle,
    );
  }
}
