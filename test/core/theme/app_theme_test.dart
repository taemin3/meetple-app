import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/theme/app_colors.dart';
import 'package:meetple/core/theme/app_theme.dart';

void main() {
  test('uses Meetple brand color tokens', () {
    expect(AppColors.primary, const Color(0xFF7B61FF));
    expect(AppColors.secondary, const Color(0xFFA78BFA));
    expect(AppColors.accent, const Color(0xFFF78BC7));
    expect(AppColors.canvas, const Color(0xFFF8F7FC));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.ink, const Color(0xFF1F1D3D));
    expect(AppColors.muted, const Color(0xFF8C8AA5));
    expect(AppColors.success, const Color(0xFF6DDC91));
    expect(AppColors.warning, const Color(0xFFFFB84D));
    expect(AppColors.error, const Color(0xFFFF6B81));
  });

  test('applies Pretendard as the app font family', () {
    final theme = AppTheme.light();

    expect(theme.textTheme.bodyMedium?.fontFamily, 'Pretendard');
    expect(theme.textTheme.titleLarge?.fontFamily, 'Pretendard');
  });
}
