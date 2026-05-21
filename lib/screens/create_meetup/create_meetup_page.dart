import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/primary_gradient_button.dart';

class CreateMeetupPage extends StatelessWidget {
  const CreateMeetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        const CreateHeader(),
        const SizedBox(height: 24),
        const ImageUploadBox(),
        const SizedBox(height: 26),
        const CreateField(label: '모임 제목', hint: 'ex) 같이 책 읽는 모임'),
        const CreateField(
            label: '카테고리', hint: '카테고리를 선택하세요', suffix: Icons.chevron_right),
        const CreateField(
            label: '일시',
            hint: '날짜와 시간을 선택하세요',
            suffix: Icons.calendar_today_outlined),
        const CreateField(
            label: '장소', hint: '장소를 입력하세요', suffix: Icons.place_outlined),
        const CreateField(label: '인원', hint: '모집 인원을 입력하세요', suffixText: '명'),
        const CreateTextArea(),
        const SizedBox(height: 12),
        PrimaryGradientButton(label: '모임 만들기', onPressed: () {}),
      ],
    );
  }
}

class CreateHeader extends StatelessWidget {
  const CreateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const Expanded(
          child: Text(
            '모임 만들기',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class ImageUploadBox extends StatelessWidget {
  const ImageUploadBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              color: AppColors.primary, size: 36),
          SizedBox(height: 12),
          Text(
            '모임 이미지를 추가해 주세요',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CreateField extends StatelessWidget {
  const CreateField({
    super.key,
    required this.label,
    required this.hint,
    this.suffix,
    this.suffixText,
  });

  final String label;
  final String hint;
  final IconData? suffix;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffix != null ? Icon(suffix) : null,
              suffixText: suffixText,
            ),
          ),
        ],
      ),
    );
  }
}

class CreateTextArea extends StatelessWidget {
  const CreateTextArea({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '소개',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          TextField(
            readOnly: true,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '모임을 소개해주세요 :)',
              alignLabelWithHint: true,
              counterText: '0/500',
            ),
          ),
        ],
      ),
    );
  }
}
