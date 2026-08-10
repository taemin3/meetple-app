import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/auth_token_refresh_coordinator.dart';
import 'package:meetple/data/repositories/auth_token_store.dart';

void main() {
  test('keeps an access token that is not close to expiration', () async {
    final store = MemoryAuthTokenStore(
      initialTokens: AuthTokenPair(
        accessToken: _jwt(expiresAt: DateTime.utc(2026, 8, 10, 13)),
        refreshToken: 'refresh-token',
      ),
    );
    final apiClient = _RefreshApiClient();
    final coordinator = AuthTokenRefreshCoordinator(
      apiClient: apiClient,
      tokenStore: store,
      now: () => DateTime.utc(2026, 8, 10, 12),
    );

    final token = await coordinator.getValidAccessToken();

    expect(token, (await store.read())!.accessToken);
    expect(apiClient.postCount, 0);
  });

  test('uses the current access token when proactive refresh fails transiently',
      () async {
    final accessToken = _jwt(
      expiresAt: DateTime.utc(2026, 8, 10, 12, 0, 20),
    );
    final store = MemoryAuthTokenStore(
      initialTokens: AuthTokenPair(
        accessToken: accessToken,
        refreshToken: 'refresh-token',
      ),
    );
    final apiClient = _RefreshApiClient(errorStatusCode: 500);
    final coordinator = AuthTokenRefreshCoordinator(
      apiClient: apiClient,
      tokenStore: store,
      now: () => DateTime.utc(2026, 8, 10, 12),
    );

    final token = await coordinator.getValidAccessToken();

    expect(token, accessToken);
    expect((await store.read())!.accessToken, accessToken);
    expect(apiClient.postCount, 1);
  });

  test('shares one refresh request between concurrent callers', () async {
    final expiredAccessToken = _jwt(
      expiresAt: DateTime.utc(2026, 8, 10, 11),
    );
    final store = MemoryAuthTokenStore(
      initialTokens: AuthTokenPair(
        accessToken: expiredAccessToken,
        refreshToken: 'refresh-token',
      ),
    );
    final responseCompleter = Completer<Map<String, dynamic>>();
    final apiClient = _RefreshApiClient(responseCompleter: responseCompleter);
    final coordinator = AuthTokenRefreshCoordinator(
      apiClient: apiClient,
      tokenStore: store,
      now: () => DateTime.utc(2026, 8, 10, 12),
    );

    final refreshes = [
      coordinator.getValidAccessToken(),
      coordinator.refreshAccessToken(expiredAccessToken),
      coordinator.getValidAccessToken(),
    ];
    await Future<void>.delayed(Duration.zero);
    expect(apiClient.postCount, 1);

    responseCompleter.complete(_successResponse());
    expect(await Future.wait(refreshes), everyElement('new-access-token'));
    expect((await store.read())!.refreshToken, 'new-refresh-token');
    expect(apiClient.postCount, 1);
  });

  test('reuses tokens refreshed by another request', () async {
    final store = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
      ),
    );
    final apiClient = _RefreshApiClient();
    final coordinator = AuthTokenRefreshCoordinator(
      apiClient: apiClient,
      tokenStore: store,
    );

    final token = await coordinator.refreshAccessToken('old-access-token');

    expect(token, 'new-access-token');
    expect(apiClient.postCount, 0);
  });

  test('clears tokens and emits expiration when refresh is unauthorized',
      () async {
    final store = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'expired-access-token',
        refreshToken: 'expired-refresh-token',
      ),
    );
    final apiClient = _RefreshApiClient(errorStatusCode: 401);
    final coordinator = AuthTokenRefreshCoordinator(
      apiClient: apiClient,
      tokenStore: store,
    );
    final expiration = coordinator.sessionExpired.first;

    final token = await coordinator.refreshAccessToken(
      'expired-access-token',
    );

    expect(token, isNull);
    await expiration;
    expect(await store.read(), isNull);
  });

  test('preserves tokens when refresh fails transiently', () async {
    const tokens = AuthTokenPair(
      accessToken: 'expired-access-token',
      refreshToken: 'refresh-token',
    );
    final store = MemoryAuthTokenStore(initialTokens: tokens);
    final coordinator = AuthTokenRefreshCoordinator(
      apiClient: _RefreshApiClient(errorStatusCode: 500),
      tokenStore: store,
    );

    await expectLater(
      coordinator.refreshAccessToken(tokens.accessToken),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          500,
        ),
      ),
    );
    expect((await store.read())!.accessToken, tokens.accessToken);
  });

  test('waits for an active refresh before clearing tokens for sign out',
      () async {
    const tokens = AuthTokenPair(
      accessToken: 'expired-access-token',
      refreshToken: 'refresh-token',
    );
    final store = MemoryAuthTokenStore(initialTokens: tokens);
    final responseCompleter = Completer<Map<String, dynamic>>();
    final apiClient = _RefreshApiClient(responseCompleter: responseCompleter);
    final coordinator = AuthTokenRefreshCoordinator(
      apiClient: apiClient,
      tokenStore: store,
    );
    final refresh = coordinator.refreshAccessToken(tokens.accessToken);
    await Future<void>.delayed(Duration.zero);

    final preparingForSignOut = coordinator.prepareForSignOut();
    await Future<void>.delayed(Duration.zero);
    responseCompleter.complete(_successResponse());
    await preparingForSignOut;

    expect(await refresh, 'new-access-token');
    expect((await store.read())!.refreshToken, 'new-refresh-token');
    expect(
      await coordinator.refreshAccessToken('new-access-token'),
      isNull,
    );
    expect(apiClient.postCount, 1);

    await coordinator.clearAfterSignOut();

    expect(await store.read(), isNull);
  });

  test('discards a refresh that was waiting for tokens when sign out starts',
      () async {
    const tokens = AuthTokenPair(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final store = _DelayedFirstReadTokenStore(tokens);
    final apiClient = _RefreshApiClient();
    final coordinator = AuthTokenRefreshCoordinator(
      apiClient: apiClient,
      tokenStore: store,
    );
    final refresh = coordinator.refreshAccessToken(tokens.accessToken);
    await store.firstReadStarted.future;

    await coordinator.prepareForSignOut();
    await coordinator.clearAfterSignOut();
    store.releaseFirstRead.complete();

    expect(await refresh, isNull);
    expect(apiClient.postCount, 0);
    expect(await store.read(), isNull);
  });
}

