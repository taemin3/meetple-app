abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'MEETPLE_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
