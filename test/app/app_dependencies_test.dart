import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/app_dependencies.dart';
import 'package:meetple/data/repositories/api_meeting_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';

void main() {
  test('creates mock meeting repository by default', () {
    final repository = createMeetingRepository();

    expect(repository, isA<MockMeetingRepository>());
  });

  test('creates API meeting repository when API mode is enabled', () {
    final repository = createMeetingRepository(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
    );

    expect(repository, isA<ApiMeetingRepository>());
  });

  test('creates API meeting repository with access token', () {
    final repository = createMeetingRepository(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
      accessToken: 'access-token',
    );

    expect(repository, isA<ApiMeetingRepository>());
  });
}