String _jwt({required DateTime expiresAt}) {
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000}),
    ),
  );
  return '$header.$payload.signature';
}

Map<String, dynamic> _successResponse() => {
      'status': 200,
      'success': true,
      'data': {
        'accessToken': 'new-access-token',
        'refreshToken': 'new-refresh-token',
      },
    };

class _RefreshApiClient extends ApiClient {
  _RefreshApiClient({
    this.responseCompleter,
    this.errorStatusCode,
  });

  final Completer<Map<String, dynamic>>? responseCompleter;
  final int? errorStatusCode;
  int postCount = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  }) async {
    postCount += 1;
    expect(path, '/api/v1/auth/reissue');
    expect(includeAuthorization, isFalse);
    final statusCode = errorStatusCode;
    if (statusCode != null) {
      throw ApiException(
        statusCode: statusCode,
        message: 'refresh failed',
      );
    }
    return responseCompleter == null
        ? _successResponse()
        : await responseCompleter!.future;
  }
}

class _DelayedFirstReadTokenStore implements AuthTokenStore {
  _DelayedFirstReadTokenStore(this._tokens);

  AuthTokenPair? _tokens;
  bool _isFirstRead = true;
  final firstReadStarted = Completer<void>();
  final releaseFirstRead = Completer<void>();

  @override
  Future<AuthTokenPair?> read() async {
    final tokens = _tokens;
    if (_isFirstRead) {
      _isFirstRead = false;
      firstReadStarted.complete();
      await releaseFirstRead.future;
    }
    return tokens;
  }

  @override
  Future<void> write(AuthTokenPair tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}
