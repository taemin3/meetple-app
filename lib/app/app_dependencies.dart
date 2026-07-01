import '../core/config/app_config.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/api_category_repository.dart';
import '../data/repositories/api_location_repository.dart';
import '../data/repositories/api_meeting_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/auth_token_store.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/repositories/mock_category_repository.dart';
import '../data/repositories/mock_location_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';

const AuthTokenStore _apiAuthTokenStore = FlutterSecureAuthTokenStore();

AuthRepository createAuthRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  AuthTokenStore? tokenStore,
}) {
  if (useApiRepository) {
    return ApiAuthRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      tokenStore: tokenStore ?? _apiAuthTokenStore,
    );
  }

  return MockAuthRepository();
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
