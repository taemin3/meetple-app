import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PushInstallationIdStore {
  Future<String> readOrCreate();
}

class SecurePushInstallationIdStore implements PushInstallationIdStore {
  const SecurePushInstallationIdStore({
    FlutterSecureStorage secureStorage = _defaultSecureStorage,
  }) : _secureStorage = secureStorage;

  static const _storageKey = 'meetple.push.installation_id';
  static const _defaultSecureStorage = FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String> readOrCreate() async {
    final stored = await _secureStorage.read(key: _storageKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    final created = _newUuidV4();
    await _secureStorage.write(key: _storageKey, value: created);
    return created;
  }

  String _newUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

class MemoryPushInstallationIdStore implements PushInstallationIdStore {
  MemoryPushInstallationIdStore([this._value = 'test-installation-id']);

  final String _value;

  @override
  Future<String> readOrCreate() async => _value;
}
