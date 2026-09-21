import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/repositories/meeting_repository.dart';
import '../models/meeting.dart';
import 'meeting_bookmark_store.dart';
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
  late MeetingBookmarkStore _bookmarks;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant BookmarkableMeetingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meetingRepository != widget.meetingRepository) {
      _bookmarks.removeListener(_rebuild);
      _subscribe();
    }
  }

  void _subscribe() {
    _bookmarks = MeetingBookmarkStore.forRepository(widget.meetingRepository);
    _bookmarks.addListener(_rebuild);
    _bookmarks.load().catchError((Object _) {
      // The button retries loading when tapped.
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bookmarks.removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    final meetingId = widget.meeting.id;
    if (meetingId == null || _bookmarks.isBusy(meetingId)) return;
    try {
      if (!_bookmarks.isLoaded) await _bookmarks.load();
      if (!mounted) return;
      await _bookmarks.toggle(meetingId);
      if (mounted) widget.onBookmarkChanged?.call();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('찜하기를 변경하지 못했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingId = widget.meeting.id;
    final isBookmarked =
        meetingId != null && _bookmarks.isBookmarked(meetingId);
    return MeetingListCard(
      meeting: widget.meeting,
      showDistance: widget.showDistance,
      onTap: () async => widget.onTap(),
      trailing: IconButton(
        key: Key('meeting-bookmark-$meetingId'),
        tooltip: isBookmarked ? '찜 취소' : '찜하기',
        // Keep the callback active so taps never reach the parent card.
        onPressed: _toggleBookmark,
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
