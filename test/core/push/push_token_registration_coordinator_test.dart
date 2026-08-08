import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/push/push_installation_id_store.dart';
import 'package:meetple/core/push/push_token_registration_coordinator.dart';
import 'package:meetple/data/repositories/push_device_token_repository.dart';

void main() {
  test('retries a failed token registration with exponential backoff',
      () async {
    final retryDelays = <Duration>[];
    final repository = _CallbackTokenRepository((call) async {
      if (call.attempt < 3) {
        throw Exception('temporary failure');
      }
    });
    final coordinator = PushTokenRegistrationCoordinator(
      tokenRepository: repository,
      installationIdStore: MemoryPushInstallationIdStore('installation-1'),
      platform: 'ANDROID',
      retryDelay: (duration) async => retryDelays.add(duration),
    );

    coordinator.activate();
    await coordinator.register('token-1');

    expect(repository.calls, hasLength(3));
    expect(retryDelays, const [Duration(seconds: 1), Duration(seconds: 2)]);
  });

  test('serializes registrations and leaves the newest token last', () async {
    final repository = _DeferredTokenRepository();
    final coordinator = PushTokenRegistrationCoordinator(
      tokenRepository: repository,
      installationIdStore: MemoryPushInstallationIdStore('installation-1'),
      platform: 'ANDROID',
    );

    coordinator.activate();
    final firstRegistration = coordinator.register('old-token');
    await _flushMicrotasks();
    expect(repository.tokens, ['old-token']);

    final secondRegistration = coordinator.register('new-token');
    await _flushMicrotasks();
    expect(repository.tokens, ['old-token']);

    repository.completeNext();
    await _flushMicrotasks();
    expect(repository.tokens, ['old-token', 'new-token']);

    repository.completeNext();
    await Future.wait([firstRegistration, secondRegistration]);
    expect(repository.tokens.last, 'new-token');
  });

  test('stops retrying after deactivation', () async {
    final retryStarted = Completer<void>();
    final releaseRetry = Completer<void>();
    final repository = _CallbackTokenRepository((call) async {
      throw Exception('temporary failure');
    });
    final coordinator = PushTokenRegistrationCoordinator(
      tokenRepository: repository,
      installationIdStore: MemoryPushInstallationIdStore('installation-1'),
      platform: 'ANDROID',
      retryDelay: (_) {
        retryStarted.complete();
        return releaseRetry.future;
      },
    );

    coordinator.activate();
    final registration = coordinator.register('token-1');
    await retryStarted.future;

    await coordinator.deactivate();
    releaseRetry.complete();
    await registration;

    expect(repository.calls, hasLength(1));
  });

  test('does not start registration after deactivation during ID read',
      () async {
    final installationIdStore = _DeferredInstallationIdStore();
    final repository = _CallbackTokenRepository((call) async {});
    final coordinator = PushTokenRegistrationCoordinator(
      tokenRepository: repository,
      installationIdStore: installationIdStore,
      platform: 'ANDROID',
    );

    coordinator.activate();
    final registration = coordinator.register('token-1');
    await installationIdStore.readStarted.future;

    await coordinator.deactivate();
    installationIdStore.complete('installation-1');
    await registration;

    expect(repository.calls, isEmpty);
  });
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _TokenRegistrationCall {
  const _TokenRegistrationCall({
    required this.attempt,
    required this.deviceId,
    required this.token,
    required this.platform,
  });

  final int attempt;
  final String deviceId;
  final String token;
  final String platform;
}

class _CallbackTokenRepository implements PushDeviceTokenRepository {
  _CallbackTokenRepository(this.onRegister);

  final Future<void> Function(_TokenRegistrationCall call) onRegister;
  final calls = <_TokenRegistrationCall>[];

  @override
  Future<void> register({
    required String deviceId,
    required String token,
    required String platform,
  }) {
    final call = _TokenRegistrationCall(
      attempt: calls.length + 1,
      deviceId: deviceId,
      token: token,
      platform: platform,
    );
    calls.add(call);
    return onRegister(call);
  }
}

class _DeferredTokenRepository implements PushDeviceTokenRepository {
  final tokens = <String>[];
  final _pending = <Completer<void>>[];

  @override
  Future<void> register({
    required String deviceId,
    required String token,
    required String platform,
  }) {
    tokens.add(token);
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext() {
    _pending.removeAt(0).complete();
  }
}

class _DeferredInstallationIdStore implements PushInstallationIdStore {
  final readStarted = Completer<void>();
  final _value = Completer<String>();

  @override
  Future<String> readOrCreate() {
    readStarted.complete();
    return _value.future;
  }

  void complete(String value) {
    _value.complete(value);
  }
}
