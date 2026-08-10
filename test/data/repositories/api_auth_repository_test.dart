import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/api_auth_repository.dart';
import 'package:meetple/data/repositories/auth_repository.dart';
import 'package:meetple/data/repositories/auth_token_refresh_coordinator.dart';
import 'package:meetple/data/repositories/auth_token_store.dart';

void main() {
  test('signs in with backend login and profile APIs', () async {
    final tokenStore = MemoryAuthTokenStore();
    final apiClient = FakeApiClient(
      responses: [
        _apiResponse(
          data: {
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
            'tokenType': 'Bearer',
          },
        ),
        _apiResponse(data: _profileJson()),
      ],
    );
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    final session = await repository.signIn(
      email: ' user@example.com ',
      password: 'password123',
    );

    expect(apiClient.requests, hasLength(2));
    expect(apiClient.requests[0].method, 'POST');
    expect(apiClient.requests[0].path, '/api/v1/auth/login');
    expect(apiClient.requests[0].includeAuthorization, isFalse);
    expect(apiClient.requests[0].body, {
      'email': 'user@example.com',
      'password': 'password123',
    });
    expect(apiClient.requests[1].method, 'GET');
    expect(apiClient.requests[1].path, '/api/v1/users/me');
    expect(session.accessToken, 'access-token');
    expect(session.refreshToken, 'refresh-token');
    expect(session.user.id, 1);
    expect(session.user.email, 'user@example.com');
    expect(session.user.nickname, '민지');
    expect(session.user.createdMeetingsCount, 3);
    expect(session.user.joinedMeetingsCount, 4);
    expect(session.user.likedMeetingsCount, 5);
    expect((await tokenStore.read())?.accessToken, 'access-token');
  });

  test('clears issued tokens when profile API fails after sign in', () async {
    final tokenStore = MemoryAuthTokenStore();
    final apiClient = FakeApiClient(
      responses: [
        _apiResponse(
          data: {
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
          },
        ),
        const ApiException(statusCode: 500, message: 'Profile failed'),
      ],
    );
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    await expectLater(
      repository.signIn(
        email: 'user@example.com',
        password: 'password123',
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Profile failed',
        ),
      ),
    );
    expect(await tokenStore.read(), isNull);
  });

  test('rejects blank sign in fields before sending API request', () async {
    final apiClient = FakeApiClient(responses: []);
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: MemoryAuthTokenStore(),
    );

    await expectLater(
      repository.signIn(email: ' ', password: 'password123'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          '이메일을 입력해 주세요.',
        ),
      ),
    );
    await expectLater(
      repository.signIn(email: 'user@example.com', password: '   '),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          '비밀번호를 입력해 주세요.',
        ),
      ),
    );
    expect(apiClient.requests, isEmpty);
  });

  test('signs up and then signs in to create an app session', () async {
    final apiClient = FakeApiClient(
      responses: [
        _apiResponse(
          status: 201,
          data: {
            'id': 2,
            'email': 'new@example.com',
            'nickname': '새회원',
          },
        ),
        _apiResponse(
          data: {
            'accessToken': 'new-access-token',
            'refreshToken': 'new-refresh-token',
          },
        ),
        _apiResponse(
          data: _profileJson(
            id: 2,
            email: 'new@example.com',
            nickname: '새회원',
          ),
        ),
      ],
    );
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: MemoryAuthTokenStore(),
    );

    final session = await repository.signUp(
      nickname: ' 새회원 ',
      email: ' new@example.com ',
      password: 'password123',
    );

    expect(apiClient.requests.map((request) => request.path), [
      '/api/v1/auth/signup',
      '/api/v1/auth/login',
      '/api/v1/users/me',
    ]);
    expect(apiClient.requests[0].body, {
      'email': 'new@example.com',
      'password': 'password123',
      'nickname': '새회원',
    });
    expect(session.user.nickname, '새회원');
    expect(session.accessToken, 'new-access-token');
  });

  test('rejects blank sign up fields before sending API request', () async {
    final apiClient = FakeApiClient(responses: []);
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: MemoryAuthTokenStore(),
    );

    await expectLater(
      repository.signUp(
        nickname: ' ',
        email: 'new@example.com',
        password: 'password123',
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          '닉네임을 입력해 주세요.',
        ),
      ),
    );
    await expectLater(
      repository.signUp(
        nickname: '새회원',
        email: ' ',
        password: 'password123',
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          '이메일을 입력해 주세요.',
        ),
      ),
    );
    await expectLater(
      repository.signUp(
        nickname: '새회원',
        email: 'new@example.com',
        password: ' ',
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          '비밀번호를 입력해 주세요.',
        ),
      ),
    );
    expect(apiClient.requests, isEmpty);
  });

  test('restores session by reissuing tokens after unauthorized profile API',
      () async {
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'expired-access-token',
        refreshToken: 'valid-refresh-token',
      ),
    );
    final apiClient = FakeApiClient(
      responses: [
        const ApiException(statusCode: 401, message: 'Unauthorized'),
        _apiResponse(
          data: {
            'accessToken': 'reissued-access-token',
            'refreshToken': 'reissued-refresh-token',
          },
        ),
        _apiResponse(data: _profileJson()),
      ],
    );
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    final session = await repository.restoreSession();

    expect(session?.accessToken, 'reissued-access-token');
    expect(session?.refreshToken, 'reissued-refresh-token');
    expect(apiClient.requests.map((request) => request.path), [
      '/api/v1/users/me',
      '/api/v1/auth/reissue',
      '/api/v1/users/me',
    ]);
    expect(apiClient.requests[1].includeAuthorization, isFalse);
    expect(apiClient.requests[1].body, {
      'refreshToken': 'valid-refresh-token',
    });
    expect((await tokenStore.read())?.accessToken, 'reissued-access-token');
  });

  test('restores with the current token when proactive reissue fails',
      () async {
    final accessToken = _jwt(
      expiresAt: DateTime.utc(2026, 8, 10, 12, 0, 20),
    );
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: AuthTokenPair(
        accessToken: accessToken,
        refreshToken: 'refresh-token',
      ),
    );
    final requestedPaths = <String>[];
    final httpClient = MockClient((request) async {
      requestedPaths.add(request.url.path);
      if (request.url.path == '/api/v1/auth/reissue') {
        return http.Response(
          jsonEncode({'message': 'Refresh failed'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
      expect(request.url.path, '/api/v1/users/me');
      expect(request.headers['Authorization'], 'Bearer $accessToken');
      return http.Response(
        jsonEncode(_apiResponse(data: _profileJson())),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final refreshCoordinator = AuthTokenRefreshCoordinator(
      apiClient: HttpApiClient(
        baseUri: Uri.parse('https://api.example.com'),
        httpClient: httpClient,
      ),
      tokenStore: tokenStore,
      now: () => DateTime.utc(2026, 8, 10, 12),
    );
    final repository = ApiAuthRepository(
      apiClient: HttpApiClient(
        baseUri: Uri.parse('https://api.example.com'),
        httpClient: httpClient,
        accessTokenProvider: refreshCoordinator.getValidAccessToken,
        unauthorizedTokenRefresher: refreshCoordinator.refreshAccessToken,
      ),
      tokenStore: tokenStore,
      tokenRefreshCoordinator: refreshCoordinator,
    );

    final session = await repository.restoreSession();

    expect(session?.accessToken, accessToken);
    expect(requestedPaths, [
      '/api/v1/auth/reissue',
      '/api/v1/users/me',
    ]);
    expect((await tokenStore.read())?.accessToken, accessToken);
  });

  test('uses tokens rotated while restoring the current profile', () async {
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'old-access-token',
        refreshToken: 'old-refresh-token',
      ),
    );
    final apiClient = _TokenUpdatingApiClient(
      tokenStore: tokenStore,
      updatedTokens: const AuthTokenPair(
        accessToken: 'rotated-access-token',
        refreshToken: 'rotated-refresh-token',
      ),
      responses: [_apiResponse(data: _profileJson())],
    );
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    final session = await repository.restoreSession();

    expect(session?.accessToken, 'rotated-access-token');
    expect(session?.refreshToken, 'rotated-refresh-token');
  });

  test('preserves current session when profile refresh fails transiently',
      () async {
    final tokenStore = MemoryAuthTokenStore();
    final apiClient = FakeApiClient(
      responses: [
        _apiResponse(
          data: {
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
          },
        ),
        _apiResponse(data: _profileJson()),
        const ApiException(statusCode: 500, message: 'Profile failed'),
      ],
    );
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );
    final session = await repository.signIn(
      email: 'user@example.com',
      password: 'password123',
    );

    await expectLater(
      repository.refreshSession(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          500,
        ),
      ),
    );

    expect(await repository.restoreSession(), same(session));
    expect((await tokenStore.read())?.accessToken, 'access-token');
    expect(apiClient.requests.map((request) => request.path), [
      '/api/v1/auth/login',
      '/api/v1/users/me',
      '/api/v1/users/me',
    ]);
  });

  test('clears current session when refresh token is also unauthorized',
      () async {
    final tokenStore = MemoryAuthTokenStore();
    final apiClient = FakeApiClient(
      responses: [
        _apiResponse(
          data: {
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
          },
        ),
        _apiResponse(data: _profileJson()),
        const ApiException(statusCode: 401, message: 'Unauthorized'),
        const ApiException(statusCode: 401, message: 'Refresh unauthorized'),
      ],
    );
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );
    await repository.signIn(
      email: 'user@example.com',
      password: 'password123',
    );

    final session = await repository.refreshSession();

    expect(session, isNull);
    expect(await tokenStore.read(), isNull);
    expect(apiClient.requests.map((request) => request.path), [
      '/api/v1/auth/login',
      '/api/v1/users/me',
      '/api/v1/users/me',
      '/api/v1/auth/reissue',
    ]);
  });

  test('signs out through backend logout API and clears tokens', () async {
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final apiClient = FakeApiClient(responses: [_apiResponse(data: null)]);
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    await repository.signOut();

    expect(apiClient.requests.single.path, '/api/v1/auth/logout');
    expect(apiClient.requests.single.includeAuthorization, isTrue);
    expect(apiClient.requests.single.body, {'refreshToken': 'refresh-token'});
    expect(await tokenStore.read(), isNull);
  });

  test('signs out with the rotated refresh token after proactive refresh',
      () async {
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: AuthTokenPair(
        accessToken: _jwt(expiresAt: DateTime.utc(2026, 8, 10, 11)),
        refreshToken: 'old-refresh-token',
      ),
    );
    final refreshApiClient = FakeApiClient(
      responses: [
        _apiResponse(
          data: {
            'accessToken': 'new-access-token',
            'refreshToken': 'new-refresh-token',
          },
        ),
      ],
    );
    final logoutApiClient = FakeApiClient(
      responses: [_apiResponse(data: null)],
    );
    final repository = ApiAuthRepository(
      apiClient: logoutApiClient,
      tokenStore: tokenStore,
      tokenRefreshCoordinator: AuthTokenRefreshCoordinator(
        apiClient: refreshApiClient,
        tokenStore: tokenStore,
        now: () => DateTime.utc(2026, 8, 10, 12),
      ),
    );

    await repository.signOut();

    expect(refreshApiClient.requests.single.path, '/api/v1/auth/reissue');
    expect(logoutApiClient.requests.single.body, {
      'refreshToken': 'new-refresh-token',
    });
    expect(await tokenStore.read(), isNull);
  });

  test('still requests server logout when proactive refresh fails transiently',
      () async {
    final accessToken = _jwt(
      expiresAt: DateTime.utc(2026, 8, 10, 12, 0, 20),
    );
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: AuthTokenPair(
        accessToken: accessToken,
        refreshToken: 'refresh-token',
      ),
    );
    final refreshApiClient = FakeApiClient(
      responses: [
        const ApiException(statusCode: 500, message: 'Refresh failed'),
      ],
    );
    final logoutApiClient = FakeApiClient(
      responses: [_apiResponse(data: null)],
    );
    final repository = ApiAuthRepository(
      apiClient: logoutApiClient,
      tokenStore: tokenStore,
      tokenRefreshCoordinator: AuthTokenRefreshCoordinator(
        apiClient: refreshApiClient,
        tokenStore: tokenStore,
        now: () => DateTime.utc(2026, 8, 10, 12),
      ),
    );

    await repository.signOut();

    expect(refreshApiClient.requests.single.path, '/api/v1/auth/reissue');
    expect(logoutApiClient.requests.single.body, {
      'refreshToken': 'refresh-token',
    });
    expect(await tokenStore.read(), isNull);
  });

  test('includes the installation ID when signing out', () async {
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final apiClient = FakeApiClient(responses: [_apiResponse(data: null)]);
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
      logoutDeviceIdProvider: () async => 'installation-1',
    );

    await repository.signOut();

    expect(apiClient.requests.single.body, {
      'refreshToken': 'refresh-token',
      'deviceId': 'installation-1',
    });
    expect(await tokenStore.read(), isNull);
  });

  test('deactivates local push before signing out', () async {
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final apiClient = FakeApiClient(responses: [_apiResponse(data: null)]);
    var pushDeactivated = false;
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
      beforeSignOut: () async {
        expect(apiClient.requests, isEmpty);
        pushDeactivated = true;
      },
    );

    await repository.signOut();

    expect(pushDeactivated, isTrue);
    expect(apiClient.requests.single.path, '/api/v1/auth/logout');
  });

  test('continues server logout when local push deactivation fails', () async {
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final apiClient = FakeApiClient(responses: [_apiResponse(data: null)]);
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
      beforeSignOut: () async => throw Exception('FCM cleanup failure'),
    );

    await repository.signOut();

    expect(apiClient.requests.single.path, '/api/v1/auth/logout');
    expect(await tokenStore.read(), isNull);
  });

  test('still signs out when the installation ID cannot be read', () async {
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final apiClient = FakeApiClient(responses: [_apiResponse(data: null)]);
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
      logoutDeviceIdProvider: () async => throw Exception('storage failure'),
    );

    await repository.signOut();

    expect(apiClient.requests.single.body, {'refreshToken': 'refresh-token'});
    expect(await tokenStore.read(), isNull);
  });

  test('checks logout API envelope before completing sign out', () async {
    final tokenStore = MemoryAuthTokenStore(
      initialTokens: const AuthTokenPair(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      ),
    );
    final apiClient = FakeApiClient(
      responses: [
        {
          'status': 400,
          'success': false,
          'message': '로그아웃에 실패했습니다.',
        },
      ],
    );
    final repository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );

    await expectLater(
      repository.signOut(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '로그아웃에 실패했습니다.',
        ),
      ),
    );
    expect(apiClient.requests.single.path, '/api/v1/auth/logout');
    expect(await tokenStore.read(), isNull);
  });

  test('maps unsuccessful API envelope to AuthException', () {
    final repository = ApiAuthRepository(
      apiClient: FakeApiClient(
        responses: [
          {
            'status': 400,
            'success': false,
            'message': '이메일 또는 비밀번호를 확인해 주세요.',
          },
        ],
      ),
      tokenStore: MemoryAuthTokenStore(),
    );

    expect(
      repository.signIn(email: 'user@example.com', password: 'password123'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          '이메일 또는 비밀번호를 확인해 주세요.',
        ),
      ),
    );
  });
}

