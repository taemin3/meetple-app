import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../data/repositories/mock_meeting_repository.dart';
import '../../models/app_notification.dart';
import '../../widgets/app_page_header.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    this.meetingRepository = const MockMeetingRepository(),
    this.onMeetingChanged,
  });

  final MeetingRepository meetingRepository;
  final VoidCallback? onMeetingChanged;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _future;
  final Set<int> _readingIds = {};
  final Set<int> _openingIds = {};

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

  Future<void> _open(AppNotification item) async {
    if (_openingIds.contains(item.id)) {
      return;
    }

    setState(() => _openingIds.add(item.id));
    try {
      await _read(item);
      final meetingId = item.meetingId;
      if (meetingId == null || !mounted) {
        return;
      }

      final meeting = await widget.meetingRepository.findById(meetingId);
      if (!mounted) return;
      final result = await AppRoutes.openMeetingDetail<Object>(
        context,
        meeting,
        meetingRepository: widget.meetingRepository,
      );
      if (result != null && mounted) {
        widget.onMeetingChanged?.call();
      }
    } on Exception catch (error) {
      if (!mounted) return;
      final message =
          error is ApiException ? error.message : '모임 정보를 불러오지 못했습니다.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _openingIds.remove(item.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: '알림'),
            Expanded(
              child: FutureBuilder<List<AppNotification>>(
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
                      final isOpening = _openingIds.contains(item.id);
                      final isBusy = isReading || isOpening;
                      return Card(
                        color:
                            item.isRead ? Colors.white : AppColors.softSurface,
                        child: ListTile(
                          onTap: isBusy ? null : () => _open(item),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withOpacity(0.12),
                            foregroundColor: AppColors.primary,
                            child: Icon(_iconFor(item.type)),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(item.message),
                          trailing: isBusy
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
            ),
          ],
        ),
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
