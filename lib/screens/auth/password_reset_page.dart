import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/auth_form_field.dart';
import '../../widgets/primary_button.dart';
import 'auth_form_widgets.dart';

enum _PasswordResetStep { email, code, password }

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({
    super.key,
    required this.authRepository,
    this.initialEmail = '',
    this.now,
  });

  final AuthRepository authRepository;
  final String initialEmail;
  final DateTime Function()? now;

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage>
    with WidgetsBindingObserver {
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  _PasswordResetStep _step = _PasswordResetStep.email;
  bool _isSubmitting = false;
  bool _isResending = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  int _resendSeconds = 0;
  String? _requestedEmail;
  String? _passwordResetToken;
  DateTime? _passwordResetTokenExpiresAt;
  DateTime? _resendExpiresAt;
  Timer? _resendTimer;
  String? _message;
  String? _errorMessage;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _emailController = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshResendCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(title: _title, subtitle: _subtitle),
                  const SizedBox(height: 34),
                  _buildStep(),
                  const SizedBox(height: 18),
                  if (_message != null) ...[
                    Text(
                      _message!,
                      key: const Key('password_reset_message'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_errorMessage != null) ...[
                    AuthErrorText(
                      key: const Key('password_reset_error'),
                      message: _errorMessage!,
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  PrimaryButton(
                    key: const Key('password_reset_primary_button'),
                    label: _primaryLabel,
                    loading: _isSubmitting,
                    onPressed: _isResending ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _PasswordResetStep.email:
        return AuthFormField(
          key: const Key('password_reset_email'),
          controller: _emailController,
          label: '이메일',
          icon: Icons.mail_outline_rounded,
          hintText: '가입할 때 사용한 이메일을 입력해주세요',
          keyboardType: TextInputType.emailAddress,
        );
      case _PasswordResetStep.code:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormField(
              key: const Key('password_reset_code'),
              controller: _codeController,
              label: '인증번호',
              icon: Icons.verified_outlined,
              hintText: '6자리 인증번호를 입력해주세요',
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              helperText: '인증번호는 발급 후 5분 동안 유효합니다.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('password_reset_resend_button'),
                onPressed: _canResend ? _resendCode : null,
                child: Text(_resendLabel),
              ),
            ),
          ],
        );
      case _PasswordResetStep.password:
        return Column(
          children: [
            AuthFormField(
              fieldKey: const Key('password_reset_new_password'),
              controller: _passwordController,
              label: '새 비밀번호',
              icon: Icons.lock_outline_rounded,
              hintText: '8자 이상 입력해주세요',
              keyboardType: TextInputType.visiblePassword,
              obscureText: !_isPasswordVisible,
              enableSuggestions: false,
              autocorrect: false,
              helperText: '8자 이상 64자 이하로 입력해주세요',
              suffix: IconButton(
                tooltip: _isPasswordVisible ? '비밀번호 숨기기' : '비밀번호 보기',
                onPressed: _togglePasswordVisibility,
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const SizedBox(height: 18),
            AuthFormField(
              fieldKey: const Key('password_reset_password_confirm'),
              controller: _passwordConfirmController,
              label: '새 비밀번호 확인',
              icon: Icons.lock_outline_rounded,
              hintText: '비밀번호를 다시 입력해주세요',
              keyboardType: TextInputType.visiblePassword,
              obscureText: !_isPasswordConfirmVisible,
              enableSuggestions: false,
              autocorrect: false,
              suffix: IconButton(
                tooltip: _isPasswordConfirmVisible ? '비밀번호 숨기기' : '비밀번호 보기',
                onPressed: _togglePasswordConfirmVisibility,
                icon: Icon(
                  _isPasswordConfirmVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ],
        );
    }
  }

  String get _title {
    switch (_step) {
      case _PasswordResetStep.email:
        return '비밀번호 재설정';
      case _PasswordResetStep.code:
        return '인증번호 확인';
      case _PasswordResetStep.password:
        return '새 비밀번호 설정';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _PasswordResetStep.email:
        return '가입한 이메일로 본인 확인을 진행해요.';
      case _PasswordResetStep.code:
        return '${_requestedEmail ?? ''}으로 보낸 인증번호를 입력해주세요.';
      case _PasswordResetStep.password:
        return '다른 서비스에서 사용하지 않는 비밀번호를 권장해요.';
    }
  }

  String get _primaryLabel {
    switch (_step) {
      case _PasswordResetStep.email:
        return '인증번호 받기';
      case _PasswordResetStep.code:
        return '인증번호 확인';
      case _PasswordResetStep.password:
        return '비밀번호 변경';
    }
  }

  bool get _canResend => !_isSubmitting && !_isResending && _resendSeconds == 0;

  String get _resendLabel {
    if (_isResending) {
      return '전송 중...';
    }
    if (_resendSeconds > 0) {
      return '인증번호 재전송 ($_resendSeconds초)';
    }
    return '인증번호 재전송';
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isResending) {
      return;
    }
    switch (_step) {
      case _PasswordResetStep.email:
        return _sendCode();
      case _PasswordResetStep.code:
        return _confirmCode();
      case _PasswordResetStep.password:
        return _resetPassword();
    }
  }

  Future<void> _sendCode({bool isResend = false}) async {
    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() {
        _errorMessage = '올바른 이메일을 입력해 주세요.';
        _message = null;
      });
      return;
    }

    setState(() {
      if (isResend) {
        _isResending = true;
      } else {
        _isSubmitting = true;
      }
      _errorMessage = null;
      _message = null;
    });

    try {
      await widget.authRepository.sendPasswordResetVerificationCode(
        email: email,
      );
      if (!mounted) return;
      _codeController.clear();
      final resendExpiresAt = _now.add(const Duration(seconds: 60));
      setState(() {
        _requestedEmail = email;
        _step = _PasswordResetStep.code;
        _resendExpiresAt = resendExpiresAt;
        _resendSeconds = 60;
        _message = '가입된 이메일이라면 인증번호를 전송했어요.';
      });
      _startResendTimer();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isResending = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) {
      return;
    }
    await _sendCode(isResend: true);
  }

  Future<void> _confirmCode() async {
    final email = _requestedEmail;
    final code = _codeController.text.trim();
    if (email == null) {
      setState(() => _step = _PasswordResetStep.email);
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _errorMessage = '인증번호는 6자리 숫자로 입력해 주세요.';
        _message = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _message = null;
    });
    try {
      final verification = await widget.authRepository
          .confirmPasswordResetVerificationCode(email: email, code: code);
      if (!mounted) return;
      _resendTimer?.cancel();
      setState(() {
        _passwordResetToken = verification.token;
        _passwordResetTokenExpiresAt = _now.add(verification.expiresIn);
        _step = _PasswordResetStep.password;
        _resendExpiresAt = null;
        _resendSeconds = 0;
        _message = '이메일 인증이 완료됐어요.';
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _requestedEmail;
    final token = _passwordResetToken;
    final password = _passwordController.text;
    if (email == null ||
        token == null ||
        (_passwordResetTokenExpiresAt?.isBefore(_now) ?? true)) {
      setState(() {
        _errorMessage = '이메일 인증이 만료됐어요. 처음부터 다시 진행해주세요.';
        _message = null;
      });
      return;
    }
    if (password.length < 8 || password.length > 64) {
      setState(() {
        _errorMessage = '비밀번호는 8자 이상 64자 이하여야 합니다.';
        _message = null;
      });
      return;
    }
    if (password != _passwordConfirmController.text) {
      setState(() {
        _errorMessage = '비밀번호가 일치하지 않습니다.';
        _message = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _message = null;
    });
    try {
      await widget.authRepository.resetPassword(
        email: email,
        passwordResetToken: token,
        newPassword: password,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  void _togglePasswordConfirmVisibility() {
    setState(
      () => _isPasswordConfirmVisible = !_isPasswordConfirmVisible,
    );
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshResendCountdown(),
    );
  }

  void _refreshResendCountdown() {
    if (!mounted) {
      _resendTimer?.cancel();
      return;
    }
    final remainingMilliseconds =
        _resendExpiresAt?.difference(_now).inMilliseconds ?? 0;
    final remainingSeconds = remainingMilliseconds <= 0
        ? 0
        : (remainingMilliseconds / Duration.millisecondsPerSecond).ceil();
    if (remainingSeconds == 0) {
      _resendTimer?.cancel();
      _resendExpiresAt = null;
    }
    if (_resendSeconds != remainingSeconds) {
      setState(() => _resendSeconds = remainingSeconds);
    }
  }

  bool _looksLikeEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }
}
