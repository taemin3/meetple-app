import 'package:flutter/material.dart';

import '../../app/app_route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/auth_session.dart';
import 'auth_form_widgets.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authRepository,
  });

  final AuthRepository authRepository;

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
              final horizontalPadding =
                  constraints.maxWidth < 380 ? 24.0 : 36.0;
              final topSpacing = isExtraCompact
                  ? 12.0
                  : (constraints.maxHeight * 0.07).clamp(34.0, 72.0);
              final brandHeight =
                  (constraints.maxHeight * 0.28).clamp(124.0, 238.0);
              final brandSpacing =
                  (constraints.maxHeight * 0.042).clamp(18.0, 38.0);
              final fieldHeight =
                  isExtraCompact ? 54.0 : (isCompact ? 62.0 : 70.0);
              final fieldGap = isCompact ? 12.0 : 18.0;
              final forgotGap = isCompact ? 6.0 : 12.0;
              final errorHeight = isCompact ? 26.0 : 30.0;
              final buttonSpacing =
                  (constraints.maxHeight * 0.043).clamp(18.0, 42.0);
              final buttonHeight =
                  isExtraCompact ? 52.0 : (isCompact ? 58.0 : 64.0);
              final signUpSpacing =
                  (constraints.maxHeight * 0.07).clamp(28.0, 68.0);
              final bottomPadding = isCompact ? 18.0 : 30.0;

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
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              textStyle: TextStyle(
                                fontSize: isCompact ? 14 : 15,
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
                        _LoginButton(
                          height: buttonHeight,
                          label: _isSubmitting ? '로그인 중...' : '로그인',
                          onPressed: _isSubmitting ? null : _submit,
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
        builder: (_) => SignUpPage(authRepository: widget.authRepository),
      ),
    );

    if (session != null) {
      _complete(session);
    }
  }

  void _complete(AuthSession session) {
    if (!mounted) {
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
        SizedBox(height: isCompact ? 6 : 10),
        Text(
          '우리, 가까운 모임으로 연결되는 순간',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: isCompact ? 15 : 17,
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
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
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
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enableSuggestions: !obscureText,
          autocorrect: !obscureText,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: isCompact ? 15 : 17,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.subtle,
              fontSize: isCompact ? 15 : 17,
              fontWeight: FontWeight.w800,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: isCompact ? 20 : 24, right: 14),
              child: Icon(icon),
            ),
            prefixIconColor: AppColors.muted,
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(right: isCompact ? 12 : 18),
                    child: IconTheme(
                      data: const IconThemeData(
                        color: AppColors.muted,
                        size: 24,
                      ),
                      child: suffix!,
                    ),
                  ),
            suffixIconColor: AppColors.muted,
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: isCompact ? 17 : 22,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.height,
    required this.label,
    required this.onPressed,
  });

  final double height;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final isCompact = height < 60;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? const [
                  AppColors.primary,
                  AppColors.secondary,
                  AppColors.accent,
                ]
              : [
                  AppColors.primary.withOpacity(0.56),
                  AppColors.secondary.withOpacity(0.56),
                ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 19 : 22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(enabled ? 0.24 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isCompact ? 19 : 22),
          child: SizedBox(
            height: height,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 18 : 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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
    final fontSize = isCompact ? 14.0 : 16.0;

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
