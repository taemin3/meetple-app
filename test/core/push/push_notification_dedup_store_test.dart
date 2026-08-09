import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/push/push_notification_dedup_store.dart';

void main() {
  test('commits an event only after the reservation succeeds', () async {
    final store = MemoryPushNotificationDedupStore();

    final reservation = await store.reserveIfNew('event-1');
    expect(reservation, isNotNull);
    expect(await store.reserveIfNew('event-1'), isNull);

    await reservation!.commit();
    expect(await store.reserveIfNew('event-1'), isNull);
    expect(await store.reserveIfNew('event-2'), isNotNull);
  });

  test('allows the event to be reserved again after rollback', () async {
    final store = MemoryPushNotificationDedupStore();

    final reservation = await store.reserveIfNew('event-1');
    await reservation!.rollback();

    expect(await store.reserveIfNew('event-1'), isNotNull);
  });

  test('evicts the oldest event when the storage limit is exceeded', () async {
    final store = MemoryPushNotificationDedupStore(maxEventIds: 2);

    await (await store.reserveIfNew('event-1'))!.commit();
    await (await store.reserveIfNew('event-2'))!.commit();
    await (await store.reserveIfNew('event-3'))!.commit();

    expect(await store.reserveIfNew('event-2'), isNull);
    expect(await store.reserveIfNew('event-1'), isNotNull);
  });
}
