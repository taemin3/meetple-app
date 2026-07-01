abstract final class AppConfig {
  static const useApiRepository = bool.fromEnvironment(
    'MEETPLE_USE_API',
    defaultValue: false,
  );

  static const apiBaseUrl = String.fromEnvironment(
    'MEETPLE_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const naverMapClientId = String.fromEnvironment(
    'MEETPLE_NAVER_MAP_CLIENT_ID',
  );

  static bool get hasNaverMapClientId => naverMapClientId.isNotEmpty;
}
