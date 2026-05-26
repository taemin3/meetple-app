abstract final class AppConfig {
  static const useApiRepository = bool.fromEnvironment(
    'MEETPLE_USE_API',
    defaultValue: false,
  );

  static const apiBaseUrl = String.fromEnvironment(
    'MEETPLE_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const accessToken = String.fromEnvironment(
    'MEETPLE_ACCESS_TOKEN',
    defaultValue: '',
  );
}
