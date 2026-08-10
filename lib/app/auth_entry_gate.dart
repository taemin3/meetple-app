import 'dart:async';

import 'package:flutter/material.dart';

import '../core/push/push_notification_message.dart';
import '../core/push/push_notification_service.dart';
import '../core/theme/app_colors.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/image_upload_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../data/realtime/chat_realtime_client.dart';
import '../models/auth_session.dart';
import '../screens/auth/login_page.dart';
import '../screens/chat/chat_room_page.dart';
import 'app_routes.dart';
import 'app_shell.dart';

enum _AuthEntryState {
  checking,
  signedOut,
  signedIn,
}

class AuthEntryGate extends StatefulWidget {
  const AuthEntryGate({
    super.key,
    this.authRepository,
    this.authSessionExpired,
    this.pushNotificationService = const NoopPushNotificationService(),
    required this.meetingRepository,
    required this.notificationRepository,
    required this.chatRepository,
    required this.chatRealtimeClient,
    required this.categoryRepository,
    required this.locationRepository,
    required this.imageUploadRepository,
  });

  final AuthRepository? authRepository;
  final Stream<void>? authSessionExpired;
  final PushNotificationService pushNotificationService;
  final MeetingRepository meetingRepository;
  final NotificationRepository notificationRepository;
  final ChatRepository chatRepository;
  final ChatRealtimeClient chatRealtimeClient;
  final CategoryRepository categoryRepository;
  final LocationRepository locationRepository;
  final ImageUploadRepository imageUploadRepository;

  @override
  State<AuthEntryGate> createState() => _AuthEntryGateState();
}

