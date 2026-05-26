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
              final horizontalPadding =
                  constraints.maxWidth < 380 ? 24.0 : 36.0;
              final topSpacing =
                  (constraints.maxHeight * 0.12).clamp(48.0, 108.0);
              final brandSpacing =
                  (constraints.maxHeight * 0.062).clamp(34.0, 64.0);
              final buttonSpacing =
                  (constraints.maxHeight * 0.052).clamp(32.0, 54.0);
              final signUpSpacing =
                  (constraints.maxHeight * 0.092).clamp(56.0, 92.0);

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          34,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: topSpacing),
                            const _LoginBrand(),
                            SizedBox(height: brandSpacing),
                            _LoginTextField(
                              controller: _emailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: '이메일을 입력해주세요',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 18),
                            _LoginTextField(
                              controller: _passwordController,
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
                            const SizedBox(height: 12),
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
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                child: const Text('비밀번호 찾기'),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              AuthErrorText(message: _errorMessage!),
                            ],
                            SizedBox(height: buttonSpacing),
                            _LoginButton(
                              label: _isSubmitting ? '로그인 중...' : '로그인',
                              onPressed: _isSubmitting ? null : _submit,
                            ),
                            SizedBox(height: signUpSpacing),
                            _SignUpPrompt(onPressed: _openSignUp),
                          ],
                        ),
                      ),
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
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/icons/app-icon-foreground.png',
          width: 172,
          height: 172,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        const _GradientText(
          '밋플',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            height: 1.06,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '우리, 가까운 모임으로 연결되는 순간',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 17,
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
    required this.icon,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
        height: 70,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enableSuggestions: !obscureText,
          autocorrect: !obscureText,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.subtle,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 24, right: 14),
              child: Icon(icon),
            ),
            prefixIconColor: AppColors.muted,
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 18),
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
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 22),
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
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

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
        borderRadius: BorderRadius.circular(22),
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
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 64,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
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
  const _SignUpPrompt({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        const SizedBox(width: 18),
        const Text(
          '계정이 없으신가요?',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 16,
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
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: const Text('회원가입'),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(
    this.text, {
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ).createShader(bounds);
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}
