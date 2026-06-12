import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenPair {
  const AuthTokenPair({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

abstract interface class AuthTokenStore {
  Future<AuthTokenPair?> read();

  Future<void> write(AuthTokenPair tokens);

  Future<void> clear();
}

class FlutterSecureAuthTokenStore implements AuthTokenStore {
  const FlutterSecureAuthTokenStore({
    FlutterSecureStorage secureStorage = _defaultSecureStorage,
  }) : _secureStorage = secureStorage;

  static const _accessTokenKey = 'meetple.auth.access_token';
  static const _refreshTokenKey = 'meetple.auth.refresh_token';
  static const _defaultSecureStorage = FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  Future<AuthTokenPair?> read() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    return AuthTokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> write(AuthTokenPair tokens) async {
    await Future.wait([
      _secureStorage.write(
        key: _accessTokenKey,
        value: tokens.accessToken,
      ),
      _secureStorage.write(
        key: _refreshTokenKey,
        value: tokens.refreshToken,
      ),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
    ]);
  }
}

class MemoryAuthTokenStore implements AuthTokenStore {
  MemoryAuthTokenStore({AuthTokenPair? initialTokens})
      : _tokens = initialTokens;

  AuthTokenPair? _tokens;

  @override
  Future<AuthTokenPair?> read() async {
    return _tokens;
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
