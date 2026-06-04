import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    this.refreshToken,
  });

  final AuthUser user;
  final String accessToken;
  final String? refreshToken;

  bool get hasRefreshToken => refreshToken != null && refreshToken!.isNotEmpty;
}
