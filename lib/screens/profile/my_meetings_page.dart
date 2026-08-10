import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/meeting_repository.dart';
import '../../models/meeting.dart';
import '../../models/meeting_list_filter.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/meeting_list_card.dart';
import '../../widgets/segmented_count_filter_bar.dart';

class MyMeetingsPage extends StatefulWidget {
  const MyMeetingsPage({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.meetingRepository,
    required this.loader,
    required this.filters,
    this.trailingBuilder,
  });

  final String title;
  final String emptyMessage;
  final MeetingRepository meetingRepository;
  final Future<List<Meeting>> Function() loader;
  final List<MeetingListFilter> filters;
  final Widget Function(Meeting meeting)? trailingBuilder;

  @override
  State<MyMeetingsPage> createState() => _MyMeetingsPageState();
}

class _MyMeetingsPageState extends State<MyMeetingsPage> {
  late Future<List<Meeting>> _future;
  late MeetingListFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    assert(widget.filters.isNotEmpty);
    _selectedFilter = widget.filters.first;
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
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(title: widget.title),
            Expanded(
              child: FutureBuilder<List<Meeting>>(
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

                  final allMeetings = snapshot.data ?? const [];
                  if (allMeetings.isEmpty) {
                    return AppEmptyView(
                      message: widget.emptyMessage,
                      height: double.infinity,
                    );
                  }
                  final meetings = allMeetings
                      .where(_selectedFilter.matches)
                      .toList(growable: false);

                  return Column(
                    children: [
                      SegmentedCountFilterBar<MeetingListFilter>(
                        items: [
                          for (final filter in widget.filters)
                            SegmentedCountFilterItem(
                              value: filter,
                              label: filter.label,
                            ),
                        ],
                        selectedValue: _selectedFilter,
                        countFor: (filter) =>
                            allMeetings.where(filter.matches).length,
                        onSelected: (filter) {
                          setState(() => _selectedFilter = filter);
                        },
                      ),
                      Expanded(
                        child: meetings.isEmpty
                            ? AppEmptyView(
                                message: _selectedFilter.emptyMessage,
                                height: double.infinity,
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  _reload();
                                  await _future;
                                },
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    24,
                                  ),
                                  itemCount: meetings.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final meeting = meetings[index];
                                    return MeetingListCard(
                                      key: ValueKey(
                                        'my-meeting-${meeting.id ?? index}',
                                      ),
                                      meeting: meeting,
                                      onTap: () async {
                                        await AppRoutes.openMeetingDetail(
                                          context,
                                          meeting,
                                          meetingRepository:
                                              widget.meetingRepository,
                                        );
                                        if (mounted) {
                                          _reload();
                                        }
                                      },
                                      trailing:
                                          widget.trailingBuilder?.call(meeting),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
