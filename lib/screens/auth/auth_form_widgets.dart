import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class AuthFormField extends StatelessWidget {
  const AuthFormField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.maxLines = 1,
    this.helperText,
    this.trailingText,
    this.suffix,
    this.inputFormatters,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final int maxLines;
  final String? helperText;
  final String? trailingText;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line, width: 1.4),
          ),
          child: SizedBox(
            height: isMultiline ? 96 : 48,
            child: Stack(
              children: [
                TextField(
                  key: fieldKey,
                  controller: controller,
                  keyboardType: obscureText
                      ? TextInputType.visiblePassword
                      : keyboardType,
                  obscureText: obscureText,
                  enableSuggestions: !obscureText,
                  autocorrect: !obscureText,
                  maxLength: maxLength,
                  maxLines: maxLines,
                  inputFormatters: inputFormatters,
                  scrollPadding: const EdgeInsets.fromLTRB(20, 24, 20, 240),
                  onTap: () => _ensureVisible(context),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    counterText: '',
                    hintStyle: const TextStyle(
                      color: AppColors.subtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 12,
                        bottom: isMultiline ? 48 : 0,
                      ),
                      child: Icon(icon),
                    ),
                    prefixIconColor: AppColors.muted,
                    suffixIcon: suffix == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: IconTheme(
                              data: const IconThemeData(
                                color: AppColors.muted,
                                size: 24,
                              ),
                              child: suffix!,
                            ),
                          ),
                    suffixIconConstraints: suffix == null
                        ? null
                        : const BoxConstraints(minHeight: 48),
                    suffixIconColor: AppColors.muted,
                    filled: false,
                    isDense: false,
                    contentPadding: EdgeInsets.fromLTRB(
                      0,
                      isMultiline ? 14 : 12,
                      trailingText == null ? 18 : 58,
                      isMultiline ? 24 : 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
                if (trailingText != null)
                  Positioned(
                    right: 20,
                    bottom: isMultiline ? 12 : 14,
                    child: Text(
                      trailingText!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }

  void _ensureVisible(BuildContext context) {
    Scrollable.ensureVisible(
      context,
      alignment: 0.32,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );

    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!context.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        alignment: 0.32,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class AuthErrorText extends StatelessWidget {
  const AuthErrorText({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

String authErrorMessage(Exception error) {
  if (error is AuthException) {
    return error.message;
  }

  return '요청을 처리하지 못했습니다.';
}
