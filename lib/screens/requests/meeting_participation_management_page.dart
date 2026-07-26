import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../models/meeting_engagement.dart';

class MeetingParticipationManagementPage extends StatefulWidget {
  const MeetingParticipationManagementPage({
    super.key,
    required this.meeting,
    required this.meetingRepository,
  });

  final Meeting meeting;
  final MeetingRepository meetingRepository;

  @override
  State<MeetingParticipationManagementPage> createState() =>
      _MeetingParticipationManagementPageState();
}

class _MeetingParticipationManagementPageState
    extends State<MeetingParticipationManagementPage> {
  static const _statuses = ['PENDING', 'APPROVED', 'REJECTED', 'CANCELED'];
  static const _labels = ['승인 대기', '승인', '거절', '취소'];

  int _selectedIndex = 0;
  late int _joined;
  late Future<List<MeetingParticipation>> _future;

  @override
  void initState() {
    super.initState();
    _joined = widget.meeting.joined;
    _load();
  }

  void _load() {
    _future = widget.meetingRepository.getParticipations(
      widget.meeting.id!,
      status: _statuses[_selectedIndex],
    );
  }

  void _selectStatus(int index) {
    setState(() {
      _selectedIndex = index;
      _load();
    });
  }

  Future<void> _review(
    MeetingParticipation participation, {
    required bool approve,
  }) async {
    try {
      await widget.meetingRepository.reviewParticipation(
        widget.meeting.id!,
        participation.id,
        approve: approve,
      );
      if (!mounted) return;
      setState(() {
        if (approve && _joined < widget.meeting.capacity) {
          _joined += 1;
        }
        _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? '참여를 승인했습니다.' : '참여를 거절했습니다.')),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : '요청을 처리하지 못했습니다.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.meeting.title} 신청 관리')),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _labels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ChoiceChip(
                label: Text(_labels[index]),
                selected: index == _selectedIndex,
                onSelected: (_) => _selectStatus(index),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MeetingParticipation>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('신청 내역을 불러오지 못했습니다.'));
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return Center(
                      child: Text('${_labels[_selectedIndex]} 내역이 없습니다.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      item.memberProfileImageUrl == null
                                          ? null
                                          : NetworkImage(
                                              item.memberProfileImageUrl!,
                                            ),
                                  child: item.memberProfileImageUrl == null
                                      ? const Icon(Icons.person_outline)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.memberNickname,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.message?.trim().isNotEmpty == true
                                  ? item.message!
                                  : '신청 메시지가 없습니다.',
                              style: const TextStyle(
                                color: AppColors.muted,
                                height: 1.5,
                              ),
                            ),
                            if (_selectedIndex == 0) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _review(item, approve: false),
                                      child: const Text('거절'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _joined >=
                                              widget.meeting.capacity
                                          ? null
                                          : () => _review(item, approve: true),
                                      child: const Text('승인'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
    );
  }
}
