import '../core/config/app_config.dart';
import '../core/push/push_installation_id_store.dart';
import '../core/push/push_notification_service.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/api_category_repository.dart';
import '../data/repositories/api_chat_repository.dart';
import '../data/repositories/api_image_upload_repository.dart';
import '../data/repositories/api_location_repository.dart';
import '../data/repositories/api_meeting_repository.dart';
import '../data/repositories/api_notification_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/auth_token_refresh_coordinator.dart';
import '../data/repositories/auth_token_store.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/image_upload_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_notification_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/mock_category_repository.dart';
import '../data/repositories/mock_chat_repository.dart';
import '../data/repositories/mock_image_upload_repository.dart';
import '../data/repositories/mock_location_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';
import '../data/repositories/push_device_token_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/realtime/chat_realtime_client.dart';
import '../data/realtime/mock_chat_realtime_client.dart';
import '../data/realtime/stomp_chat_realtime_client.dart';

const AuthTokenStore _apiAuthTokenStore = FlutterSecureAuthTokenStore();
final AuthTokenRefreshCoordinator _apiAuthTokenRefreshCoordinator =
    AuthTokenRefreshCoordinator.withBaseUrl(
  tokenStore: _apiAuthTokenStore,
);

Stream<void> get apiAuthSessionExpired =>
    _apiAuthTokenRefreshCoordinator.sessionExpired;

AuthTokenRefreshCoordinator _resolveTokenRefreshCoordinator({
  required String apiBaseUrl,
  required AuthTokenStore tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
}) {
  if (tokenRefreshCoordinator != null) {
    return tokenRefreshCoordinator;
  }
  if (identical(tokenStore, _apiAuthTokenStore) &&
      apiBaseUrl == AppConfig.apiBaseUrl) {
    return _apiAuthTokenRefreshCoordinator;
  }
  return AuthTokenRefreshCoordinator.withBaseUrl(
    baseUrl: apiBaseUrl,
    tokenStore: tokenStore,
  );
}

AuthRepository createAuthRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
  LogoutDeviceIdProvider? logoutDeviceIdProvider,
  BeforeSignOut? beforeSignOut,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
    final resolvedTokenRefreshCoordinator = _resolveTokenRefreshCoordinator(
      apiBaseUrl: apiBaseUrl,
      tokenStore: resolvedTokenStore,
      tokenRefreshCoordinator: tokenRefreshCoordinator,
    );
    return ApiAuthRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      tokenStore: resolvedTokenStore,
      tokenRefreshCoordinator: resolvedTokenRefreshCoordinator,
      logoutDeviceIdProvider: logoutDeviceIdProvider,
      beforeSignOut: beforeSignOut,
    );
  }

  return MockAuthRepository();
}

PushNotificationService createPushNotificationService({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
  PushInstallationIdStore? installationIdStore,
}) {
  if (!useApiRepository || !supportsFirebasePush) {
    return const NoopPushNotificationService();
  }

  final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
  final resolvedTokenRefreshCoordinator = _resolveTokenRefreshCoordinator(
    apiBaseUrl: apiBaseUrl,
    tokenStore: resolvedTokenStore,
    tokenRefreshCoordinator: tokenRefreshCoordinator,
  );
  return FirebasePushNotificationService(
    tokenRepository: ApiPushDeviceTokenRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: resolvedTokenRefreshCoordinator.getValidAccessToken,
      unauthorizedTokenRefresher:
          resolvedTokenRefreshCoordinator.refreshAccessToken,
    ),
    installationIdStore:
        installationIdStore ?? const SecurePushInstallationIdStore(),
  );
}

