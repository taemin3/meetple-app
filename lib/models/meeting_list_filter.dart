import 'meeting.dart';

enum MeetingListFilter {
  all('전체', '모임이 없습니다.'),
  ongoing('진행 중', '진행 중인 모임이 없습니다.'),
  ended('종료', '종료된 모임이 없습니다.');

  const MeetingListFilter(this.label, this.emptyMessage);

  final String label;
  final String emptyMessage;

  bool matches(Meeting meeting) {
    final status = meeting.status.toUpperCase();
    return switch (this) {
      MeetingListFilter.all => true,
      MeetingListFilter.ongoing => status == 'RECRUITING' || status == 'FULL',
      MeetingListFilter.ended => status == 'COMPLETED' || status == 'CANCELED',
    };
  }
}
