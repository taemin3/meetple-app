import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final double height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.48, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: widget.borderRadius,
          ),
        ),
      ),
    );
  }
}
