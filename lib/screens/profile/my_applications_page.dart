import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../models/meeting_engagement.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/surface_panel.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({
    super.key,
    required this.meetingRepository,
  });

  final MeetingRepository meetingRepository;

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  late Future<List<MeetingParticipation>> _future;
  ParticipationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _future = widget.meetingRepository.getMyApplications();
  }

  void _reload() {
    setState(() {
      _future = widget.meetingRepository.getMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 신청 내역')),
      body: Column(
        children: [
          _ApplicationFilters(
            selectedStatus: _selectedStatus,
            onSelected: (status) => setState(() => _selectedStatus = status),
          ),
          Expanded(
            child: FutureBuilder<List<MeetingParticipation>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const AppLoadingView(
                    message: '신청 내역을 불러오는 중입니다.',
                    height: double.infinity,
                  );
                }
                if (snapshot.hasError) {
                  return AppErrorView(
                    message: '신청 내역을 불러오지 못했습니다.',
                    height: double.infinity,
                    onRetry: _reload,
                  );
                }

                final applications = (snapshot.data ?? const [])
                    .where(
                      (item) =>
                          _selectedStatus == null ||
                          item.status == _selectedStatus,
                    )
                    .toList(growable: false);
                if (applications.isEmpty) {
                  return const AppEmptyView(
                    message: '해당하는 신청 내역이 없습니다.',
                    height: double.infinity,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: applications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _ApplicationCard(
                      application: applications[index],
                      onTap: () => _openMeeting(applications[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMeeting(MeetingParticipation application) async {
    final meetingId = application.meetingId;
    if (meetingId == null) {
      return;
    }

    try {
      final meeting = await widget.meetingRepository.findById(meetingId);
      if (!mounted) {
        return;
      }
      await AppRoutes.openMeetingDetail(
        context,
        meeting,
        meetingRepository: widget.meetingRepository,
      );
      if (mounted) {
        _reload();
      }
    } on Exception {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모임 정보를 불러오지 못했습니다.')),
      );
    }
  }
}

class _ApplicationFilters extends StatelessWidget {
  const _ApplicationFilters({
    required this.selectedStatus,
    required this.onSelected,
  });

  final ParticipationStatus? selectedStatus;
  final ValueChanged<ParticipationStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = <(String, ParticipationStatus?)>[
      ('전체', null),
      ('대기', ParticipationStatus.pending),
      ('승인', ParticipationStatus.approved),
      ('거절', ParticipationStatus.rejected),
      ('취소', ParticipationStatus.canceled),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          for (final filter in filters) ...[
            ChoiceChip(
              label: Text(filter.$1),
              selected: selectedStatus == filter.$2,
              onSelected: (_) => onSelected(filter.$2),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onTap,
  });

  final MeetingParticipation application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(application.status);
    return SurfacePanel(
      child: InkWell(
        key: ValueKey('my-application-${application.id}'),
        onTap: application.meetingId == null ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.meetingTitle ?? '모임 정보',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: status.$2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      status.$1,
                      style: TextStyle(
                        color: status.$3,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              if (application.message case final message?
                  when message.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
              if (application.createdAt case final createdAt?) ...[
                const SizedBox(height: 10),
                Text(
                  '신청일 ${createdAt.year}.${_twoDigits(createdAt.month)}.${_twoDigits(createdAt.day)}',
                  style: const TextStyle(
                    color: AppColors.subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (String, Color, Color) _statusStyle(ParticipationStatus status) {
    return switch (status) {
      ParticipationStatus.pending => (
          '대기 중',
          AppColors.softSurface,
          AppColors.primary,
        ),
      ParticipationStatus.approved => (
          '승인',
          const Color(0xFFE8F7EF),
          const Color(0xFF268A58),
        ),
      ParticipationStatus.rejected => (
          '거절',
          const Color(0xFFFFECEC),
          AppColors.error,
        ),
      ParticipationStatus.canceled => (
          '취소',
          const Color(0xFFF1F2F5),
          AppColors.muted,
        ),
    };
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
