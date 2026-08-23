import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/image_upload_repository.dart';
import '../../data/repositories/mock_image_upload_repository.dart';
import '../../models/auth_session.dart';
import '../../models/legal_document.dart';
import '../../widgets/auth_form_field.dart';
import '../../widgets/primary_button.dart';
import 'auth_form_widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
    required this.authRepository,
    this.imageUploadRepository = const MockImageUploadRepository(),
    this.pickProfileImage,
    this.now,
  });

  final AuthRepository authRepository;
  final ImageUploadRepository imageUploadRepository;
  final Future<XFile?> Function()? pickProfileImage;
  final DateTime Function()? now;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _emailVerificationCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _introController = TextEditingController();

  int _step = 0;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  bool _isAgeConfirmed = false;
  bool _isLoadingLegalDocuments = true;
  bool _isPickingProfileImage = false;
  bool _isProfileImageUploaded = false;
  bool _isSendingEmailVerificationCode = false;
  bool _isConfirmingEmailVerificationCode = false;
  int _emailVerificationResendSeconds = 0;
  ImageUploadFile? _profileImage;
  AuthSession? _createdSession;
  List<LegalDocument>? _legalDocuments;
  Timer? _emailVerificationResendTimer;
  DateTime? _emailVerificationResendExpiresAt;
  String? _emailVerificationRequestedEmail;
  String? _verifiedEmail;
  String? _signupVerificationToken;
  DateTime? _signupVerificationExpiresAt;
  String? _emailVerificationMessage;
  String? _emailVerificationError;
  String? _legalDocumentsError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _emailController.addListener(_handleEmailChanged);
    _nicknameController.addListener(_rebuildCounter);
    _introController.addListener(_rebuildCounter);
    _loadLegalDocuments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailVerificationResendTimer?.cancel();
    _emailController.removeListener(_handleEmailChanged);
    _emailController.dispose();
    _emailVerificationCodeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshEmailVerificationResendCountdown();
    }
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
              const horizontalPadding = 16.0;
              final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

              return Stack(
                children: [
                  SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      10,
                      horizontalPadding,
                      220 + keyboardInset,
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
                                      emailVerificationCodeController:
                                          _emailVerificationCodeController,
                                      isSendingEmailVerificationCode:
                                          _isSendingEmailVerificationCode,
                                      isConfirmingEmailVerificationCode:
                                          _isConfirmingEmailVerificationCode,
                                      emailVerificationRequested:
                                          _emailVerificationRequestedEmail !=
                                              null,
                                      isEmailVerified: _isEmailVerified,
                                      emailVerificationResendSeconds:
                                          _emailVerificationResendSeconds,
                                      emailVerificationMessage:
                                          _emailVerificationMessage,
                                      emailVerificationError:
                                          _emailVerificationError,
                                      passwordController: _passwordController,
                                      passwordConfirmController:
                                          _passwordConfirmController,
                                      isPasswordVisible: _isPasswordVisible,
                                      isPasswordConfirmVisible:
                                          _isPasswordConfirmVisible,
                                      legalDocuments: _legalDocuments,
                                      isLoadingLegalDocuments:
                                          _isLoadingLegalDocuments,
                                      legalDocumentsError: _legalDocumentsError,
                                      isAgeConfirmed: _isAgeConfirmed,
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
                                      sendEmailVerificationCode:
                                          _sendEmailVerificationCode,
                                      confirmEmailVerificationCode:
                                          _confirmEmailVerificationCode,
                                      retryLegalDocuments: _loadLegalDocuments,
                                      showLegalDocument: _showLegalDocument,
                                      toggleAgeConfirmation: () {
                                        setState(() {
                                          _isAgeConfirmed = !_isAgeConfirmed;
                                        });
                                      },
                                    )
                                  : _ProfileStep(
                                      key: const ValueKey('profile-step'),
                                      nicknameController: _nicknameController,
                                      introController: _introController,
                                      profileImage: _profileImage,
                                      isPickingProfileImage:
                                          _isPickingProfileImage,
                                      isSubmitting: _isSubmitting,
                                      errorMessage: _errorMessage,
                                      pickProfilePhoto: _pickProfilePhoto,
                                      removeProfilePhoto: _removeProfilePhoto,
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
                    bottom: keyboardInset,
                    child: PopScope<AuthSession?>(
                      canPop: _createdSession == null && _step == 0,
                      onPopInvokedWithResult: (didPop, result) {
                        if (!didPop) {
                          _handleBackPressed();
                        }
                      },
                      child: _SignUpStickyFooter(
                        step: _step,
                        isSubmitting: _isSubmitting,
                        legalDocuments: _legalDocuments,
                        showLegalDocument: _showLegalDocument,
                        onPrimaryPressed: _step == 0
                            ? _goToProfileStep
                            : (_isSubmitting || _isPickingProfileImage
                                ? null
                                : _submit),
                      ),
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

  String get _normalizedEmail => _emailController.text.trim().toLowerCase();

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  bool get _isEmailVerified {
    final expiresAt = _signupVerificationExpiresAt;
    return _signupVerificationToken != null &&
        _verifiedEmail == _normalizedEmail &&
        expiresAt != null &&
        expiresAt.isAfter(_now);
  }

  void _handleEmailChanged() {
    final requestedEmail = _emailVerificationRequestedEmail;
    if (requestedEmail == null || requestedEmail == _normalizedEmail) {
      return;
    }

    _emailVerificationResendTimer?.cancel();
    _emailVerificationCodeController.clear();
    setState(() {
      _emailVerificationRequestedEmail = null;
      _verifiedEmail = null;
      _signupVerificationToken = null;
      _signupVerificationExpiresAt = null;
      _emailVerificationResendExpiresAt = null;
      _emailVerificationResendSeconds = 0;
      _emailVerificationMessage = null;
      _emailVerificationError = null;
    });
  }

  Future<void> _sendEmailVerificationCode() async {
    if (_isSendingEmailVerificationCode ||
        _isConfirmingEmailVerificationCode ||
        _emailVerificationResendSeconds > 0 ||
        _isEmailVerified) {
      return;
    }

    final email = _normalizedEmail;
    if (!_looksLikeEmail(email)) {
      setState(() {
        _emailVerificationError =
            email.isEmpty ? '이메일을 입력해 주세요.' : '올바른 이메일 형식으로 입력해 주세요.';
        _emailVerificationMessage = null;
      });
      return;
    }

    setState(() {
      _isSendingEmailVerificationCode = true;
      _emailVerificationError = null;
      _emailVerificationMessage = null;
    });

    try {
      await widget.authRepository.sendSignupEmailVerificationCode(
        email: email,
      );
      if (!mounted || _normalizedEmail != email) {
        return;
      }
      _emailVerificationCodeController.clear();
      final resendExpiresAt = _now.add(const Duration(seconds: 60));
      setState(() {
        _emailVerificationRequestedEmail = email;
        _verifiedEmail = null;
        _signupVerificationToken = null;
        _signupVerificationExpiresAt = null;
        _emailVerificationResendExpiresAt = resendExpiresAt;
        _emailVerificationMessage = '인증번호를 전송했어요.';
        _emailVerificationResendSeconds = 60;
      });
      _startEmailVerificationResendTimer();
    } on Exception catch (error) {
      if (!mounted || _normalizedEmail != email) {
        return;
      }
      setState(() {
        _emailVerificationError = authErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isSendingEmailVerificationCode = false);
      }
    }
  }

  Future<void> _confirmEmailVerificationCode() async {
    if (_isSendingEmailVerificationCode ||
        _isConfirmingEmailVerificationCode ||
        _isEmailVerified) {
      return;
    }

    final email = _normalizedEmail;
    if (_emailVerificationRequestedEmail != email) {
      setState(() {
        _emailVerificationError = '현재 이메일로 인증번호를 먼저 받아주세요.';
        _emailVerificationMessage = null;
      });
      return;
    }

    final code = _emailVerificationCodeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _emailVerificationError = '인증번호 6자리를 입력해 주세요.';
        _emailVerificationMessage = null;
      });
      return;
    }

    setState(() {
      _isConfirmingEmailVerificationCode = true;
      _emailVerificationError = null;
      _emailVerificationMessage = null;
    });

    try {
      final verification = await widget.authRepository
          .confirmSignupEmailVerificationCode(email: email, code: code);
      if (!mounted || _normalizedEmail != email) {
        return;
      }
      _emailVerificationResendTimer?.cancel();
      setState(() {
        _verifiedEmail = email;
        _signupVerificationToken = verification.token;
        _signupVerificationExpiresAt = _now.add(verification.expiresIn);
        _emailVerificationResendExpiresAt = null;
        _emailVerificationResendSeconds = 0;
        _emailVerificationMessage = '이메일 인증이 완료됐어요.';
        _errorMessage = null;
      });
    } on Exception catch (error) {
      if (!mounted || _normalizedEmail != email) {
        return;
      }
      setState(() {
        _emailVerificationError = authErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isConfirmingEmailVerificationCode = false);
      }
    }
  }

  void _startEmailVerificationResendTimer() {
    _emailVerificationResendTimer?.cancel();
    _emailVerificationResendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshEmailVerificationResendCountdown(),
    );
  }

  void _refreshEmailVerificationResendCountdown() {
    if (!mounted) {
      _emailVerificationResendTimer?.cancel();
      return;
    }

    final expiresAt = _emailVerificationResendExpiresAt;
    final remainingMilliseconds =
        expiresAt?.difference(_now).inMilliseconds ?? 0;
    final remainingSeconds = remainingMilliseconds <= 0
        ? 0
        : (remainingMilliseconds / Duration.millisecondsPerSecond).ceil();

    if (remainingSeconds == 0) {
      _emailVerificationResendTimer?.cancel();
      _emailVerificationResendExpiresAt = null;
    }
    if (_emailVerificationResendSeconds != remainingSeconds) {
      setState(() => _emailVerificationResendSeconds = remainingSeconds);
    }
  }

  bool _looksLikeEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  void _handleBackPressed() {
    final createdSession = _createdSession;
    if (createdSession != null) {
      _complete(createdSession);
      return;
    }

    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _step = 0;
      _errorMessage = null;
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

    if (!_looksLikeEmail(_normalizedEmail)) {
      return '올바른 이메일 형식으로 입력해 주세요.';
    }

    if (!_isEmailVerified) {
      return _signupVerificationToken == null
          ? '이메일 인증을 완료해 주세요.'
          : '이메일 인증이 만료됐어요. 다시 인증해 주세요.';
    }

    if (_passwordController.text.isEmpty) {
      return '비밀번호를 입력해 주세요.';
    }

    final passwordValidationMessage =
        newPasswordValidationMessage(_passwordController.text);
    if (passwordValidationMessage != null) {
      return passwordValidationMessage;
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      return '비밀번호가 일치하지 않습니다.';
    }

    if (_legalDocuments == null) {
      return '약관 정보를 불러온 후 다시 시도해 주세요.';
    }

    if (!_isAgeConfirmed) {
      return '만 14세 이상임을 확인해 주세요.';
    }

    return null;
  }

  Future<void> _loadLegalDocuments() async {
    setState(() {
      _isLoadingLegalDocuments = true;
      _legalDocumentsError = null;
    });

    try {
      final documents = await widget.authRepository.getSignupLegalDocuments();
      if (!mounted) {
        return;
      }
      setState(() {
        _legalDocuments = documents;
        _isLoadingLegalDocuments = false;
        _legalDocumentsError = null;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _legalDocuments = null;
        _isLoadingLegalDocuments = false;
        _legalDocumentsError = authErrorMessage(error);
      });
    }
  }

  void _showLegalDocument(LegalDocumentType type) {
    LegalDocument? selectedDocument;
    for (final document in _legalDocuments ?? const <LegalDocument>[]) {
      if (document.type == type) {
        selectedDocument = document;
        break;
      }
    }
    if (selectedDocument == null) {
      _showSnackBar('약관 정보를 불러온 후 다시 시도해 주세요.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LegalDocumentSheet(document: selectedDocument!),
    );
  }

  Future<void> _pickProfilePhoto() async {
    if (_isSubmitting || _isPickingProfileImage) {
      return;
    }

    setState(() => _isPickingProfileImage = true);

    Object? pickError;
    ImageUploadFile? selectedImage;
    try {
      final pickProfileImage = widget.pickProfileImage;
      final file = pickProfileImage == null
          ? await ImagePicker().pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
            )
          : await pickProfileImage();
      if (file != null) {
        final contentType = _resolveImageContentType(file.mimeType, file.name);
        if (contentType == null) {
          throw const ImageUploadException(
            'jpg, png, webp 이미지만 선택할 수 있습니다.',
          );
        }
        selectedImage = ImageUploadFile(
          name: file.name.trim().isEmpty
              ? _defaultProfileImageFileName(contentType)
              : file.name,
          contentType: contentType,
          bytes: await file.readAsBytes(),
        );
      }
    } on Object catch (error) {
      pickError = error;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPickingProfileImage = false;
      if (selectedImage != null) {
        _profileImage = selectedImage;
        _isProfileImageUploaded = false;
        _errorMessage = null;
      }
    });

    if (pickError != null) {
      _showSnackBar(
        pickError is ImageUploadException
            ? pickError.message
            : '프로필 사진을 불러오지 못했습니다.',
      );
    }
  }

  void _removeProfilePhoto() {
    if (_isSubmitting || _isPickingProfileImage) {
      return;
    }
    setState(() {
      _profileImage = null;
      _isProfileImageUploaded = false;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isPickingProfileImage) {
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
      var session = _createdSession;
      if (session == null) {
        if (!_isEmailVerified) {
          setState(() {
            _step = 0;
            _signupVerificationToken = null;
            _signupVerificationExpiresAt = null;
            _errorMessage = '이메일 인증이 만료됐어요. 다시 인증해 주세요.';
          });
          return;
        }
        session = await widget.authRepository.signUp(
          nickname: _nicknameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          signupVerificationToken: _signupVerificationToken!,
          legalDocuments: _legalDocuments!,
        );
        _createdSession = session;
      }

      final profileImage = _profileImage;
      if (profileImage != null && !_isProfileImageUploaded) {
        final uploadedProfileImage =
            await widget.imageUploadRepository.uploadProfileImage(profileImage);
        _isProfileImageUploaded = true;
        session = AuthSession(
          user: session.user.copyWith(
            profileImageUrl: uploadedProfileImage.fileUrl,
          ),
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
        _createdSession = session;
      }
      _complete(session);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _createdSession == null
            ? authErrorMessage(error)
            : '가입은 완료됐지만 프로필 사진을 저장하지 못했습니다. 다시 시도해 주세요.';
      });
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

  String? _resolveImageContentType(String? mimeType, String fileName) {
    final normalizedMimeType = mimeType?.toLowerCase();
    if (normalizedMimeType == 'image/jpeg' ||
        normalizedMimeType == 'image/png' ||
        normalizedMimeType == 'image/webp') {
      return normalizedMimeType;
    }

    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  String _defaultProfileImageFileName(String contentType) {
    return switch (contentType) {
      'image/jpeg' => 'profile.jpg',
      'image/webp' => 'profile.webp',
      _ => 'profile.png',
    };
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    required this.emailVerificationCodeController,
    required this.isSendingEmailVerificationCode,
    required this.isConfirmingEmailVerificationCode,
    required this.emailVerificationRequested,
    required this.isEmailVerified,
    required this.emailVerificationResendSeconds,
    required this.emailVerificationMessage,
    required this.emailVerificationError,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.isPasswordVisible,
    required this.isPasswordConfirmVisible,
    required this.legalDocuments,
    required this.isLoadingLegalDocuments,
    required this.legalDocumentsError,
    required this.isAgeConfirmed,
    required this.errorMessage,
    required this.togglePasswordVisibility,
    required this.togglePasswordConfirmVisibility,
    required this.sendEmailVerificationCode,
    required this.confirmEmailVerificationCode,
    required this.retryLegalDocuments,
    required this.showLegalDocument,
    required this.toggleAgeConfirmation,
  });

  final TextEditingController emailController;
  final TextEditingController emailVerificationCodeController;
  final bool isSendingEmailVerificationCode;
  final bool isConfirmingEmailVerificationCode;
  final bool emailVerificationRequested;
  final bool isEmailVerified;
  final int emailVerificationResendSeconds;
  final String? emailVerificationMessage;
  final String? emailVerificationError;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool isPasswordVisible;
  final bool isPasswordConfirmVisible;
  final List<LegalDocument>? legalDocuments;
  final bool isLoadingLegalDocuments;
  final String? legalDocumentsError;
  final bool isAgeConfirmed;
  final String? errorMessage;
  final VoidCallback togglePasswordVisibility;
  final VoidCallback togglePasswordConfirmVisibility;
  final VoidCallback sendEmailVerificationCode;
  final VoidCallback confirmEmailVerificationCode;
  final VoidCallback retryLegalDocuments;
  final ValueChanged<LegalDocumentType> showLegalDocument;
  final VoidCallback toggleAgeConfirmation;

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
        AuthFormField(
          fieldKey: const Key('sign_up_email'),
          label: '이메일',
          controller: emailController,
          icon: Icons.mail_outline_rounded,
          hintText: '이메일을 입력해주세요',
          keyboardType: TextInputType.emailAddress,
          suffix: TextButton(
            key: const Key('sign_up_send_verification_code'),
            onPressed: isSendingEmailVerificationCode ||
                    isConfirmingEmailVerificationCode ||
                    emailVerificationResendSeconds > 0 ||
                    isEmailVerified
                ? null
                : sendEmailVerificationCode,
            child: isSendingEmailVerificationCode
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isEmailVerified
                        ? '인증 완료'
                        : emailVerificationResendSeconds > 0
                            ? '$emailVerificationResendSeconds초'
                            : emailVerificationRequested
                                ? '재전송'
                                : '인증번호 받기',
                  ),
          ),
        ),
        if (emailVerificationRequested) ...[
          const SizedBox(height: 12),
          AuthFormField(
            fieldKey: const Key('sign_up_email_verification_code'),
            label: '인증번호',
            controller: emailVerificationCodeController,
            icon: Icons.verified_outlined,
            hintText: '6자리 인증번호',
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffix: TextButton(
              key: const Key('sign_up_confirm_verification_code'),
              onPressed: isConfirmingEmailVerificationCode || isEmailVerified
                  ? null
                  : confirmEmailVerificationCode,
              child: isConfirmingEmailVerificationCode
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEmailVerified ? '확인 완료' : '확인'),
            ),
          ),
        ],
        if (emailVerificationMessage != null) ...[
          const SizedBox(height: 7),
          Text(
            emailVerificationMessage!,
            key: const Key('sign_up_email_verification_message'),
            style: TextStyle(
              color:
                  isEmailVerified ? const Color(0xFF16803C) : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (emailVerificationError != null) ...[
          const SizedBox(height: 7),
          AuthErrorText(
            key: const Key('sign_up_email_verification_error'),
            message: emailVerificationError!,
          ),
        ],
        const SizedBox(height: 12),
        AuthFormField(
          fieldKey: const Key('sign_up_password'),
          label: '비밀번호',
          controller: passwordController,
          icon: Icons.lock_outline_rounded,
          hintText: '비밀번호를 입력해주세요',
          keyboardType: TextInputType.visiblePassword,
          obscureText: !isPasswordVisible,
          enableSuggestions: false,
          autocorrect: false,
          helperText: '영문과 숫자를 포함해 8자 이상 입력해주세요',
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
        AuthFormField(
          fieldKey: const Key('sign_up_password_confirm'),
          label: '비밀번호 확인',
          controller: passwordConfirmController,
          icon: Icons.lock_outline_rounded,
          hintText: '비밀번호를 다시 입력해주세요',
          keyboardType: TextInputType.visiblePassword,
          obscureText: !isPasswordConfirmVisible,
          enableSuggestions: false,
          autocorrect: false,
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
        _LegalDocumentsCard(
          documents: legalDocuments,
          isLoading: isLoadingLegalDocuments,
          errorMessage: legalDocumentsError,
          isAgeConfirmed: isAgeConfirmed,
          onRetry: retryLegalDocuments,
          onShowDocument: showLegalDocument,
          onToggleAgeConfirmation: toggleAgeConfirmation,
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
    required this.profileImage,
    required this.isPickingProfileImage,
    required this.isSubmitting,
    required this.errorMessage,
    required this.pickProfilePhoto,
    required this.removeProfilePhoto,
  });

  final TextEditingController nicknameController;
  final TextEditingController introController;
  final ImageUploadFile? profileImage;
  final bool isPickingProfileImage;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback pickProfilePhoto;
  final VoidCallback removeProfilePhoto;

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
              imageBytes: profileImage?.bytes,
              isPicking: isPickingProfileImage,
              onTap: pickProfilePhoto,
              onRemove: removeProfilePhoto,
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
        AuthFormField(
          fieldKey: const Key('sign_up_nickname'),
          label: '닉네임',
          controller: nicknameController,
          icon: Icons.person_outline_rounded,
          hintText: '닉네임을 입력해주세요',
          maxLength: 10,
          trailingText: '${nicknameController.text.length}/10',
        ),
        const SizedBox(height: 18),
        AuthFormField(
          fieldKey: const Key('sign_up_introduction'),
          label: '한줄 소개',
          controller: introController,
          icon: Icons.edit_outlined,
          hintText: '자신을 한줄로 소개해주세요',
          maxLength: 30,
          maxLines: 4,
          trailingText: '${introController.text.length}/30',
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 14),
          AuthErrorText(message: errorMessage!),
        ],
      ],
    );
  }
}

