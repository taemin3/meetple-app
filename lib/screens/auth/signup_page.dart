import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../models/auth_session.dart';
import '../../widgets/primary_gradient_button.dart';
import 'auth_form_widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
    this.authRepository = const MockAuthRepository(),
  });

  final AuthRepository authRepository;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
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
            const AuthHeader(title: '회원가입', subtitle: '밋플에서 함께할 사람들을 만나보세요.'),
            const SizedBox(height: 30),
            AuthTextField(
              controller: _nicknameController,
              label: '닉네임',
              hintText: '김모임',
            ),
            const SizedBox(height: 18),
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
              label: _isSubmitting ? '가입 중...' : '회원가입하기',
              onPressed: _submit,
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
      final session = await widget.authRepository.signUp(
        nickname: _nicknameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      _complete(session);
    } on Exception catch (error) {
      setState(() => _errorMessage = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _complete(AuthSession session) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(session);
  }
}
