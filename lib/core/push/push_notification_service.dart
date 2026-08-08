import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/push_device_token_repository.dart';
import 'push_installation_id_store.dart';
import 'push_notification_message.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

abstract interface class PushNotificationService {
  Stream<PushNotificationMessage> get openedNotifications;

  Future<void> initialize();

  Future<void> activate();

  void deactivate();

  Future<String?> deviceId();

  PushNotificationMessage? takePendingOpenedNotification();
}

class FirebasePushNotificationService implements PushNotificationService {
  FirebasePushNotificationService({
    required PushDeviceTokenRepository tokenRepository,
    required PushInstallationIdStore installationIdStore,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _tokenRepository = tokenRepository,
        _installationIdStore = installationIdStore,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'meetple_push',
    '밋플 알림',
    description: '모임과 채팅 소식을 전달합니다.',
    importance: Importance.high,
  );

  final PushDeviceTokenRepository _tokenRepository;
  final PushInstallationIdStore _installationIdStore;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final StreamController<PushNotificationMessage> _openedController =
      StreamController<PushNotificationMessage>.broadcast(sync: true);

  FirebaseMessaging? _messaging;
  PushNotificationMessage? _pendingOpenedNotification;
  bool _initialized = false;
  bool _active = false;

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
      android: AndroidInitializationSettings('ic_launcher'),
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
      if (_active) {
        unawaited(_registerToken(token));
      }
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
    _active = true;
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
      await _registerToken(token);
    }
  }

  Future<void> _registerToken(String token) async {
    if (!_active) return;
    try {
      await _tokenRepository.register(
        deviceId: await _installationIdStore.readOrCreate(),
        token: token,
        platform:
            defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
      );
    } on Exception catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
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
      payload: jsonEncode(message.data),
    );
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
  void deactivate() {
    _active = false;
  }

  @override
  Future<String?> deviceId() => _installationIdStore.readOrCreate();

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
  void deactivate() {}

  @override
  Future<String?> deviceId() async => null;

  @override
  PushNotificationMessage? takePendingOpenedNotification() => null;
}

bool get supportsFirebasePush {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