class _SignUpStickyFooter extends StatelessWidget {
  const _SignUpStickyFooter({
    required this.step,
    required this.isSubmitting,
    required this.legalDocuments,
    required this.showLegalDocument,
    required this.onPrimaryPressed,
  });

  final int step;
  final bool isSubmitting;
  final List<LegalDocument>? legalDocuments;
  final ValueChanged<LegalDocumentType> showLegalDocument;
  final VoidCallback? onPrimaryPressed;

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
                    if (isProfileStep && legalDocuments != null) ...[
                      _LegalAgreementNotice(
                        onShowDocument: showLegalDocument,
                      ),
                      const SizedBox(height: 10),
                    ],
                    PrimaryButton(
                      label: isProfileStep ? '가입 완료' : '다음',
                      onPressed: onPrimaryPressed,
                      loading: isProfileStep && isSubmitting,
                      height: 48,
                      borderRadius: 14,
                      fontSize: 16,
                    ),
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

class _LegalDocumentsCard extends StatelessWidget {
  const _LegalDocumentsCard({
    required this.documents,
    required this.isLoading,
    required this.errorMessage,
    required this.isAgeConfirmed,
    required this.onRetry,
    required this.onShowDocument,
    required this.onToggleAgeConfirmation,
  });

  final List<LegalDocument>? documents;
  final bool isLoading;
  final String? errorMessage;
  final bool isAgeConfirmed;
  final VoidCallback onRetry;
  final ValueChanged<LegalDocumentType> onShowDocument;
  final VoidCallback onToggleAgeConfirmation;

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
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (documents == null) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              errorMessage ?? '약관 정보를 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextButton(
              key: const Key('sign_up_legal_documents_retry'),
              onPressed: onRetry,
              child: const Text('다시 불러오기'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _LegalDocumentRow(
          key: const Key('sign_up_service_terms'),
          label: '서비스 이용약관',
          onTap: () => onShowDocument(LegalDocumentType.serviceTerms),
        ),
        _LegalDocumentRow(
          key: const Key('sign_up_privacy_policy'),
          label: '개인정보 처리방침',
          onTap: () => onShowDocument(LegalDocumentType.privacyPolicy),
        ),
        const Divider(height: 1),
        _AgeConfirmationRow(
          isChecked: isAgeConfirmed,
          onTap: onToggleAgeConfirmation,
        ),
      ],
    );
  }
}

