import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/app_dependencies.dart';
import 'package:meetple/data/repositories/api_auth_repository.dart';
import 'package:meetple/data/repositories/api_meeting_repository.dart';
import 'package:meetple/data/repositories/auth_token_store.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';

void main() {
  test('creates mock auth repository by default', () {
    final repository = createAuthRepository();

    expect(repository, isA<MockAuthRepository>());
  });

  test('creates API auth repository when API mode is enabled', () {
    final repository = createAuthRepository(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
      tokenStore: MemoryAuthTokenStore(),
    );

    expect(repository, isA<ApiAuthRepository>());
  });

  test('creates mock meeting repository by default', () {
    final repository = createMeetingRepository();

    expect(repository, isA<MockMeetingRepository>());
  });

  test('creates API meeting repository when API mode is enabled', () {
    final repository = createMeetingRepository(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
      tokenStore: MemoryAuthTokenStore(),
    );

    expect(repository, isA<ApiMeetingRepository>());
  });
}
