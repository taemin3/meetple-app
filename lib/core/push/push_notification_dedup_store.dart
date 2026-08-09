import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PushNotificationDedupStore {
  Future<PushNotificationDedupReservation?> reserveIfNew(String eventId);
}

abstract interface class PushNotificationDedupReservation {
  Future<void> commit();

  Future<void> rollback();
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
  final Set<String> _reservedEventIds = {};
  Future<void> _operationQueue = Future<void>.value();

  @override
  Future<PushNotificationDedupReservation?> reserveIfNew(String eventId) {
    return _enqueue(() async {
      if (_reservedEventIds.contains(eventId)) {
        return null;
      }
      final eventIds = await _readEventIds();
      if (eventIds.contains(eventId)) {
        return null;
      }

      _reservedEventIds.add(eventId);
      return _DedupReservation(
        commitAction: () => _commit(eventId),
        rollbackAction: () => _rollback(eventId),
      );
    });
  }

  Future<void> _commit(String eventId) {
    return _enqueue(() async {
      if (!_reservedEventIds.contains(eventId)) {
        return;
      }
      try {
        final eventIds = await _readEventIds();
        eventIds.add(eventId);
        while (eventIds.length > _maxEventIds) {
          eventIds.remove(eventIds.first);
        }
        await _secureStorage.write(
          key: _storageKey,
          value: jsonEncode(eventIds.toList(growable: false)),
        );
      } finally {
        _reservedEventIds.remove(eventId);
      }
    });
  }

  Future<void> _rollback(String eventId) {
    return _enqueue(() async {
      _reservedEventIds.remove(eventId);
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
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
        _eventIds = LinkedHashSet<String>.from(initialEventIds) {
    while (_eventIds.length > maxEventIds) {
      _eventIds.remove(_eventIds.first);
    }
  }

  final int maxEventIds;
  final LinkedHashSet<String> _eventIds;
  final Set<String> _reservedEventIds = {};

  @override
  Future<PushNotificationDedupReservation?> reserveIfNew(String eventId) async {
    if (_eventIds.contains(eventId) || !_reservedEventIds.add(eventId)) {
      return null;
    }
    return _DedupReservation(
      commitAction: () async {
        if (!_reservedEventIds.remove(eventId)) {
          return;
        }
        _eventIds.add(eventId);
        while (_eventIds.length > maxEventIds) {
          _eventIds.remove(_eventIds.first);
        }
      },
      rollbackAction: () async {
        _reservedEventIds.remove(eventId);
      },
    );
  }
}

class _DedupReservation implements PushNotificationDedupReservation {
  _DedupReservation({
    required Future<void> Function() commitAction,
    required Future<void> Function() rollbackAction,
  })  : _commitAction = commitAction,
        _rollbackAction = rollbackAction;

  final Future<void> Function() _commitAction;
  final Future<void> Function() _rollbackAction;
  bool _finished = false;

  @override
  Future<void> commit() async {
    if (_finished) {
      return;
    }
    _finished = true;
    await _commitAction();
  }

  @override
  Future<void> rollback() async {
    if (_finished) {
      return;
    }
    _finished = true;
    await _rollbackAction();
  }
}
