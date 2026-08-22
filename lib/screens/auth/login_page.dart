import 'package:flutter/material.dart';

import '../../app/app_route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/image_upload_repository.dart';
import '../../data/repositories/mock_image_upload_repository.dart';
import '../../models/auth_session.dart';
import '../../widgets/primary_button.dart';
import 'auth_form_widgets.dart';
import 'password_reset_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authRepository,
    this.imageUploadRepository = const MockImageUploadRepository(),
    this.onAuthenticated,
  });

  final AuthRepository authRepository;
  final ImageUploadRepository imageUploadRepository;
  final ValueChanged<AuthSession>? onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFEFCFF),
              AppColors.canvas,
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 800;
              final isExtraCompact = constraints.maxHeight < 620;
              const horizontalPadding = 16.0;
              final topSpacing = isExtraCompact
                  ? 10.0
                  : (constraints.maxHeight * 0.06).clamp(28.0, 58.0);
              final brandHeight =
                  (constraints.maxHeight * 0.24).clamp(110.0, 205.0);
              final brandSpacing =
                  (constraints.maxHeight * 0.035).clamp(14.0, 30.0);
              final fieldHeight =
                  isExtraCompact ? 44.0 : (isCompact ? 50.0 : 56.0);
              final fieldGap = isCompact ? 10.0 : 14.0;
              final forgotGap = isCompact ? 4.0 : 8.0;
              final errorHeight = isCompact ? 24.0 : 28.0;
              final buttonSpacing =
                  (constraints.maxHeight * 0.035).clamp(14.0, 32.0);
              final buttonHeight =
                  isExtraCompact ? 46.0 : (isCompact ? 50.0 : 54.0);
              final signUpSpacing =
                  (constraints.maxHeight * 0.055).clamp(22.0, 52.0);
              final bottomPadding = isCompact ? 14.0 : 24.0;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topSpacing),
                        _LoginBrand(
                          height: brandHeight,
                          isCompact: isCompact,
                        ),
                        SizedBox(height: brandSpacing),
                        _LoginTextField(
                          controller: _emailController,
                          height: fieldHeight,
                          icon: Icons.mail_outline_rounded,
                          hintText: '이메일을 입력해주세요',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: fieldGap),
                        _LoginTextField(
                          controller: _passwordController,
                          height: fieldHeight,
                          icon: Icons.lock_outline_rounded,
                          hintText: '비밀번호를 입력해주세요',
                          obscureText: !_isPasswordVisible,
                          keyboardType: TextInputType.visiblePassword,
                          suffix: IconButton(
                            tooltip:
                                _isPasswordVisible ? '비밀번호 숨기기' : '비밀번호 보기',
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        SizedBox(height: forgotGap),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const Key('login_password_reset_button'),
                            onPressed: _openPasswordReset,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              textStyle: TextStyle(
                                fontSize: isCompact ? 13 : 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: const Text('비밀번호 찾기'),
                          ),
                        ),
                        SizedBox(
                          height: errorHeight,
                          child: _errorMessage == null
                              ? const SizedBox.shrink()
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: AuthErrorText(message: _errorMessage!),
                                ),
                        ),
                        SizedBox(height: buttonSpacing),
                        PrimaryButton(
                          height: buttonHeight,
                          label: '로그인',
                          onPressed: _submit,
                          loading: _isSubmitting,
                          borderRadius: isCompact ? 16 : 18,
                          fontSize: isCompact ? 15 : 17,
                        ),
                        SizedBox(height: signUpSpacing),
                        _SignUpPrompt(
                          isCompact: isCompact,
                          onPressed: _openSignUp,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final session = await widget.authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _complete(session);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openSignUp() async {
    final session = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        settings: const RouteSettings(name: AppRouteNames.signUp),
        builder: (_) => SignUpPage(
          authRepository: widget.authRepository,
          imageUploadRepository: widget.imageUploadRepository,
        ),
      ),
    );

    if (session != null) {
      _complete(session);
    }
  }

  Future<void> _openPasswordReset() async {
    FocusScope.of(context).unfocus();
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        settings: const RouteSettings(name: AppRouteNames.passwordReset),
        builder: (_) => PasswordResetPage(
          authRepository: widget.authRepository,
          initialEmail: _emailController.text,
        ),
      ),
    );
    if (!mounted || changed != true) {
      return;
    }
    _passwordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호가 변경됐어요. 새 비밀번호로 로그인해주세요.')),
    );
  }

  void _complete(AuthSession session) {
    if (!mounted) {
      return;
    }

    final onAuthenticated = widget.onAuthenticated;
    if (onAuthenticated != null) {
      onAuthenticated(session);
      return;
    }

    Navigator.of(context).pop(session);
  }
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand({
    required this.height,
    required this.isCompact,
  });

  final double height;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: '밋플',
          image: true,
          child: Image.asset(
            'assets/splash/splash-brand.png',
            height: height,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: isCompact ? 4 : 8),
        Text(
          '우리, 가까운 모임으로 연결되는 순간',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: isCompact ? 13 : 15,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.height,
    required this.icon,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final double height;
  final IconData icon;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final isCompact = height < 64;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: isCompact ? 16 : 18),
              Icon(icon, color: AppColors.muted, size: isCompact ? 20 : 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  enableSuggestions: !obscureText,
                  autocorrect: !obscureText,
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: AppColors.primary,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: isCompact ? 14 : 15,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: AppColors.subtle,
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                SizedBox.square(
                  dimension: isCompact ? 34 : 38,
                  child: IconTheme(
                    data: const IconThemeData(
                      color: AppColors.muted,
                      size: 22,
                    ),
                    child: suffix!,
                  ),
                ),
                SizedBox(width: isCompact ? 6 : 8),
              ] else
                SizedBox(width: isCompact ? 16 : 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt({
    required this.isCompact,
    required this.onPressed,
  });

  final bool isCompact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fontSize = isCompact ? 13.0 : 14.0;

    return Row(
      children: [
        const Expanded(child: Divider()),
        SizedBox(width: isCompact ? 12 : 18),
        Text(
          '계정이 없으신가요?',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: const Text('회원가입'),
        ),
        SizedBox(width: isCompact ? 6 : 10),
        const Expanded(child: Divider()),
      ],
    );
  }
}
