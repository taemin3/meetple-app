import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/repositories/meeting_repository.dart';
import '../models/meeting.dart';
import '../models/meeting_engagement.dart';
import 'meeting_list_card.dart';

class BookmarkableMeetingCard extends StatefulWidget {
  const BookmarkableMeetingCard({
    super.key,
    required this.meeting,
    required this.meetingRepository,
    required this.onTap,
    this.onBookmarkChanged,
    this.showDistance = false,
  });

  final Meeting meeting;
  final MeetingRepository meetingRepository;
  final Future<void> Function() onTap;
  final VoidCallback? onBookmarkChanged;
  final bool showDistance;

  @override
  State<BookmarkableMeetingCard> createState() =>
      _BookmarkableMeetingCardState();
}

class _BookmarkableMeetingCardState extends State<BookmarkableMeetingCard> {
  MeetingEngagement? _engagement;
  bool _isBookmarkBusy = false;
  int _engagementRequestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadEngagement();
  }

  @override
  void didUpdateWidget(covariant BookmarkableMeetingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meeting.id != widget.meeting.id ||
        oldWidget.meetingRepository != widget.meetingRepository) {
      _engagement = null;
      _loadEngagement();
    }
  }

  @override
  void dispose() {
    _engagementRequestGeneration++;
    super.dispose();
  }

  Future<void> _loadEngagement() async {
    final meetingId = widget.meeting.id;
    final requestGeneration = ++_engagementRequestGeneration;
    if (meetingId == null) {
      _engagement = null;
      return;
    }
    try {
      final engagement =
          await widget.meetingRepository.getEngagement(meetingId);
      if (!mounted || requestGeneration != _engagementRequestGeneration) return;
      setState(() => _engagement = engagement);
    } on Object {
      if (!mounted || requestGeneration != _engagementRequestGeneration) return;
      setState(() => _engagement = null);
    }
  }

  Future<void> _toggleBookmark() async {
    final meetingId = widget.meeting.id;
    final engagement = _engagement;
    if (meetingId == null ||
        engagement == null ||
        engagement.isHost ||
        _isBookmarkBusy) {
      return;
    }

    final next = !engagement.isBookmarked;
    setState(() {
      _engagement = engagement.copyWith(isBookmarked: next);
      _isBookmarkBusy = true;
    });
    try {
      await widget.meetingRepository.setBookmarked(meetingId, next);
      widget.onBookmarkChanged?.call();
    } on Exception {
      if (!mounted) return;
      setState(() => _engagement = engagement);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('찜하기를 변경하지 못했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isBookmarkBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engagement = _engagement;
    final isBookmarked = engagement?.isBookmarked == true;
    return MeetingListCard(
      meeting: widget.meeting,
      showDistance: widget.showDistance,
      onTap: () async {
        await widget.onTap();
        if (mounted) await _loadEngagement();
      },
      trailing: IconButton(
        key: Key('meeting-bookmark-${widget.meeting.id}'),
        tooltip: isBookmarked ? '찜 취소' : '찜하기',
        onPressed: engagement == null || engagement.isHost || _isBookmarkBusy
            ? null
            : _toggleBookmark,
        icon: Icon(
          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border,
          color: isBookmarked ? AppColors.primary : AppColors.subtle,
        ),
        style: IconButton.styleFrom(
          fixedSize: const Size(32, 24),
          minimumSize: const Size(32, 24),
          maximumSize: const Size(32, 24),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerRight,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
