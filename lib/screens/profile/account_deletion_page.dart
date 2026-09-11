import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/centered_page_app_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/surface_panel.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({
    super.key,
    required this.authRepository,
  });

  final AuthRepository authRepository;

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  final _passwordController = TextEditingController();
  bool _confirmed = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: const CenteredPageAppBar(title: '회원 탈퇴'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              const Text(
                '탈퇴는 되돌릴 수 없습니다.',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '아래 내용을 확인하고 현재 비밀번호를 입력해 주세요.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              const SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DeletionNotice(
                      title: '삭제되는 개인정보',
                      body: '이메일, 비밀번호, 닉네임, 소개, 지역, 프로필 이미지와 푸시 등록 정보',
                    ),
                    SizedBox(height: 16),
                    _DeletionNotice(
                      title: '유지될 수 있는 기록',
                      body:
                          '분쟁 대응과 서비스 무결성에 필요한 모임·참여 상태, 익명화된 채팅 순서, 약관 동의 시각',
                    ),
                    SizedBox(height: 16),
                    _DeletionNotice(
                      title: '진행 중인 모임',
                      body: '내가 주최한 진행 중 모임은 취소되고, 다른 모임의 대기·승인된 참여 신청도 취소됩니다.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                key: const Key('account_deletion_password'),
                controller: _passwordController,
                enabled: !_submitting,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: '현재 비밀번호',
                  errorText: _errorMessage,
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                key: const Key('account_deletion_confirm'),
                value: _confirmed,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  '위 내용을 확인했으며 계정을 영구 삭제하는 데 동의합니다.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _confirmed = value ?? false),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                key: const Key('account_deletion_submit'),
                label: _submitting ? '탈퇴 처리 중...' : '회원 탈퇴',
                onPressed: !_submitting && _confirmed ? _deleteAccount : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = '현재 비밀번호를 입력해 주세요.');
      return;
    }
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await widget.authRepository.deleteAccount(currentPassword: password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AccountDeletionException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = switch (error.failure) {
          AccountDeletionFailure.invalidPassword => '현재 비밀번호가 올바르지 않습니다.',
          AccountDeletionFailure.sessionExpired => '세션이 만료되었습니다. 다시 로그인해 주세요.',
          AccountDeletionFailure.network => '네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
          AccountDeletionFailure.unknown => error.message,
        };
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = '네트워크 상태를 확인한 뒤 다시 시도해 주세요.';
      });
    }
  }
}

class _DeletionNotice extends StatelessWidget {
  const _DeletionNotice({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(
          body,
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
      ],
    );
  }
}