MeetingRepository createMeetingRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
    final resolvedTokenRefreshCoordinator = _resolveTokenRefreshCoordinator(
      apiBaseUrl: apiBaseUrl,
      tokenStore: resolvedTokenStore,
      tokenRefreshCoordinator: tokenRefreshCoordinator,
    );

    return ApiMeetingRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: resolvedTokenRefreshCoordinator.getValidAccessToken,
      unauthorizedTokenRefresher:
          resolvedTokenRefreshCoordinator.refreshAccessToken,
    );
  }

  return const MockMeetingRepository();
}

NotificationRepository createNotificationRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
    final resolvedTokenRefreshCoordinator = _resolveTokenRefreshCoordinator(
      apiBaseUrl: apiBaseUrl,
      tokenStore: resolvedTokenStore,
      tokenRefreshCoordinator: tokenRefreshCoordinator,
    );

    return ApiNotificationRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: resolvedTokenRefreshCoordinator.getValidAccessToken,
      unauthorizedTokenRefresher:
          resolvedTokenRefreshCoordinator.refreshAccessToken,
    );
  }

  return const MockNotificationRepository();
}

ChatRepository createChatRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
    final resolvedTokenRefreshCoordinator = _resolveTokenRefreshCoordinator(
      apiBaseUrl: apiBaseUrl,
      tokenStore: resolvedTokenStore,
      tokenRefreshCoordinator: tokenRefreshCoordinator,
    );

    return ApiChatRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: resolvedTokenRefreshCoordinator.getValidAccessToken,
      unauthorizedTokenRefresher:
          resolvedTokenRefreshCoordinator.refreshAccessToken,
    );
  }

  return const MockChatRepository();
}

ChatRealtimeClient createChatRealtimeClient({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
    final resolvedTokenRefreshCoordinator = _resolveTokenRefreshCoordinator(
      apiBaseUrl: apiBaseUrl,
      tokenStore: resolvedTokenStore,
      tokenRefreshCoordinator: tokenRefreshCoordinator,
    );

    return StompChatRealtimeClient(
      baseUrl: apiBaseUrl,
      accessTokenProvider: resolvedTokenRefreshCoordinator.getValidAccessToken,
      unauthorizedTokenRefresher:
          resolvedTokenRefreshCoordinator.refreshAccessToken,
    );
  }

  return const MockChatRealtimeClient();
}

ImageUploadRepository createImageUploadRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
    final resolvedTokenRefreshCoordinator = _resolveTokenRefreshCoordinator(
      apiBaseUrl: apiBaseUrl,
      tokenStore: resolvedTokenStore,
      tokenRefreshCoordinator: tokenRefreshCoordinator,
    );

    return ApiImageUploadRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: resolvedTokenRefreshCoordinator.getValidAccessToken,
      unauthorizedTokenRefresher:
          resolvedTokenRefreshCoordinator.refreshAccessToken,
    );
  }

  return const MockImageUploadRepository();
}

CategoryRepository createCategoryRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
    final resolvedTokenRefreshCoordinator = _resolveTokenRefreshCoordinator(
      apiBaseUrl: apiBaseUrl,
      tokenStore: resolvedTokenStore,
      tokenRefreshCoordinator: tokenRefreshCoordinator,
    );

    return ApiCategoryRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: resolvedTokenRefreshCoordinator.getValidAccessToken,
      unauthorizedTokenRefresher:
          resolvedTokenRefreshCoordinator.refreshAccessToken,
    );
  }

  return const MockCategoryRepository();
}

LocationRepository createLocationRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  AuthTokenRefreshCoordinator? tokenRefreshCoordinator,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
    final resolvedTokenRefreshCoordinator = _resolveTokenRefreshCoordinator(
      apiBaseUrl: apiBaseUrl,
      tokenStore: resolvedTokenStore,
      tokenRefreshCoordinator: tokenRefreshCoordinator,
    );

    return ApiLocationRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: resolvedTokenRefreshCoordinator.getValidAccessToken,
      unauthorizedTokenRefresher:
          resolvedTokenRefreshCoordinator.refreshAccessToken,
    );
  }

  return const MockLocationRepository();
}
