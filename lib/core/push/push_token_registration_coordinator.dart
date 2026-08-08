import 'package:flutter/foundation.dart';

import '../../data/repositories/push_device_token_repository.dart';
import 'push_installation_id_store.dart';

typedef PushRetryDelay = Future<void> Function(Duration duration);

class PushTokenRegistrationCoordinator {
  PushTokenRegistrationCoordinator({
    required PushDeviceTokenRepository tokenRepository,
    required PushInstallationIdStore installationIdStore,
    required String platform,
    PushRetryDelay retryDelay = Future<void>.delayed,
  })  : _tokenRepository = tokenRepository,
        _installationIdStore = installationIdStore,
        _platform = platform,
        _retryDelay = retryDelay;

  static const _maximumRetryDelay = Duration(minutes: 1);

  final PushDeviceTokenRepository _tokenRepository;
  final PushInstallationIdStore _installationIdStore;
  final String _platform;
  final PushRetryDelay _retryDelay;

  Future<void> _registrationTail = Future<void>.value();
  Future<void>? _inFlightRegistration;
  String? _latestToken;
  String? _registeredToken;
  bool _active = false;
  int _generation = 0;

  void activate() {
    if (_active) return;
    _active = true;
    _generation += 1;
  }

  Future<void> register(String token) {
    if (!_active || token.isEmpty) {
      return Future<void>.value();
    }

    _latestToken = token;
    final generation = _generation;
    final registration = _registrationTail.then(
      (_) => _registerLatest(generation),
    );
    _registrationTail = registration.catchError((Object _) {});
    return registration;
  }

  Future<void> deactivate() async {
    _active = false;
    _generation += 1;
    _latestToken = null;
    _registeredToken = null;
    _registrationTail = Future<void>.value();

    final inFlightRegistration = _inFlightRegistration;
    if (inFlightRegistration != null) {
      try {
        await inFlightRegistration;
      } on Exception {
        // The server-side logout request still needs to run after this call.
      }
    }
  }

  Future<void> _registerLatest(int generation) async {
    var failedAttempts = 0;

    while (_isCurrentGeneration(generation)) {
      final token = _latestToken;
      if (token == null || token == _registeredToken) {
        return;
      }

      try {
        final deviceId = await _installationIdStore.readOrCreate();
        if (!_isCurrentGeneration(generation) || token != _latestToken) {
          failedAttempts = 0;
          continue;
        }

        final registration = _tokenRepository.register(
          deviceId: deviceId,
          token: token,
          platform: _platform,
        );
        _inFlightRegistration = registration;
        await registration;

        if (!_isCurrentGeneration(generation)) {
          return;
        }
        if (token == _latestToken) {
          _registeredToken = token;
          return;
        }
        failedAttempts = 0;
      } on Exception catch (error) {
        if (!_isCurrentGeneration(generation)) {
          return;
        }
        if (token != _latestToken) {
          failedAttempts = 0;
          continue;
        }

        final retryDelay = _retryDuration(failedAttempts);
        failedAttempts += 1;
        debugPrint(
          'FCM token registration failed; retrying in '
          '${retryDelay.inSeconds}s: $error',
        );
        await _retryDelay(retryDelay);
      } finally {
        _inFlightRegistration = null;
      }
    }
  }

  bool _isCurrentGeneration(int generation) {
    return _active && generation == _generation;
  }

  Duration _retryDuration(int failedAttempts) {
    final seconds = 1 << failedAttempts.clamp(0, 6);
    final duration = Duration(seconds: seconds);
    return duration > _maximumRetryDelay ? _maximumRetryDelay : duration;
  }
}
