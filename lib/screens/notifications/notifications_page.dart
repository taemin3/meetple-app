import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/app_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
  });

  final MeetingRepository meetingRepository;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _future;
  final Set<int> _readingIds = {};

  @override
  void initState() {
    super.initState();
    _future = widget.meetingRepository.getNotifications();
  }

  Future<void> _read(AppNotification item) async {
    if (!item.isRead && !_readingIds.contains(item.id)) {
      setState(() => _readingIds.add(item.id));
      try {
        await widget.meetingRepository.markNotificationRead(item.id);
        if (mounted) {
          setState(() {
            _future = widget.meetingRepository.getNotifications();
          });
        }
      } on Exception catch (error) {
        if (!mounted) return;
        final message =
            error is ApiException ? error.message : '알림을 읽음 처리하지 못했습니다.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      } finally {
        if (mounted) {
          setState(() => _readingIds.remove(item.id));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('알림을 불러오지 못했습니다.'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('새로운 알림이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final isReading = _readingIds.contains(item.id);
              return Card(
                color: item.isRead ? Colors.white : AppColors.softSurface,
                child: ListTile(
                  onTap: isReading ? null : () => _read(item),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    foregroundColor: AppColors.primary,
                    child: Icon(_iconFor(item.type)),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(item.message),
                  trailing: isReading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : item.isRead
                          ? null
                          : const CircleAvatar(
                              radius: 4,
                              backgroundColor: AppColors.primary,
                            ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.contains('APPROVED')) return Icons.check_circle_outline;
    if (type.contains('REJECTED')) return Icons.cancel_outlined;
    if (type.contains('CANCELED')) return Icons.event_busy_outlined;
    return Icons.person_add_alt;
  }
}
