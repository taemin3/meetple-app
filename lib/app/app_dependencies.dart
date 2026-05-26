import '../core/config/app_config.dart';
import '../data/repositories/api_meeting_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_meeting_repository.dart';

MeetingRepository createMeetingRepository({
  bool useApiRepository = AppConfig.useApiRepository,
  String apiBaseUrl = AppConfig.apiBaseUrl,
  String accessToken = AppConfig.accessToken,
}) {
  if (useApiRepository) {
    return ApiMeetingRepository.withBaseUrl(
      baseUrl: apiBaseUrl,
      accessTokenProvider:
          accessToken.trim().isEmpty ? null : () => accessToken,
    );
  }

  return const MockMeetingRepository();
}
