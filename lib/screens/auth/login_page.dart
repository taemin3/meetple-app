import 'package:flutter/material.dart';

import '../../app/app_route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/auth_session.dart';
import '../../widgets/primary_gradient_button.dart';
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          children: [
            const AuthHeader(title: '로그인', subtitle: '밋플에서 오늘의 모임을 찾아보세요.'),
            const SizedBox(height: 30),
            AuthTextField(
              controller: _emailController,
              label: '이메일',
              hintText: 'meetple@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            AuthTextField(
              controller: _passwordController,
              label: '비밀번호',
              hintText: '비밀번호를 입력하세요',
              obscureText: true,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              AuthErrorText(message: _errorMessage!),
            ],
            const SizedBox(height: 26),
            PrimaryGradientButton(
              label: _isSubmitting ? '로그인 중...' : '로그인하기',
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _openSignUp,
              child: const Text('아직 계정이 없나요? 회원가입'),
            ),
          ],
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
