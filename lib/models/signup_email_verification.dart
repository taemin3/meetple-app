class SignupEmailVerification {
  const SignupEmailVerification({
    required this.token,
    required this.expiresIn,
  });

  final String token;
  final Duration expiresIn;
}
