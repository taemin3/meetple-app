import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/push/push_notification_dedup_store.dart';

void main() {
  test('marks an event only once', () async {
    final store = MemoryPushNotificationDedupStore();

    expect(await store.markIfNew('event-1'), isTrue);
    expect(await store.markIfNew('event-1'), isFalse);
    expect(await store.markIfNew('event-2'), isTrue);
  });

  test('evicts the oldest event when the storage limit is exceeded', () async {
    final store = MemoryPushNotificationDedupStore(maxEventIds: 2);

    expect(await store.markIfNew('event-1'), isTrue);
    expect(await store.markIfNew('event-2'), isTrue);
    expect(await store.markIfNew('event-3'), isTrue);

    expect(await store.markIfNew('event-2'), isFalse);
    expect(await store.markIfNew('event-1'), isTrue);
  });
}
