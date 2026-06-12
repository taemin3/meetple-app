import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/auth_token_store.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('reads null when secure storage has no complete token pair', () async {
    const store = FlutterSecureAuthTokenStore();

    expect(await store.read(), isNull);
  });

  test('clears partial secure storage state when reading tokens', () async {
    FlutterSecureStorage.setMockInitialValues({
      'meetple.auth.access_token': 'access-token',
    });
    const store = FlutterSecureAuthTokenStore();

    expect(await store.read(), isNull);

    const secureStorage = FlutterSecureStorage();
    expect(
      await secureStorage.read(key: 'meetple.auth.access_token'),
      isNull,
    );
    expect(
      await secureStorage.read(key: 'meetple.auth.refresh_token'),
      isNull,
    );
  });

  test('writes and reads token pair from secure storage', () async {
    const store = FlutterSecureAuthTokenStore();

    await store.write(
      const AuthTokenPair(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );

    final tokens = await store.read();

    expect(tokens?.accessToken, 'access-token');
    expect(tokens?.refreshToken, 'refresh-token');
  });

  test('rolls back secure storage when token write fails halfway', () async {
    final secureStorage = _FailingSecondWriteSecureStorage();
    final store = FlutterSecureAuthTokenStore(
      secureStorage: secureStorage,
    );

    await expectLater(
      store.write(
        const AuthTokenPair(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        ),
      ),
      throwsException,
    );

    expect(secureStorage.values, isEmpty);
  });

  test('clears token pair from secure storage', () async {
    const store = FlutterSecureAuthTokenStore();

    await store.write(
      const AuthTokenPair(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    await store.clear();

    expect(await store.read(), isNull);
  });

  test('keeps memory token store available for tests and previews', () async {
    final store = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'memory-access-token',
        refreshToken: 'memory-refresh-token',
      ),
    );

    expect((await store.read())?.accessToken, 'memory-access-token');

    await store.clear();

    expect(await store.read(), isNull);
  });
}

class _FailingSecondWriteSecureStorage extends FlutterSecureStorage {
  final values = <String, String>{};
  var _writeCount = 0;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _writeCount += 1;
    if (_writeCount == 2) {
      throw Exception('write failed');
    }

    if (value == null) {
      values.remove(key);
      return;
    }

    values[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}