Map<String, dynamic> _apiResponse({
  int status = 200,
  Object? data = const {},
}) {
  return {
    'status': status,
    'success': true,
    'code': status == 201 ? 2010 : 2000,
    'message': 'OK',
    if (data != null) 'data': data,
  };
}

Map<String, dynamic> _profileJson({
  int id = 1,
  String email = 'user@example.com',
  String nickname = '민지',
}) {
  return {
    'id': id,
    'email': email,
    'nickname': nickname,
    'profileImageUrl': 'https://example.com/profile.png',
    'region': '서울',
    'role': 'USER',
    'createdMeetingsCount': 3,
    'joinedMeetingsCount': 4,
    'likedMeetingsCount': 5,
  };
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

class RecordedApiRequest {
  const RecordedApiRequest({
    required this.method,
    required this.path,
    required this.queryParameters,
    required this.body,
    required this.includeAuthorization,
  });

  final String method;
  final String path;
  final Map<String, String?> queryParameters;
  final Map<String, dynamic> body;
  final bool includeAuthorization;
}

class FakeApiClient extends ApiClient {
  FakeApiClient({required List<Object> responses}) : _responses = responses;

  final List<Object> _responses;
  final requests = <RecordedApiRequest>[];
  int _nextResponseIndex = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    requests.add(
      RecordedApiRequest(
        method: 'GET',
        path: path,
        queryParameters: queryParameters,
        body: const {},
        includeAuthorization: true,
      ),
    );

    return _nextResponse();
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  }) async {
    requests.add(
      RecordedApiRequest(
        method: 'POST',
        path: path,
        queryParameters: const {},
        body: body,
        includeAuthorization: includeAuthorization,
      ),
    );

    return _nextResponse();
  }

  Map<String, dynamic> _nextResponse() {
    final response = _responses[_nextResponseIndex++];
    if (response is Exception) {
      throw response;
    }

    return response as Map<String, dynamic>;
  }
}

class _TokenUpdatingApiClient extends FakeApiClient {
  _TokenUpdatingApiClient({
    required this.tokenStore,
    required this.updatedTokens,
    required super.responses,
  });

  final AuthTokenStore tokenStore;
  final AuthTokenPair updatedTokens;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    await tokenStore.write(updatedTokens);
    return super.getJson(path, queryParameters: queryParameters);
  }
}
