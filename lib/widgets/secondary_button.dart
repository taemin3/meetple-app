import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.borderRadius = 14,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double borderRadius;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: loading ? Colors.white : AppColors.surface,
          disabledForegroundColor:
              loading ? AppColors.primary : AppColors.subtle,
          side: const BorderSide(color: AppColors.line),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: loading
            ? Semantics(
                label: '$label 처리 중',
                child: const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
      ),
    );
  }
}
