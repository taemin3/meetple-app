import 'package:flutter/material.dart';

class NetworkImageWithSkeleton extends StatelessWidget {
  const NetworkImageWithSkeleton({
    super.key,
    required this.imageUrl,
    required this.skeleton,
    required this.errorWidget,
    this.imageKey,
    this.width,
    this.height,
    this.fit,
  });

  final String imageUrl;
  final Widget skeleton;
  final Widget errorWidget;
  final Key? imageKey;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      key: imageKey,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeOut,
          child: frame == null
              ? skeleton
              : KeyedSubtree(
                  key: ValueKey('network-image-loaded-$imageUrl'),
                  child: child,
                ),
        );
      },
      errorBuilder: (_, __, ___) => errorWidget,
    );
  }
}
