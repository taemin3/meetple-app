import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/meeting_photo.dart';

class MyMeetingsPage extends StatefulWidget {
  const MyMeetingsPage({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.meetingRepository,
    required this.loader,
  });

  final String title;
  final String emptyMessage;
  final MeetingRepository meetingRepository;
  final Future<List<Meeting>> Function() loader;

  @override
  State<MyMeetingsPage> createState() => _MyMeetingsPageState();
}

class _MyMeetingsPageState extends State<MyMeetingsPage> {
  late Future<List<Meeting>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void _reload() {
    setState(() {
      _future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Meeting>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(
              message: '모임을 불러오는 중입니다.',
              height: double.infinity,
            );
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: '모임을 불러오지 못했습니다.',
              height: double.infinity,
              onRetry: _reload,
            );
          }

          final meetings = snapshot.data ?? const [];
          if (meetings.isEmpty) {
            return AppEmptyView(
              message: widget.emptyMessage,
              height: double.infinity,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: meetings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final meeting = meetings[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    key: ValueKey('my-meeting-${meeting.id ?? index}'),
                    onTap: () async {
                      await AppRoutes.openMeetingDetail(
                        context,
                        meeting,
                        meetingRepository: widget.meetingRepository,
                      );
                      if (mounted) {
                        _reload();
                      }
                    },
                    contentPadding: const EdgeInsets.all(10),
                    leading: SizedBox(
                      width: 72,
                      child: MeetingPhoto(
                        meeting: meeting,
                        height: 64,
                        borderRadius: 12,
                        showIcon: false,
                      ),
                    ),
                    title: Text(
                      meeting.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('${meeting.date} · ${meeting.area}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
