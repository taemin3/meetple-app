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
  static const _filters = [
    _ParticipationFilter.all,
    _ParticipationFilter.pending,
    _ParticipationFilter.approved,
    _ParticipationFilter.rejected,
  ];

  _ParticipationFilter _selectedFilter = _ParticipationFilter.all;
  late int _joined;
  late Future<Map<ParticipationStatus, List<MeetingParticipation>>> _future;
  final Set<int> _reviewingIds = {};

  @override
  void initState() {
    super.initState();
    _joined = widget.meeting.joined;
    _future = _loadParticipations();
  }

  Future<Map<ParticipationStatus, List<MeetingParticipation>>>
      _loadParticipations() async {
    final results = await Future.wait([
      widget.meetingRepository.getParticipations(
        widget.meeting.id!,
        status: 'PENDING',
      ),
      widget.meetingRepository.getParticipations(
        widget.meeting.id!,
        status: 'APPROVED',
      ),
      widget.meetingRepository.getParticipations(
        widget.meeting.id!,
        status: 'REJECTED',
      ),
    ]);
    return {
      ParticipationStatus.pending: results[0],
      ParticipationStatus.approved: results[1],
      ParticipationStatus.rejected: results[2],
    };
  }

  void _reload() {
    setState(() {
      _future = _loadParticipations();
    });
  }

  void _selectFilter(_ParticipationFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
  }

  List<MeetingParticipation> _itemsFor(
    Map<ParticipationStatus, List<MeetingParticipation>> groupedItems,
  ) {
    if (_selectedFilter.status != null) {
      return groupedItems[_selectedFilter.status] ?? const [];
    }

    final items = [
      ...?groupedItems[ParticipationStatus.pending],
      ...?groupedItems[ParticipationStatus.approved],
      ...?groupedItems[ParticipationStatus.rejected],
    ];
    items.sort((left, right) {
      final leftTime = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightTime.compareTo(leftTime);
    });
    return items;
  }

  int _countFor(
    _ParticipationFilter filter,
    Map<ParticipationStatus, List<MeetingParticipation>> groupedItems,
  ) {
    if (filter.status != null) {
      return groupedItems[filter.status]?.length ?? 0;
    }
    return groupedItems.values.fold(
      0,
      (count, items) => count + items.length,
    );
  }

  Future<void> _review(
    MeetingParticipation participation, {
    required bool approve,
  }) async {
    if (_reviewingIds.contains(participation.id)) return;
    setState(() => _reviewingIds.add(participation.id));
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
        _future = _loadParticipations();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? '참여를 수락했습니다.' : '참여를 거절했습니다.')),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : '요청을 처리하지 못했습니다.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _reviewingIds.remove(participation.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text(
          '신청자 관리',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<Map<ParticipationStatus, List<MeetingParticipation>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ParticipationErrorView(onRetry: _reload);
          }

          final groupedItems = snapshot.data ?? const {};
          final items = _itemsFor(groupedItems);
          return Column(
            children: [
              _ParticipationFilterBar(
                filters: _filters,
                selectedFilter: _selectedFilter,
                countFor: (filter) => _countFor(filter, groupedItems),
                onSelected: _selectFilter,
              ),
              _ParticipationInfoBanner(filter: _selectedFilter),
              Expanded(
                child: items.isEmpty
                    ? _ParticipationEmptyView(filter: _selectedFilter)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _ParticipationApplicantCard(
                            participation: item,
                            isReviewing: _reviewingIds.contains(item.id),
                            canApprove: _joined < widget.meeting.capacity,
                            onReject: () => _review(item, approve: false),
                            onApprove: () => _review(item, approve: true),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _ParticipationFilter {
  all('전체', null),
  pending('수락 대기', ParticipationStatus.pending),
  approved('수락 완료', ParticipationStatus.approved),
  rejected('거절', ParticipationStatus.rejected);

  const _ParticipationFilter(this.label, this.status);

  final String label;
  final ParticipationStatus? status;
}

class _ParticipationFilterBar extends StatelessWidget {
  const _ParticipationFilterBar({
    required this.filters,
    required this.selectedFilter,
    required this.countFor,
    required this.onSelected,
  });

  final List<_ParticipationFilter> filters;
  final _ParticipationFilter selectedFilter;
  final int Function(_ParticipationFilter filter) countFor;
  final ValueChanged<_ParticipationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
        child: Row(
          children: [
            for (final filter in filters)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => onSelected(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: selectedFilter == filter
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${filter.label} ${countFor(filter)}',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedFilter == filter
                              ? Colors.white
                              : AppColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParticipationInfoBanner extends StatelessWidget {
  const _ParticipationInfoBanner({required this.filter});

  final _ParticipationFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _ParticipationFilter.all ||
      _ParticipationFilter.pending =>
        '신청자 수락 후, 모임 참여가 확정됩니다.',
      _ParticipationFilter.approved => '수락 완료된 신청자는 참여 멤버로 반영됩니다.',
      _ParticipationFilter.rejected => '거절한 참여 신청 내역입니다.',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipationApplicantCard extends StatelessWidget {
  const _ParticipationApplicantCard({
    required this.participation,
    required this.isReviewing,
    required this.canApprove,
    required this.onReject,
    required this.onApprove,
  });

  final MeetingParticipation participation;
  final bool isReviewing;
  final bool canApprove;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final isPending = participation.status == ParticipationStatus.pending;
    final message = participation.message?.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0EDF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1017151F),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: AppColors.softSurface,
                foregroundImage: participation.memberProfileImageUrl == null
                    ? null
                    : NetworkImage(participation.memberProfileImageUrl!),
                child: participation.memberProfileImageUrl == null
                    ? const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participation.memberNickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '신청자',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPending)
                _ParticipationStatusBadge(status: participation.status),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            '신청 시간 · ${_formatParticipationTime(participation.createdAt)}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            '참여 이유',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message?.isNotEmpty == true ? message! : '신청 메시지가 없습니다.',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 76,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: isReviewing ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '거절',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  height: 40,
                  child: FilledButton(
                    onPressed: isReviewing || !canApprove ? null : onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.line,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isReviewing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '수락',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ],
            ),
            if (!canApprove) ...[
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '모임 정원이 가득 찼습니다.',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ParticipationStatusBadge extends StatelessWidget {
  const _ParticipationStatusBadge({required this.status});

  final ParticipationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ParticipationStatus.approved => ('수락 완료', AppColors.success),
      ParticipationStatus.rejected => ('거절', AppColors.error),
      ParticipationStatus.canceled => ('취소', AppColors.muted),
      ParticipationStatus.pending => ('수락 대기', AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ParticipationEmptyView extends StatelessWidget {
  const _ParticipationEmptyView({required this.filter});

  final _ParticipationFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '${filter.label} 신청 내역이 없습니다.',
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ParticipationErrorView extends StatelessWidget {
  const _ParticipationErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '신청 내역을 불러오지 못했습니다.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

String _formatParticipationTime(DateTime? dateTime) {
  if (dateTime == null) return '시간 정보 없음';
  final local = dateTime.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}.${local.day} $hour:$minute';
}
