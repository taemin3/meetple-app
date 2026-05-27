import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/auth_session.dart';
import 'auth_form_widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
    required this.authRepository,
  });

  final AuthRepository authRepository;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _introController = TextEditingController();

  int _step = 0;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  bool _isServiceTermsAgreed = false;
  bool _isPrivacyTermsAgreed = false;
  bool _isAgeAgreed = false;
  bool _hasProfilePhoto = false;
  DateTime? _birthDate;
  String? _region;
  String? _errorMessage;

  bool get _isAllTermsAgreed =>
      _isServiceTermsAgreed && _isPrivacyTermsAgreed && _isAgeAgreed;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_rebuildCounter);
    _introController.addListener(_rebuildCounter);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    _introController.dispose();
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
              final horizontalPadding =
                  constraints.maxWidth < 380 ? 24.0 : 36.0;

              return Stack(
                children: [
                  SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      10,
                      horizontalPadding,
                      132,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SignUpHeader(
                              step: _step,
                              onBackPressed: _handleBackPressed,
                            ),
                            const SizedBox(height: 10),
                            _StepIndicator(step: _step),
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _step == 0
                                  ? _AccountStep(
                                      key: const ValueKey('account-step'),
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      passwordConfirmController:
                                          _passwordConfirmController,
                                      isPasswordVisible: _isPasswordVisible,
                                      isPasswordConfirmVisible:
                                          _isPasswordConfirmVisible,
                                      isAllTermsAgreed: _isAllTermsAgreed,
                                      isServiceTermsAgreed:
                                          _isServiceTermsAgreed,
                                      isPrivacyTermsAgreed:
                                          _isPrivacyTermsAgreed,
                                      isAgeAgreed: _isAgeAgreed,
                                      errorMessage: _errorMessage,
                                      togglePasswordVisibility: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                      togglePasswordConfirmVisibility: () {
                                        setState(() {
                                          _isPasswordConfirmVisible =
                                              !_isPasswordConfirmVisible;
                                        });
                                      },
                                      toggleAllTerms: _toggleAllTerms,
                                      toggleServiceTerms: () {
                                        setState(() {
                                          _isServiceTermsAgreed =
                                              !_isServiceTermsAgreed;
                                        });
                                      },
                                      togglePrivacyTerms: () {
                                        setState(() {
                                          _isPrivacyTermsAgreed =
                                              !_isPrivacyTermsAgreed;
                                        });
                                      },
                                      toggleAgeTerms: () {
                                        setState(() {
                                          _isAgeAgreed = !_isAgeAgreed;
                                        });
                                      },
                                    )
                                  : _ProfileStep(
                                      key: const ValueKey('profile-step'),
                                      nicknameController: _nicknameController,
                                      introController: _introController,
                                      hasProfilePhoto: _hasProfilePhoto,
                                      birthDate: _birthDate,
                                      region: _region,
                                      isSubmitting: _isSubmitting,
                                      errorMessage: _errorMessage,
                                      toggleProfilePhoto: () {
                                        setState(() {
                                          _hasProfilePhoto = !_hasProfilePhoto;
                                        });
                                      },
                                      selectBirthDate: _selectBirthDate,
                                      selectRegion: _selectRegion,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                    child: _SignUpStickyFooter(
                      step: _step,
                      isSubmitting: _isSubmitting,
                      onPrimaryPressed: _step == 0
                          ? _goToProfileStep
                          : (_isSubmitting ? null : _submit),
                      onSecondaryPressed: _step == 0
                          ? () => Navigator.of(context).pop()
                          : () {
                              setState(() {
                                _step = 0;
                                _errorMessage = null;
                              });
                            },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _rebuildCounter() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleBackPressed() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _step = 0;
      _errorMessage = null;
    });
  }

  void _toggleAllTerms() {
    setState(() {
      final nextValue = !_isAllTermsAgreed;
      _isServiceTermsAgreed = nextValue;
      _isPrivacyTermsAgreed = nextValue;
      _isAgeAgreed = nextValue;
    });
  }

  void _goToProfileStep() {
    final message = _accountStepErrorMessage();
    if (message != null) {
      setState(() => _errorMessage = message);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _step = 1;
      _errorMessage = null;
    });
  }

  String? _accountStepErrorMessage() {
    if (_emailController.text.trim().isEmpty) {
      return '이메일을 입력해 주세요.';
    }

    if (_passwordController.text.isEmpty) {
      return '비밀번호를 입력해 주세요.';
    }

    if (_passwordController.text.length < 8) {
      return '비밀번호는 8자 이상으로 입력해 주세요.';
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      return '비밀번호가 일치하지 않습니다.';
    }

    if (!_isAllTermsAgreed) {
      return '필수 약관에 모두 동의해 주세요.';
    }

    return null;
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 14, now.month, now.day),
    );

    if (selectedDate != null) {
      setState(() => _birthDate = selectedDate);
    }
  }

  Future<void> _selectRegion() async {
    final selectedRegion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        const regions = [
          '서울',
          '경기',
          '인천',
          '부산',
          '대구',
          '광주',
          '대전',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '거주 지역 선택',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ...regions.map(
                  (region) => ListTile(
                    title: Text(
                      region,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: _region == region
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.of(context).pop(region),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedRegion != null) {
      setState(() => _region = selectedRegion);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    if (_nicknameController.text.trim().isEmpty) {
      setState(() => _errorMessage = '닉네임을 입력해 주세요.');
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

  void _complete(AuthSession session) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(session);
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader({
    required this.step,
    required this.onBackPressed,
  });

  final int step;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            onPressed: onBackPressed,
            color: AppColors.ink,
            iconSize: 30,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        Column(
          children: [
            Image.asset(
              'assets/icons/app-icon-foreground.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 6),
            const Text(
              '회원가입',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step == 0 ? '밋플에 오신 것을 환영해요!' : '프로필 정보를 입력해주세요',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final accountDone = step == 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepMarker(
          label: '계정 정보',
          value: accountDone ? null : '1',
          isActive: step == 0,
          isDone: accountDone,
        ),
        Container(
          width: 72,
          height: 2,
          margin: const EdgeInsets.only(top: 19),
          color: AppColors.line,
        ),
        _StepMarker(
          label: '프로필 정보',
          value: '2',
          isActive: step == 1,
          isDone: false,
        ),
      ],
    );
  }
}

class _StepMarker extends StatelessWidget {
  const _StepMarker({
    required this.label,
    required this.value,
    required this.isActive,
    required this.isDone,
  });

  final String label;
  final String? value;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final color = isActive || isDone ? AppColors.primary : AppColors.line;
    final textColor = isActive || isDone ? AppColors.primary : AppColors.muted;

    return SizedBox(
      width: 82,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isActive
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    )
                  : null,
              color: isActive ? null : AppColors.surface,
              border: Border.all(color: color, width: 1.5),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : Text(
                      value ?? '',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.isPasswordVisible,
    required this.isPasswordConfirmVisible,
    required this.isAllTermsAgreed,
    required this.isServiceTermsAgreed,
    required this.isPrivacyTermsAgreed,
    required this.isAgeAgreed,
    required this.errorMessage,
    required this.togglePasswordVisibility,
    required this.togglePasswordConfirmVisibility,
    required this.toggleAllTerms,
    required this.toggleServiceTerms,
    required this.togglePrivacyTerms,
    required this.toggleAgeTerms,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool isPasswordVisible;
  final bool isPasswordConfirmVisible;
  final bool isAllTermsAgreed;
  final bool isServiceTermsAgreed;
  final bool isPrivacyTermsAgreed;
  final bool isAgeAgreed;
  final String? errorMessage;
  final VoidCallback togglePasswordVisibility;
  final VoidCallback togglePasswordConfirmVisibility;
  final VoidCallback toggleAllTerms;
  final VoidCallback toggleServiceTerms;
  final VoidCallback togglePrivacyTerms;
  final VoidCallback toggleAgeTerms;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          title: '계정 정보를 입력해주세요',
          subtitle: '로그인에 사용할 정보를 설정해주세요.',
        ),
        const SizedBox(height: 18),
        _SignUpField(
          label: '이메일',
          controller: emailController,
          icon: Icons.mail_outline_rounded,
          hintText: '이메일을 입력해주세요',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _SignUpField(
          label: '비밀번호',
          controller: passwordController,
          icon: Icons.lock_outline_rounded,
          hintText: '비밀번호를 입력해주세요',
          obscureText: !isPasswordVisible,
          helperText: '8자 이상, 영문/숫자/특수문자 조합',
          suffix: IconButton(
            tooltip: isPasswordVisible ? '비밀번호 숨기기' : '비밀번호 보기',
            onPressed: togglePasswordVisibility,
            icon: Icon(
              isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SignUpField(
          label: '비밀번호 확인',
          controller: passwordConfirmController,
          icon: Icons.lock_outline_rounded,
          hintText: '비밀번호를 다시 입력해주세요',
          obscureText: !isPasswordConfirmVisible,
          suffix: IconButton(
            tooltip: isPasswordConfirmVisible ? '비밀번호 숨기기' : '비밀번호 보기',
            onPressed: togglePasswordConfirmVisibility,
            icon: Icon(
              isPasswordConfirmVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('약관 동의'),
        const SizedBox(height: 8),
        _TermsCard(
          isAllTermsAgreed: isAllTermsAgreed,
          isServiceTermsAgreed: isServiceTermsAgreed,
          isPrivacyTermsAgreed: isPrivacyTermsAgreed,
          isAgeAgreed: isAgeAgreed,
          toggleAllTerms: toggleAllTerms,
          toggleServiceTerms: toggleServiceTerms,
          togglePrivacyTerms: togglePrivacyTerms,
          toggleAgeTerms: toggleAgeTerms,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 14),
          AuthErrorText(message: errorMessage!),
        ],
      ],
    );
  }
}

class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    super.key,
    required this.nicknameController,
    required this.introController,
    required this.hasProfilePhoto,
    required this.birthDate,
    required this.region,
    required this.isSubmitting,
    required this.errorMessage,
    required this.toggleProfilePhoto,
    required this.selectBirthDate,
    required this.selectRegion,
  });

  final TextEditingController nicknameController;
  final TextEditingController introController;
  final bool hasProfilePhoto;
  final DateTime? birthDate;
  final String? region;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback toggleProfilePhoto;
  final VoidCallback selectBirthDate;
  final VoidCallback selectRegion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('프로필 사진'),
        const SizedBox(height: 10),
        Row(
          children: [
            _ProfilePhotoPicker(
              isSelected: hasProfilePhoto,
              onTap: toggleProfilePhoto,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '프로필 사진을 등록해보세요!',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '나중에 변경할 수 있어요.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SignUpField(
          label: '닉네임',
          controller: nicknameController,
          icon: Icons.person_outline_rounded,
          hintText: '닉네임을 입력해주세요',
          maxLength: 10,
          trailingText: '${nicknameController.text.length}/10',
        ),
        const SizedBox(height: 18),
        _SignUpField(
          label: '한줄 소개',
          controller: introController,
          icon: Icons.edit_outlined,
          hintText: '자신을 한줄로 소개해주세요',
          maxLength: 30,
          maxLines: 4,
          trailingText: '${introController.text.length}/30',
        ),
        const SizedBox(height: 18),
        _PickerField(
          label: '생년월일',
          icon: Icons.calendar_today_outlined,
          text: birthDate == null ? '생년월일을 선택해주세요' : _formatDate(birthDate!),
          onTap: selectBirthDate,
        ),
        const SizedBox(height: 18),
        _PickerField(
          label: '거주 지역',
          icon: Icons.location_on_outlined,
          text: region ?? '거주 지역을 선택해주세요',
          onTap: selectRegion,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 14),
          AuthErrorText(message: errorMessage!),
        ],
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }
}

class _SignUpStickyFooter extends StatelessWidget {
  const _SignUpStickyFooter({
    required this.step,
    required this.isSubmitting,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  final int step;
  final bool isSubmitting;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final isProfileStep = step == 1;

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.canvas.withOpacity(0.97),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GradientActionButton(
                      label: isProfileStep
                          ? (isSubmitting ? '가입 중...' : '가입 완료')
                          : '다음',
                      onPressed: onPrimaryPressed,
                    ),
                    const SizedBox(height: 10),
                    isProfileStep
                        ? TextButton(
                            onPressed: onSecondaryPressed,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.muted,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            child: const Text('이전 단계로 돌아가기'),
                          )
                        : _LoginPrompt(onPressed: onSecondaryPressed),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SignUpField extends StatelessWidget {
  const _SignUpField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.maxLines = 1,
    this.helperText,
    this.trailingText,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final int maxLines;
  final String? helperText;
  final String? trailingText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line, width: 1.4),
          ),
          child: SizedBox(
            height: isMultiline ? 96 : 48,
            child: Stack(
              children: [
                TextField(
                  controller: controller,
                  keyboardType: obscureText
                      ? TextInputType.visiblePassword
                      : keyboardType,
                  obscureText: obscureText,
                  enableSuggestions: !obscureText,
                  autocorrect: !obscureText,
                  maxLength: maxLength,
                  maxLines: maxLines,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    counterText: '',
                    hintStyle: const TextStyle(
                      color: AppColors.subtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 12,
                        bottom: isMultiline ? 48 : 0,
                      ),
                      child: Icon(icon),
                    ),
                    prefixIconColor: AppColors.muted,
                    suffixIcon: suffix == null
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 12),
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
                    contentPadding: EdgeInsets.fromLTRB(
                      0,
                      isMultiline ? 14 : 12,
                      trailingText == null ? 18 : 58,
                      isMultiline ? 24 : 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
                if (trailingText != null)
                  Positioned(
                    right: 20,
                    bottom: isMultiline ? 12 : 14,
                    child: Text(
                      trailingText!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line, width: 1.4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({
    required this.isAllTermsAgreed,
    required this.isServiceTermsAgreed,
    required this.isPrivacyTermsAgreed,
    required this.isAgeAgreed,
    required this.toggleAllTerms,
    required this.toggleServiceTerms,
    required this.togglePrivacyTerms,
    required this.toggleAgeTerms,
  });

  final bool isAllTermsAgreed;
  final bool isServiceTermsAgreed;
  final bool isPrivacyTermsAgreed;
  final bool isAgeAgreed;
  final VoidCallback toggleAllTerms;
  final VoidCallback toggleServiceTerms;
  final VoidCallback togglePrivacyTerms;
  final VoidCallback toggleAgeTerms;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _TermsRow(
            key: const Key('sign_up_all_terms'),
            label: '모든 약관에 동의합니다',
            isChecked: isAllTermsAgreed,
            onTap: toggleAllTerms,
            isStrong: true,
          ),
          const Divider(height: 1),
          _TermsRow(
            label: '서비스 이용약관 동의 (필수)',
            isChecked: isServiceTermsAgreed,
            onTap: toggleServiceTerms,
            showChevron: true,
          ),
          _TermsRow(
            label: '개인정보 수집 및 이용 동의 (필수)',
            isChecked: isPrivacyTermsAgreed,
            onTap: togglePrivacyTerms,
            showChevron: true,
          ),
          _TermsRow(
            label: '만 14세 이상입니다 (필수)',
            isChecked: isAgeAgreed,
            onTap: toggleAgeTerms,
            showChevron: true,
          ),
        ],
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    super.key,
    required this.label,
    required this.isChecked,
    required this.onTap,
    this.isStrong = false,
    this.showChevron = false,
  });

  final String label;
  final bool isChecked;
  final VoidCallback onTap;
  final bool isStrong;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          isStrong ? 11 : 5,
          16,
          isStrong ? 11 : 5,
        ),
        child: Row(
          children: [
            _RoundCheck(isChecked: isChecked),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isStrong ? AppColors.ink : AppColors.muted,
                  fontSize: isStrong ? 14 : 13,
                  fontWeight: isStrong ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundCheck extends StatelessWidget {
  const _RoundCheck({required this.isChecked});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isChecked ? AppColors.primary : AppColors.softSurface,
        border: Border.all(
          color: isChecked ? AppColors.primary : AppColors.line,
          width: 1.5,
        ),
      ),
      child: isChecked
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 15,
            )
          : null,
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.secondary.withOpacity(0.55),
            radius: 18,
          ),
          child: SizedBox(
            width: 92,
            height: 92,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_outline_rounded
                        : Icons.photo_camera_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSelected ? '추가됨' : '사진 추가',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
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
                  AppColors.primary.withOpacity(0.52),
                  AppColors.secondary.withOpacity(0.52),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(enabled ? 0.22 : 0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '이미 계정이 있으신가요?',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 13,
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
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: const Text('로그인'),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 7.0;
      const dashGap = 6.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
