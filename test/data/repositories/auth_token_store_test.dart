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
