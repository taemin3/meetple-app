import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/meeting_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';

void main() {
  test('updates display schedule and explicitly clears meeting images',
      () async {
    const repository = MockMeetingRepository();

    final updated = await repository.updateMeetingDetails(
      1,
      UpdateMeetingInput(
        title: '저녁 러닝',
        category: '운동',
        locationName: '여의도공원',
        address: '서울 영등포구 여의공원로 68',
        latitude: 37.5268,
        longitude: 126.9228,
        scheduledAt: DateTime(2026, 8, 10, 9, 5),
        capacity: 12,
        description: '함께 달려요.',
        imageObjectKeys: const [],
      ),
    );

    expect(updated.date, '8/10');
    expect(updated.time, '09:05');
    expect(updated.scheduledAt, DateTime(2026, 8, 10, 9, 5));
    expect(updated.imageUrls, isEmpty);
    expect(updated.thumbnailImageUrl, isNull);
    expect(updated.primaryImageUrl, isNull);
  });
}
