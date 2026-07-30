import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../widgets/meeting_list_card.dart';

class BookmarkedMeetingsPage extends StatefulWidget {
  const BookmarkedMeetingsPage({
    super.key,
    required this.meetingRepository,
  });

  final MeetingRepository meetingRepository;

  @override
  State<BookmarkedMeetingsPage> createState() => _BookmarkedMeetingsPageState();
}

class _BookmarkedMeetingsPageState extends State<BookmarkedMeetingsPage> {
  late Future<List<Meeting>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.meetingRepository.getBookmarkedMeetings();
  }

  void _reload() {
    setState(() {
      _future = widget.meetingRepository.getBookmarkedMeetings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('찜한 모임')),
      body: FutureBuilder<List<Meeting>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('찜한 모임을 불러오지 못했습니다.'));
          }
          final meetings = snapshot.data ?? const [];
          if (meetings.isEmpty) {
            return const Center(child: Text('아직 찜한 모임이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return MeetingListCard(
                meeting: meeting,
                onTap: () async {
                  await AppRoutes.openMeetingDetail(
                    context,
                    meeting,
                    meetingRepository: widget.meetingRepository,
                  );
                  if (mounted) _reload();
                },
                trailing: const Icon(
                  Icons.bookmark,
                  color: Color(0xFF7B61FF),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