class _LegalDocumentRow extends StatelessWidget {
  const _LegalDocumentRow({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _AgeConfirmationRow extends StatelessWidget {
  const _AgeConfirmationRow({required this.isChecked, required this.onTap});

  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('sign_up_age_confirmation'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
        child: Row(
          children: [
            _RoundCheck(isChecked: isChecked),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                '만 14세 이상입니다 (필수)',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
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

class _LegalAgreementNotice extends StatelessWidget {
  const _LegalAgreementNotice({required this.onShowDocument});

  final ValueChanged<LegalDocumentType> onShowDocument;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: AppColors.muted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.4,
    );
    const linkStyle = TextStyle(
      color: AppColors.primary,
      fontSize: 11,
      fontWeight: FontWeight.w900,
      decoration: TextDecoration.underline,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('회원가입하면 ', style: textStyle),
        InkWell(
          key: const Key('sign_up_footer_service_terms'),
          onTap: () => onShowDocument(LegalDocumentType.serviceTerms),
          child: const Text('서비스 이용약관', style: linkStyle),
        ),
        const Text('에 동의하고 ', style: textStyle),
        InkWell(
          key: const Key('sign_up_footer_privacy_policy'),
          onTap: () => onShowDocument(LegalDocumentType.privacyPolicy),
          child: const Text('개인정보 처리방침', style: linkStyle),
        ),
        const Text('을 확인한 것으로 봅니다.', style: textStyle),
      ],
    );
  }
}

class _LegalDocumentSheet extends StatelessWidget {
  const _LegalDocumentSheet({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 10, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '버전 ${document.version}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    document.content,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.imageBytes,
    required this.isPicking,
    required this.onTap,
    required this.onRemove,
  });

  final Uint8List? imageBytes;
  final bool isPicking;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selectedImage = imageBytes;
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('sign_up_profile_photo_picker'),
                onTap: isPicking ? null : onTap,
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: AppColors.secondary.withOpacity(0.55),
                    radius: 18,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: selectedImage == null
                        ? Center(
                            child: isPicking
                                ? const CircularProgressIndicator()
                                : const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.photo_camera_outlined,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        '사진 추가',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                          )
                        : Image.memory(
                            selectedImage,
                            key: const Key('sign_up_profile_photo_preview'),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (selectedImage != null)
            Positioned(
              top: -8,
              right: -8,
              child: IconButton.filled(
                key: const Key('sign_up_profile_photo_remove'),
                tooltip: '프로필 사진 제거',
                onPressed: isPicking ? null : onRemove,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.square(28),
                  fixedSize: const Size.square(28),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ),
        ],
      ),
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
