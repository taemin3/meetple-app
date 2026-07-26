import 'dart:async';

import 'package:flutter/material.dart';

import '../models/meeting.dart';
import 'meeting_photo.dart';

class MeetingImageGallery extends StatefulWidget {
  const MeetingImageGallery({
    super.key,
    required this.meeting,
    this.height = 300,
  });

  final Meeting meeting;
  final double height;

  @override
  State<MeetingImageGallery> createState() => _MeetingImageGalleryState();
}

class _MeetingImageGalleryState extends State<MeetingImageGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;
  String? _precacheSignature;

  List<String> get _imageUrls => meetingImageUrls(widget.meeting);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages();
  }

  @override
  void didUpdateWidget(covariant MeetingImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_imageSignature(oldWidget.meeting) != _imageSignature(widget.meeting)) {
      _currentIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _precacheImages();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = _imageUrls;
    if (imageUrls.isEmpty) {
      return MeetingPhoto(
        meeting: widget.meeting,
        height: widget.height,
        borderRadius: 0,
        showIcon: false,
      );
    }

    return SizedBox(
      key: const Key('meeting-detail-image-gallery'),
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                key: ValueKey('meeting-detail-image-$index'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _openViewer(context, imageUrls, index),
                child: _GalleryNetworkImage(
                  imageUrl: imageUrls[index],
                ),
              );
            },
          ),
          if (imageUrls.length > 1)
            Positioned(
              top: 72,
              right: 16,
              child: _ImageCounter(
                key: const Key('meeting-detail-image-counter'),
                current: _currentIndex + 1,
                total: imageUrls.length,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openViewer(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FullScreenMeetingImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  String _imageSignature(Meeting meeting) {
    return meetingImageUrls(meeting).join('\n');
  }

  void _precacheImages() {
    final imageUrls = _imageUrls;
    final signature = imageUrls.join('\n');
    if (imageUrls.isEmpty || signature == _precacheSignature) {
      return;
    }

    _precacheSignature = signature;
    for (final imageUrl in imageUrls) {
      unawaited(
        precacheImage(
          NetworkImage(imageUrl),
          context,
          onError: (_, __) {},
        ),
      );
    }
  }
}

class FullScreenMeetingImageViewer extends StatefulWidget {
  const FullScreenMeetingImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<FullScreenMeetingImageViewer> createState() =>
      _FullScreenMeetingImageViewerState();
}

class _FullScreenMeetingImageViewerState
    extends State<FullScreenMeetingImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('meeting-image-viewer'),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: PageView.builder(
              key: const Key('meeting-image-viewer-pages'),
              controller: _pageController,
              physics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _isZoomed = false;
                });
              },
              itemBuilder: (context, index) {
                return _ZoomableNetworkImage(
                  key: ValueKey('meeting-image-viewer-image-$index'),
                  imageUrl: widget.imageUrls[index],
                  onZoomChanged: (isZoomed) {
                    if (index == _currentIndex && _isZoomed != isZoomed) {
                      setState(() => _isZoomed = isZoomed);
                    }
                  },
                );
              },
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('meeting-image-viewer-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '닫기',
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0x66000000),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Spacer(),
                  _ImageCounter(
                    key: const Key('meeting-image-viewer-counter'),
                    current: _currentIndex + 1,
                    total: widget.imageUrls.length,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomableNetworkImage extends StatefulWidget {
  const _ZoomableNetworkImage({
    super.key,
    required this.imageUrl,
    required this.onZoomChanged,
  });

  final String imageUrl;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableNetworkImage> createState() => _ZoomableNetworkImageState();
}

class _ZoomableNetworkImageState extends State<_ZoomableNetworkImage> {
  final TransformationController _transformationController =
      TransformationController();
  Offset? _doubleTapPosition;
  bool _isZoomed = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _toggleDoubleTapZoom,
      child: InteractiveViewer(
        key: const Key('meeting-image-interactive-viewer'),
        transformationController: _transformationController,
        minScale: 1,
        maxScale: 4,
        panEnabled: _isZoomed,
        scaleEnabled: true,
        onInteractionUpdate: (_) => _syncZoomState(),
        onInteractionEnd: (_) => _syncZoomState(),
        child: SizedBox.expand(
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleDoubleTapZoom() {
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
      _setZoomed(false);
      return;
    }

    const scale = 2.5;
    final position = _doubleTapPosition ?? Offset.zero;
    _transformationController.value = Matrix4.identity()
      ..translate(
        position.dx * (1 - scale),
        position.dy * (1 - scale),
      )
      ..scale(scale);
    _setZoomed(true);
  }

  void _syncZoomState() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    _setZoomed(scale > 1.01);
  }

  void _setZoomed(bool value) {
    if (_isZoomed == value) return;
    setState(() => _isZoomed = value);
    widget.onZoomChanged(value);
  }
}

class _GalleryNetworkImage extends StatelessWidget {
  const _GalleryNetworkImage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const _GalleryImagePlaceholder();
      },
      errorBuilder: (_, __, ___) => const _GalleryImagePlaceholder(),
    );
  }
}

class _GalleryImagePlaceholder extends StatelessWidget {
  const _GalleryImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: Key('meeting-gallery-image-placeholder'),
      color: Color(0xFF242329),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 28,
          color: Colors.white38,
        ),
      ),
    );
  }
}

class _ImageCounter extends StatelessWidget {
  const _ImageCounter({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

List<String> meetingImageUrls(Meeting meeting) {
  final imageUrls = <String>[];
  void addImageUrl(String? value) {
    final normalized = value?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        imageUrls.contains(normalized)) {
      return;
    }
    imageUrls.add(normalized);
  }

  addImageUrl(meeting.thumbnailImageUrl);
  for (final imageUrl in meeting.imageUrls) {
    addImageUrl(imageUrl);
  }
  return imageUrls;
}
