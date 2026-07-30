import 'package:cached_network_image/cached_network_image.dart';
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
    this.cacheWidth,
    this.cacheHeight,
    this.useOldImageOnUrlChange = true,
  });

  final String imageUrl;
  final Widget skeleton;
  final Widget errorWidget;
  final Key? imageKey;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool useOldImageOnUrlChange;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: imageKey,
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: cacheWidth,
      maxHeightDiskCache: cacheHeight,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      placeholderFadeInDuration: Duration.zero,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => skeleton,
      errorWidget: (_, __, ___) => errorWidget,
    );
  }
}
