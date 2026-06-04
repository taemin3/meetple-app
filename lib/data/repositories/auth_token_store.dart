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
