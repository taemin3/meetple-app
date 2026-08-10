import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/app_dependencies.dart';
import 'package:meetple/core/push/push_notification_service.dart';
import 'package:meetple/data/repositories/api_auth_repository.dart';
import 'package:meetple/data/repositories/api_category_repository.dart';
import 'package:meetple/data/repositories/api_chat_repository.dart';
import 'package:meetple/data/repositories/api_image_upload_repository.dart';
import 'package:meetple/data/repositories/api_location_repository.dart';
import 'package:meetple/data/repositories/api_meeting_repository.dart';
import 'package:meetple/data/repositories/api_notification_repository.dart';
import 'package:meetple/data/repositories/auth_token_store.dart';
import 'package:meetple/data/repositories/mock_auth_repository.dart';
import 'package:meetple/data/repositories/mock_category_repository.dart';
import 'package:meetple/data/repositories/mock_chat_repository.dart';
import 'package:meetple/data/repositories/mock_image_upload_repository.dart';
import 'package:meetple/data/repositories/mock_location_repository.dart';
import 'package:meetple/data/repositories/mock_meeting_repository.dart';
import 'package:meetple/data/repositories/mock_notification_repository.dart';
import 'package:meetple/data/realtime/mock_chat_realtime_client.dart';
import 'package:meetple/data/realtime/stomp_chat_realtime_client.dart';

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

  test('creates no-op push service when API mode is disabled', () {
    final service = createPushNotificationService(
      useApiRepository: false,
    );

    expect(service, isA<NoopPushNotificationService>());
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

  test('creates mock notification repository by default', () {
    final repository = createNotificationRepository();

    expect(repository, isA<MockNotificationRepository>());
  });

  test('creates API notification repository when API mode is enabled', () {
    final repository = createNotificationRepository(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
      tokenStore: MemoryAuthTokenStore(),
    );

    expect(repository, isA<ApiNotificationRepository>());
  });

  test('creates mock chat repository by default', () {
    final repository = createChatRepository();

    expect(repository, isA<MockChatRepository>());
  });

  test('creates API chat repository when API mode is enabled', () {
    final repository = createChatRepository(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
      tokenStore: MemoryAuthTokenStore(),
    );

    expect(repository, isA<ApiChatRepository>());
  });

  test('creates mock realtime chat client by default', () {
    final client = createChatRealtimeClient();

    expect(client, isA<MockChatRealtimeClient>());
  });

  test('creates STOMP chat client when API mode is enabled', () {
    final client = createChatRealtimeClient(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
      tokenStore: MemoryAuthTokenStore(),
    );

    expect(client, isA<StompChatRealtimeClient>());
  });

  test('creates mock image upload repository by default', () {
    final repository = createImageUploadRepository();

    expect(repository, isA<MockImageUploadRepository>());
  });

  test('creates API image upload repository when API mode is enabled', () {
    final repository = createImageUploadRepository(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
      tokenStore: MemoryAuthTokenStore(),
    );

    expect(repository, isA<ApiImageUploadRepository>());
  });

  test('creates mock category repository by default', () {
    final repository = createCategoryRepository();

    expect(repository, isA<MockCategoryRepository>());
  });

  test('creates API category repository when API mode is enabled', () {
    final repository = createCategoryRepository(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
      tokenStore: MemoryAuthTokenStore(),
    );

    expect(repository, isA<ApiCategoryRepository>());
  });

  test('creates mock location repository by default', () {
    final repository = createLocationRepository();

    expect(repository, isA<MockLocationRepository>());
  });

  test('creates API location repository when API mode is enabled', () {
    final repository = createLocationRepository(
      useApiRepository: true,
      apiBaseUrl: 'http://localhost:8080',
      tokenStore: MemoryAuthTokenStore(),
    );

    expect(repository, isA<ApiLocationRepository>());
  });
}
