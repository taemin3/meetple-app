import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../models/meeting_list_filter.dart';
import 'my_meetings_page.dart';

class BookmarkedMeetingsPage extends StatelessWidget {
  const BookmarkedMeetingsPage({
    super.key,
    required this.meetingRepository,
  });

  final MeetingRepository meetingRepository;

  @override
  Widget build(BuildContext context) {
    return MyMeetingsPage(
      title: '찜한 모임',
      emptyMessage: '아직 찜한 모임이 없습니다.',
      meetingRepository: meetingRepository,
      loader: meetingRepository.getBookmarkedMeetings,
      filters: const [
        MeetingListFilter.all,
        MeetingListFilter.ongoing,
        MeetingListFilter.ended,
      ],
      trailingBuilder: (_) => const Icon(
        Icons.bookmark,
        color: AppColors.primary,
      ),
    );
  }
}
