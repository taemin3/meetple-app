import 'dart:async';
import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import 'auth_token_store.dart';

class AuthTokenRefreshCoordinator {
  AuthTokenRefreshCoordinator({
    required ApiClient apiClient,
    required AuthTokenStore tokenStore,
    DateTime Function()? now,
    this.refreshBefore = const Duration(seconds: 30),
  })  : _apiClient = apiClient,
        _tokenStore = tokenStore,
        _now = now ?? DateTime.now;

  factory AuthTokenRefreshCoordinator.withBaseUrl({
    String baseUrl = AppConfig.apiBaseUrl,
    required AuthTokenStore tokenStore,
  }) {
    return AuthTokenRefreshCoordinator(
      apiClient: HttpApiClient(baseUri: Uri.parse(baseUrl)),
      tokenStore: tokenStore,
    );
  }

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;
  final DateTime Function() _now;
  final Duration refreshBefore;
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast(sync: true);

  Future<AuthTokenPair?>? _refreshingTokens;
  bool _refreshSuspended = false;
  int _refreshGeneration = 0;

  Stream<void> get sessionExpired => _sessionExpiredController.stream;

  Future<String?> getValidAccessToken() async {
    final tokens = await _tokenStore.read();
    if (tokens == null) {
      return null;
    }
    if (!_expiresSoon(tokens.accessToken)) {
      return tokens.accessToken;
    }

    try {
      return (await refreshTokens(
        rejectedAccessToken: tokens.accessToken,
      ))
          ?.accessToken;
    } on Exception {
      return tokens.accessToken;
    }
  }

  Future<String?> refreshAccessToken(String rejectedAccessToken) async {
    return (await refreshTokens(
      rejectedAccessToken: rejectedAccessToken,
    ))
        ?.accessToken;
  }

  Future<AuthTokenPair?> refreshTokens({
    required String rejectedAccessToken,
  }) async {
    final refreshGeneration = _refreshGeneration;
    if (_refreshSuspended) {
      return null;
    }

    final existingRefresh = _refreshingTokens;
    if (existingRefresh != null) {
      return existingRefresh;
    }

    final storedTokens = await _tokenStore.read();
    if (_refreshSuspended || refreshGeneration != _refreshGeneration) {
      return null;
    }
    final refreshStartedWhileReading = _refreshingTokens;
    if (refreshStartedWhileReading != null) {
      return refreshStartedWhileReading;
    }
    if (storedTokens == null) {
      return null;
    }
    if (storedTokens.accessToken != rejectedAccessToken) {
      return storedTokens;
    }

    final refresh = _performRefresh(storedTokens.refreshToken);
    _refreshingTokens = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshingTokens, refresh)) {
        _refreshingTokens = null;
      }
    }
  }

  Future<void> prepareForSignOut() async {
    try {
      await getValidAccessToken();
    } on Exception {
      // A transient refresh failure must not prevent the server logout attempt.
    }

    _refreshGeneration += 1;
    _refreshSuspended = true;
    final activeRefresh = _refreshingTokens;
    if (activeRefresh == null) {
      return;
    }
    try {
      await activeRefresh;
    } on Exception {
      // The stored token pair remains available for the logout request.
    }
  }

  Future<void> clearAfterSignOut() async {
    try {
      await _tokenStore.clear();
    } finally {
      _refreshSuspended = false;
    }
  }

  Future<AuthTokenPair?> _performRefresh(String refreshToken) async {
    try {
      final response = await _apiClient.postJson(
        '/api/v1/auth/reissue',
        includeAuthorization: false,
        body: {'refreshToken': refreshToken},
      );
      _ensureSuccess(response);
      final data = _readMap(response['data'], 'data');
      final tokens = AuthTokenPair(
        accessToken: _readRequiredString(data['accessToken'], 'accessToken'),
        refreshToken: _readRequiredString(
          data['refreshToken'],
          'refreshToken',
        ),
      );
      await _tokenStore.write(tokens);
      return tokens;
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
      await _expireSession();
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _tokenStore.clear();
    if (!_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }
  }

  bool _expiresSoon(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) {
        return false;
      }
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) {
        return false;
      }
      final expirationValue = payload['exp'];
      final expirationSeconds = switch (expirationValue) {
        int value => value,
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      };
      if (expirationSeconds == null) {
        return false;
      }
      final expiration = DateTime.fromMillisecondsSinceEpoch(
        expirationSeconds * 1000,
        isUtc: true,
      );
      return !expiration.isAfter(_now().toUtc().add(refreshBefore));
    } on FormatException {
      return false;
    }
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] == true) {
      return;
    }
    throw ApiException(
      statusCode: _readInt(response['status']),
      message: response['message']?.toString() ?? 'Token refresh failed.',
      body: response,
    );
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

  String _readRequiredString(Object? value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw FormatException('Token response is missing $fieldName.');
  }

  int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
