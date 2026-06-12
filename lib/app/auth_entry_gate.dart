import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../models/auth_session.dart';
import '../screens/auth/login_page.dart';
import '../widgets/app_state_view.dart';
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
  });

  final AuthRepository? authRepository;
  final MeetingRepository meetingRepository;

  @override
  State<AuthEntryGate> createState() => _AuthEntryGateState();
}

class _AuthEntryGateState extends State<AuthEntryGate> {
  late AuthRepository _authRepository;
  _AuthEntryState _state = _AuthEntryState.checking;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? MockAuthRepository();
    _restoreSession();
  }

  @override
  void didUpdateWidget(covariant AuthEntryGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authRepository != widget.authRepository &&
        widget.authRepository != null) {
      _authRepository = widget.authRepository!;
      _restoreSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AuthEntryState.checking:
        return const Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Center(
              child: AppLoadingView(
                message:
                    '\uB85C\uADF8\uC778 \uC0C1\uD0DC\uB97C \uD655\uC778\uD558\uACE0 \uC788\uC2B5\uB2C8\uB2E4.',
              ),
            ),
          ),
        );
      case _AuthEntryState.signedOut:
        return LoginPage(
          authRepository: _authRepository,
          onAuthenticated: _showSignedIn,
        );
      case _AuthEntryState.signedIn:
        return AppShell(
          authRepository: _authRepository,
          meetingRepository: widget.meetingRepository,
          onSignedOut: _showSignedOut,
        );
    }
  }

  Future<void> _restoreSession() async {
    setState(() => _state = _AuthEntryState.checking);

    AuthSession? session;
    try {
      session = await _authRepository.restoreSession();
    } on Exception {
      session = null;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _state = session == null
          ? _AuthEntryState.signedOut
          : _AuthEntryState.signedIn;
    });
  }

  void _showSignedIn(AuthSession session) {
    setState(() => _state = _AuthEntryState.signedIn);
  }

  void _showSignedOut() {
    setState(() => _state = _AuthEntryState.signedOut);
  }
}
