import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

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
    this.enableSuggestions = true,
    this.autocorrect = true,
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
  final bool enableSuggestions;
  final bool autocorrect;
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
                  keyboardType: keyboardType ??
                      (obscureText ? TextInputType.visiblePassword : null),
                  obscureText: obscureText,
                  enableSuggestions: enableSuggestions,
                  autocorrect: autocorrect,
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
