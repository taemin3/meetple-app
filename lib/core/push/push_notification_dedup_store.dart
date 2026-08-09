import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PushNotificationDedupStore {
  Future<bool> markIfNew(String eventId);
}

class SecurePushNotificationDedupStore implements PushNotificationDedupStore {
  SecurePushNotificationDedupStore({
    FlutterSecureStorage secureStorage = _defaultSecureStorage,
    int maxEventIds = 512,
  })  : assert(maxEventIds > 0),
        _secureStorage = secureStorage,
        _maxEventIds = maxEventIds;

  static const _storageKey = 'meetple.push.displayed_event_ids';
  static const _defaultSecureStorage = FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  final int _maxEventIds;
  Future<void> _operationQueue = Future<void>.value();

  @override
  Future<bool> markIfNew(String eventId) {
    final result = Completer<bool>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        result.complete(await _markIfNew(eventId));
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<bool> _markIfNew(String eventId) async {
    final eventIds = await _readEventIds();
    if (eventIds.contains(eventId)) {
      return false;
    }

    eventIds.add(eventId);
    while (eventIds.length > _maxEventIds) {
      eventIds.remove(eventIds.first);
    }
    await _secureStorage.write(
      key: _storageKey,
      value: jsonEncode(eventIds.toList(growable: false)),
    );
    return true;
  }

  Future<LinkedHashSet<String>> _readEventIds() async {
    final stored = await _secureStorage.read(key: _storageKey);
    if (stored == null || stored.isEmpty) {
      return LinkedHashSet<String>();
    }

    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) {
        return LinkedHashSet<String>();
      }
      return LinkedHashSet<String>.from(
        decoded.whereType<String>().where((eventId) => eventId.isNotEmpty),
      );
    } on FormatException {
      return LinkedHashSet<String>();
    }
  }
}

class MemoryPushNotificationDedupStore implements PushNotificationDedupStore {
  MemoryPushNotificationDedupStore({
    Iterable<String> initialEventIds = const [],
    this.maxEventIds = 512,
  })  : assert(maxEventIds > 0),
        _eventIds = LinkedHashSet<String>.from(initialEventIds);

  final int maxEventIds;
  final LinkedHashSet<String> _eventIds;

  @override
  Future<bool> markIfNew(String eventId) async {
    if (!_eventIds.add(eventId)) {
      return false;
    }
    while (_eventIds.length > maxEventIds) {
      _eventIds.remove(_eventIds.first);
    }
    return true;
  }
}
