import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/push_device_token_repository.dart';
import 'push_installation_id_store.dart';
import 'push_notification_message.dart';
import 'push_token_registration_coordinator.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

abstract interface class PushNotificationService {
  Stream<PushNotificationMessage> get openedNotifications;

  Future<void> initialize();

  Future<void> activate();

  Future<void> deactivate();

  Future<String?> deviceId();

  void enterChatRoom(int roomId);

  void leaveChatRoom(int roomId);

  PushNotificationMessage? takePendingOpenedNotification();
}

class FirebasePushNotificationService implements PushNotificationService {
  FirebasePushNotificationService({
    required PushDeviceTokenRepository tokenRepository,
    required PushInstallationIdStore installationIdStore,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _installationIdStore = installationIdStore,
        _tokenRegistration = PushTokenRegistrationCoordinator(
          tokenRepository: tokenRepository,
          installationIdStore: installationIdStore,
          platform:
              defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
        ),
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'meetple_push',
    '밋플 알림',
    description: '모임과 채팅 소식을 전달합니다.',
    importance: Importance.high,
  );

  final PushInstallationIdStore _installationIdStore;
  final PushTokenRegistrationCoordinator _tokenRegistration;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final StreamController<PushNotificationMessage> _openedController =
      StreamController<PushNotificationMessage>.broadcast(sync: true);

  FirebaseMessaging? _messaging;
  PushNotificationMessage? _pendingOpenedNotification;
  bool _initialized = false;
  bool _localTokenDeleted = false;
  int? _activeChatRoomId;

  @override
  Stream<PushNotificationMessage> get openedNotifications =>
      _openedController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _messaging = FirebaseMessaging.instance;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_meetple_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final notification =
            PushNotificationMessage.fromPayload(response.payload);
        if (notification != null) {
          _emitOpened(notification);
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging!.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _emitOpened(_fromRemoteMessage(message)),
    );
    _messaging!.onTokenRefresh.listen((token) {
      unawaited(_tokenRegistration.register(token));
    });

    final initialRemoteMessage = await _messaging!.getInitialMessage();
    if (initialRemoteMessage != null) {
      _pendingOpenedNotification = _fromRemoteMessage(initialRemoteMessage);
    }
    final localLaunch =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (localLaunch?.didNotificationLaunchApp == true) {
      final localNotification = PushNotificationMessage.fromPayload(
        localLaunch?.notificationResponse?.payload,
      );
      if (localNotification != null) {
        _pendingOpenedNotification = localNotification;
      }
    }

    _initialized = true;
  }

  @override
  Future<void> activate() async {
    _tokenRegistration.activate();
    _localTokenDeleted = false;
    if (!_initialized) {
      await initialize();
    }

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = await _messaging!.getToken();
    if (token != null && token.isNotEmpty) {
      await _tokenRegistration.register(token);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final pushMessage = _fromRemoteMessage(message);
    if (!shouldShowForeground(pushMessage)) {
      return;
    }

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final groupKey = message.data['route'] == 'CHAT_ROOM'
        ? 'chat-room-${message.data['roomId']}'
        : null;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        groupKey: groupKey,
      ),
      iOS: DarwinNotificationDetails(threadIdentifier: groupKey),
    );
    await _localNotifications.show(
      message.messageId?.hashCode ?? message.data.hashCode,
      title,
      body,
      details,
      payload: pushMessage.toPayload(),
    );
  }

  @visibleForTesting
  bool shouldShowForeground(PushNotificationMessage message) {
    return message.route != PushNotificationRoute.chatRoom ||
        message.roomId != _activeChatRoomId;
  }

  void _emitOpened(PushNotificationMessage notification) {
    if (_openedController.hasListener) {
      _openedController.add(notification);
    } else {
      _pendingOpenedNotification = notification;
    }
  }

  PushNotificationMessage _fromRemoteMessage(RemoteMessage message) {
    return PushNotificationMessage(
      message.data.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  @override
  Future<void> deactivate() async {
    await _tokenRegistration.deactivate();
    if (!_initialized || _localTokenDeleted) {
      return;
    }

    for (var attempt = 0; attempt < 3; attempt += 1) {
      try {
        await _messaging!.deleteToken();
        _localTokenDeleted = true;
        return;
      } on Exception catch (error) {
        if (attempt == 2) {
          debugPrint('FCM token deletion failed: $error');
          return;
        }
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
      }
    }
  }

  @override
  Future<String?> deviceId() => _installationIdStore.readOrCreate();

  @override
  void enterChatRoom(int roomId) {
    _activeChatRoomId = roomId;
  }

  @override
  void leaveChatRoom(int roomId) {
    if (_activeChatRoomId == roomId) {
      _activeChatRoomId = null;
    }
  }

  @override
  PushNotificationMessage? takePendingOpenedNotification() {
    final pending = _pendingOpenedNotification;
    _pendingOpenedNotification = null;
    return pending;
  }
}

class NoopPushNotificationService implements PushNotificationService {
  const NoopPushNotificationService();

  @override
  Stream<PushNotificationMessage> get openedNotifications =>
      const Stream<PushNotificationMessage>.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<String?> deviceId() async => null;

  @override
  void enterChatRoom(int roomId) {}

  @override
  void leaveChatRoom(int roomId) {}

  @override
  PushNotificationMessage? takePendingOpenedNotification() => null;
}

bool get supportsFirebasePush {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
