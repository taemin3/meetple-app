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

AuthRepository createAuthRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
  LogoutDeviceIdProvider? logoutDeviceIdProvider,
  BeforeSignOut? beforeSignOut,
}) {
  if (useApiRepository) {
    return ApiAuthRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      tokenStore: tokenStore ?? _apiAuthTokenStore,
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
  PushInstallationIdStore? installationIdStore,
}) {
  if (!useApiRepository || !supportsFirebasePush) {
    return const NoopPushNotificationService();
  }

  final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;
  return FirebasePushNotificationService(
    tokenRepository: ApiPushDeviceTokenRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: () async {
        final tokens = await resolvedTokenStore.read();
        return tokens?.accessToken;
      },
    ),
    installationIdStore:
        installationIdStore ?? const SecurePushInstallationIdStore(),
  );
}

MeetingRepository createMeetingRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;

    return ApiMeetingRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: () async {
        final tokens = await resolvedTokenStore.read();
        return tokens?.accessToken;
      },
    );
  }

  return const MockMeetingRepository();
}

NotificationRepository createNotificationRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;

    return ApiNotificationRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: () async {
        final tokens = await resolvedTokenStore.read();
        return tokens?.accessToken;
      },
    );
  }

  return const MockNotificationRepository();
}

ChatRepository createChatRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;

    return ApiChatRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: () async {
        final tokens = await resolvedTokenStore.read();
        return tokens?.accessToken;
      },
    );
  }

  return const MockChatRepository();
}

ChatRealtimeClient createChatRealtimeClient({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;

    return StompChatRealtimeClient(
      baseUrl: apiBaseUrl,
      accessTokenProvider: () async {
        final tokens = await resolvedTokenStore.read();
        return tokens?.accessToken;
      },
    );
  }

  return const MockChatRealtimeClient();
}

ImageUploadRepository createImageUploadRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;

    return ApiImageUploadRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: () async {
        final tokens = await resolvedTokenStore.read();
        return tokens?.accessToken;
      },
    );
  }

  return const MockImageUploadRepository();
}

CategoryRepository createCategoryRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;

    return ApiCategoryRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: () async {
        final tokens = await resolvedTokenStore.read();
        return tokens?.accessToken;
      },
    );
  }

  return const MockCategoryRepository();
}

LocationRepository createLocationRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
}) {
  if (useApiRepository) {
    final resolvedTokenStore = tokenStore ?? _apiAuthTokenStore;

    return ApiLocationRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider: () async {
        final tokens = await resolvedTokenStore.read();
        return tokens?.accessToken;
      },
    );
  }

  return const MockLocationRepository();
}
