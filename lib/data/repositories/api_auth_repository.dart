import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/auth_session.dart';
import '../../models/auth_user.dart';
import 'auth_repository.dart';
import 'auth_token_store.dart';

typedef LogoutDeviceIdProvider = Future<String?> Function();

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient apiClient,
    required AuthTokenStore tokenStore,
    LogoutDeviceIdProvider? logoutDeviceIdProvider,
  })  : _apiClient = apiClient,
        _tokenStore = tokenStore,
        _logoutDeviceIdProvider = logoutDeviceIdProvider;

  factory ApiAuthRepository.withBaseUrl({
    String baseUrl = AppConfig.apiBaseUrl,
    AuthTokenStore? tokenStore,
    LogoutDeviceIdProvider? logoutDeviceIdProvider,
  }) {
    final resolvedTokenStore =
        tokenStore ?? const FlutterSecureAuthTokenStore();

    return ApiAuthRepository(
      apiClient: HttpApiClient(
        baseUri: Uri.parse(baseUrl),
        accessTokenProvider: () async {
          final tokens = await resolvedTokenStore.read();
          return tokens?.accessToken;
        },
      ),
      tokenStore: resolvedTokenStore,
      logoutDeviceIdProvider: logoutDeviceIdProvider,
    );
  }

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;
  final LogoutDeviceIdProvider? _logoutDeviceIdProvider;

  AuthSession? _session;

  @override
  Future<AuthSession?> restoreSession() async {
    if (_session != null) {
      return _session;
    }

    final tokens = await _tokenStore.read();
    if (tokens == null) {
      return null;
    }

    try {
      return await _restoreWithTokens(tokens);
    } on ApiException catch (error) {
      if (error.statusCode != 401 || tokens.refreshToken.isEmpty) {
        await _clearSession();
        return null;
      }

      try {
        final refreshedTokens = await _reissue(tokens.refreshToken);
        return await _restoreWithTokens(refreshedTokens);
      } on Exception {
        await _clearSession();
        return null;
      }
    } on Exception {
      await _clearSession();
      return null;
    }
  }

  @override
  Future<AuthSession?> refreshSession() async {
    final previousSession = _session;
    final tokens = await _tokenStore.read();
    if (tokens == null) {
      return previousSession;
    }

    try {
      return await _restoreWithTokens(tokens, clearOnFailure: false);
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        _session = previousSession;
        rethrow;
      }
      if (tokens.refreshToken.isEmpty) {
        await _clearSession();
        return null;
      }

      try {
        final refreshedTokens = await _reissue(tokens.refreshToken);
        return await _restoreWithTokens(
          refreshedTokens,
          clearOnFailure: false,
        );
      } on ApiException catch (refreshError) {
        if (refreshError.statusCode == 401) {
          await _clearSession();
          return null;
        }
        _session = previousSession;
        rethrow;
      } on Exception {
        _session = previousSession;
        rethrow;
      }
    } on Exception {
      _session = previousSession;
      rethrow;
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
    _ensureNotBlank(password, '비밀번호를 입력해 주세요.');

    try {
      final tokens = await _login(email: email, password: password);
      return await _restoreWithTokens(tokens);
    } on AuthException {
      rethrow;
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } on FormatException {
      throw const AuthException('인증 응답 형식이 올바르지 않습니다.');
    }
  }

  @override
  Future<AuthSession> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    _ensureNotBlank(nickname, '닉네임을 입력해 주세요.');
    _ensureNotBlank(email, '이메일을 입력해 주세요.');
    _ensureNotBlank(password, '비밀번호를 입력해 주세요.');

    try {
      final response = await _apiClient.postJson(
        '/api/v1/auth/signup',
        includeAuthorization: false,
        body: {
          'email': email.trim(),
          'password': password,
          'nickname': nickname.trim(),
        },
      );
      _ensureSuccess(response);

      return await signIn(email: email, password: password);
    } on AuthException {
      rethrow;
    } on ApiException catch (error) {
      throw AuthException(error.message);
    } on FormatException {
      throw const AuthException('회원가입 응답 형식이 올바르지 않습니다.');
    }
  }

  @override
  Future<void> signOut() async {
    final tokens = await _tokenStore.read();

    try {
      if (tokens != null && tokens.refreshToken.isNotEmpty) {
        final deviceId = await _readLogoutDeviceId();
        final response = await _apiClient.postJson(
          '/api/v1/auth/logout',
          body: {
            'refreshToken': tokens.refreshToken,
            if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
          },
        );
        _ensureSuccess(response);
      }
    } finally {
      await _clearSession();
    }
  }

  Future<String?> _readLogoutDeviceId() async {
    try {
      return await _logoutDeviceIdProvider?.call();
    } on Exception {
      return null;
    }
  }

  Future<AuthTokenPair> _login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/login',
      includeAuthorization: false,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
    final data = _readData(response);

    return _tokensFromJson(data);
  }

  Future<AuthTokenPair> _reissue(String refreshToken) async {
    final response = await _apiClient.postJson(
      '/api/v1/auth/reissue',
      includeAuthorization: false,
      body: {'refreshToken': refreshToken},
    );
    final data = _readData(response);
    final tokens = _tokensFromJson(data);
    await _tokenStore.write(tokens);

    return tokens;
  }

  Future<AuthSession> _restoreWithTokens(
    AuthTokenPair tokens, {
    bool clearOnFailure = true,
  }) async {
    await _tokenStore.write(tokens);

    try {
      final response = await _apiClient.getJson('/api/v1/users/me');
      final user = _userFromJson(_readData(response));
      final session = AuthSession(
        user: user,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      _session = session;

      return session;
    } catch (_) {
      if (clearOnFailure) {
        await _clearSession();
      }
      rethrow;
    }
  }

  Future<void> _clearSession() async {
    _session = null;
    await _tokenStore.clear();
  }

  Map<String, dynamic> _readData(Map<String, dynamic> response) {
    _ensureSuccess(response);

    return _readMap(response['data'], 'data');
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw ApiException(
        statusCode: _readInt(response['status']),
        message:
            _readString(response['message'], fallback: 'API request failed.'),
        body: response,
      );
    }
  }

  AuthTokenPair _tokensFromJson(Map<String, dynamic> json) {
    final accessToken = _readString(json['accessToken']);
    final refreshToken = _readString(json['refreshToken']);

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const FormatException('Token response is missing required fields.');
    }

    return AuthTokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  AuthUser _userFromJson(Map<String, dynamic> json) {
    final nickname = _readString(json['nickname'], fallback: 'Meetple');
    final email = _readString(json['email']);

    return AuthUser(
      id: _readInt(json['id']),
      nickname: nickname,
      handle: _handleFrom(nickname, email),
      email: email,
      profileImageUrl: _readNullableString(json['profileImageUrl']),
      createdMeetingsCount: _readInt(json['createdMeetingsCount']),
      joinedMeetingsCount: _readInt(json['joinedMeetingsCount']),
      likedMeetingsCount: _readInt(json['likedMeetingsCount']),
    );
  }

  String _handleFrom(String nickname, String email) {
    if (nickname.trim().isNotEmpty) {
      return nickname.trim();
    }

    final atIndex = email.indexOf('@');
    if (atIndex > 0) {
      return email.substring(0, atIndex);
    }

    return 'meetple';
  }

  Map<String, dynamic> _readMap(Object? value, String fieldName) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    throw FormatException('Expected $fieldName to be an object.');
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return fallback;
  }

  String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return null;
  }

  void _ensureNotBlank(String value, String message) {
    if (value.trim().isEmpty) {
      throw AuthException(message);
    }
  }
}
