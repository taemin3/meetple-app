class PasswordResetVerification {
  const PasswordResetVerification({
    required this.token,
    required this.expiresIn,
  });

  final String token;
  final Duration expiresIn;
}