class _AuthEntryGateState extends State<AuthEntryGate> {
  late AuthRepository _authRepository;
  _AuthEntryState _state = _AuthEntryState.checking;
  AuthSession? _session;
  int _restoreGeneration = 0;
  StreamSubscription<PushNotificationMessage>? _openedNotificationSubscription;
  StreamSubscription<void>? _authSessionExpiredSubscription;
  PushNotificationMessage? _pendingOpenedNotification;
  bool _notificationNavigationScheduled = false;
  bool _openingNotification = false;
  int _meetingRefreshToken = 0;
  int _chatRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? MockAuthRepository();
    _subscribeToAuthSessionExpiration();
    _subscribeToOpenedNotifications();
    _restoreSession();
  }

  @override
  void didUpdateWidget(covariant AuthEntryGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authRepository != widget.authRepository) {
      _authRepository = widget.authRepository ?? MockAuthRepository();
      _restoreSession();
    }
    if (oldWidget.authSessionExpired != widget.authSessionExpired) {
      unawaited(_authSessionExpiredSubscription?.cancel());
      _subscribeToAuthSessionExpiration();
    }
    if (oldWidget.pushNotificationService != widget.pushNotificationService) {
      unawaited(_openedNotificationSubscription?.cancel());
      _subscribeToOpenedNotifications();
    }
  }

  @override
  void dispose() {
    unawaited(_openedNotificationSubscription?.cancel());
    unawaited(_authSessionExpiredSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AuthEntryState.checking:
        return const _AuthSplashView();
      case _AuthEntryState.signedOut:
        return LoginPage(
          authRepository: _authRepository,
          onAuthenticated: _showSignedIn,
        );
      case _AuthEntryState.signedIn:
        return AppShell(
          authRepository: _authRepository,
          meetingRepository: widget.meetingRepository,
          notificationRepository: widget.notificationRepository,
          chatRepository: widget.chatRepository,
          chatRealtimeClient: widget.chatRealtimeClient,
          currentMemberId: _session!.user.id,
          categoryRepository: widget.categoryRepository,
          locationRepository: widget.locationRepository,
          imageUploadRepository: widget.imageUploadRepository,
          meetingRefreshToken: _meetingRefreshToken,
          externalChatRefreshToken: _chatRefreshToken,
          pushNotificationService: widget.pushNotificationService,
          onSignedOut: _showSignedOut,
        );
    }
  }

  Future<void> _restoreSession() async {
    final restoreGeneration = ++_restoreGeneration;
    final authRepository = _authRepository;

    setState(() => _state = _AuthEntryState.checking);

    AuthSession? session;
    try {
      session = await authRepository.restoreSession();
    } on Exception {
      session = null;
    }

    if (!mounted ||
        restoreGeneration != _restoreGeneration ||
        !identical(authRepository, _authRepository)) {
      return;
    }

    setState(() {
      _session = session;
      _state = session == null
          ? _AuthEntryState.signedOut
          : _AuthEntryState.signedIn;
    });
    if (session == null) {
      _pendingOpenedNotification = null;
      unawaited(_deactivatePushNotifications());
    } else {
      unawaited(_activatePushNotifications());
      _schedulePendingNotificationNavigation();
    }
  }

  void _showSignedIn(AuthSession session) {
    setState(() {
      _session = session;
      _state = _AuthEntryState.signedIn;
    });
    unawaited(_activatePushNotifications());
    _schedulePendingNotificationNavigation();
  }

  void _showSignedOut() {
    _pendingOpenedNotification = null;
    unawaited(_deactivatePushNotifications());
    setState(() {
      _session = null;
      _state = _AuthEntryState.signedOut;
    });
  }

  void _subscribeToAuthSessionExpiration() {
    _authSessionExpiredSubscription =
        widget.authSessionExpired?.listen((_) => _handleSessionExpired());
  }

  void _handleSessionExpired() {
    if (!mounted || _state != _AuthEntryState.signedIn) {
      return;
    }
    _showSignedOut();
  }

  Future<void> _activatePushNotifications() async {
    try {
      await widget.pushNotificationService.activate();
    } on Exception catch (error) {
      debugPrint('Push notification activation failed: $error');
    }
  }

  Future<void> _deactivatePushNotifications() async {
    try {
      await widget.pushNotificationService.deactivate();
    } on Exception catch (error) {
      debugPrint('Push notification deactivation failed: $error');
    }
  }

  void _subscribeToOpenedNotifications() {
    _openedNotificationSubscription = widget
        .pushNotificationService.openedNotifications
        .listen(_handleOpenedNotification);
    final pending =
        widget.pushNotificationService.takePendingOpenedNotification();
    if (pending != null) {
      _handleOpenedNotification(pending);
    }
  }

  void _handleOpenedNotification(PushNotificationMessage notification) {
    final hasTarget = switch (notification.route) {
      PushNotificationRoute.meetingDetail => notification.meetingId != null,
      PushNotificationRoute.chatRoom => notification.roomId != null,
      PushNotificationRoute.unknown => false,
    };
    if (!hasTarget || _state == _AuthEntryState.signedOut) {
      return;
    }

    _pendingOpenedNotification = notification;
    _schedulePendingNotificationNavigation();
  }

  void _schedulePendingNotificationNavigation() {
    if (!mounted ||
        _state != _AuthEntryState.signedIn ||
        _pendingOpenedNotification == null ||
        _openingNotification ||
        _notificationNavigationScheduled) {
      return;
    }

    _notificationNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationNavigationScheduled = false;
      if (mounted) {
        unawaited(_openPendingNotification());
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _openPendingNotification() async {
    final notification = _pendingOpenedNotification;
    if (notification == null ||
        _state != _AuthEntryState.signedIn ||
        _openingNotification) {
      return;
    }

    _pendingOpenedNotification = null;
    _openingNotification = true;
    try {
      switch (notification.route) {
        case PushNotificationRoute.meetingDetail:
          await _openMeetingNotification(notification);
          break;
        case PushNotificationRoute.chatRoom:
          await _openChatNotification(notification);
          break;
        case PushNotificationRoute.unknown:
          return;
      }
    } on Exception catch (error) {
      debugPrint('Push notification navigation failed: $error');
      if (mounted && _state == _AuthEntryState.signedIn) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(_navigationErrorMessage(notification.route))),
        );
      }
    } finally {
      _openingNotification = false;
      _schedulePendingNotificationNavigation();
    }
  }

  Future<void> _openMeetingNotification(
    PushNotificationMessage notification,
  ) async {
    final meetingId = notification.meetingId;
    if (meetingId == null) return;

    final notificationId = notification.notificationId;
    if (notificationId != null) {
      unawaited(_markNotificationRead(notificationId));
    }
    final meeting = await widget.meetingRepository.findById(meetingId);
    if (!mounted || _state != _AuthEntryState.signedIn) {
      return;
    }
    final detailResult = AppRoutes.openMeetingDetail<Object>(
      context,
      meeting,
      meetingRepository: widget.meetingRepository,
      categoryRepository: widget.categoryRepository,
      locationRepository: widget.locationRepository,
      imageUploadRepository: widget.imageUploadRepository,
    );
    _releaseNotificationNavigation();
    unawaited(_handleMeetingDetailResult(detailResult));
  }

  Future<void> _openChatNotification(
    PushNotificationMessage notification,
  ) async {
    final roomId = notification.roomId;
    if (roomId == null) return;
    if (widget.pushNotificationService.isChatRoomActive(roomId)) {
      return;
    }

    final room = await widget.chatRepository.getRoom(roomId);
    if (!mounted || _state != _AuthEntryState.signedIn) {
      return;
    }
    final roomResult = Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomPage(
          room: room,
          chatRepository: widget.chatRepository,
          chatRealtimeClient: widget.chatRealtimeClient,
          currentMemberId: _session!.user.id,
          pushNotificationService: widget.pushNotificationService,
        ),
      ),
    );
    _releaseNotificationNavigation();
    unawaited(_handleChatRoomClosed(roomResult));
  }

  void _releaseNotificationNavigation() {
    _openingNotification = false;
    _schedulePendingNotificationNavigation();
  }

  String _navigationErrorMessage(PushNotificationRoute route) {
    return route == PushNotificationRoute.chatRoom
        ? '채팅방을 불러오지 못했습니다.'
        : '모임 정보를 불러오지 못했습니다.';
  }

  Future<void> _handleMeetingDetailResult(Future<Object?> resultFuture) async {
    final result = await resultFuture;
    if (result == null || !mounted || _state != _AuthEntryState.signedIn) {
      return;
    }

    setState(() => _meetingRefreshToken++);
  }

  Future<void> _handleChatRoomClosed(Future<void> roomFuture) async {
    await roomFuture;
    if (!mounted || _state != _AuthEntryState.signedIn) {
      return;
    }

    setState(() => _chatRefreshToken++);
  }

  Future<void> _markNotificationRead(int notificationId) async {
    try {
      await widget.notificationRepository.markNotificationRead(notificationId);
    } on Exception catch (error) {
      debugPrint('Push notification read update failed: $error');
    }
  }
}

class _AuthSplashView extends StatelessWidget {
  const _AuthSplashView();

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final brandHeight = shortestSide.clamp(180.0, 240.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: '\uBC0B\uD50C',
            image: true,
            child: Image.asset(
              'assets/splash/splash-brand.png',
              height: brandHeight,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
