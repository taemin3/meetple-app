import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
