import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/image_upload_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../models/auth_session.dart';
import '../screens/auth/login_page.dart';
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
    required this.meetingRepository,
    required this.chatRepository,
    required this.categoryRepository,
    required this.locationRepository,
    required this.imageUploadRepository,
  });

  final AuthRepository? authRepository;
  final MeetingRepository meetingRepository;
  final ChatRepository chatRepository;
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

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? MockAuthRepository();
    _restoreSession();
  }

  @override
  void didUpdateWidget(covariant AuthEntryGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authRepository != widget.authRepository) {
      _authRepository = widget.authRepository ?? MockAuthRepository();
      _restoreSession();
    }
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
          chatRepository: widget.chatRepository,
          currentMemberId: _session!.user.id,
          categoryRepository: widget.categoryRepository,
          locationRepository: widget.locationRepository,
          imageUploadRepository: widget.imageUploadRepository,
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
  }

  void _showSignedIn(AuthSession session) {
    setState(() {
      _session = session;
      _state = _AuthEntryState.signedIn;
    });
  }

  void _showSignedOut() {
    setState(() {
      _session = null;
      _state = _AuthEntryState.signedOut;
    });
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
