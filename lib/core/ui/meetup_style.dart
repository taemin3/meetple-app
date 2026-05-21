import 'package:flutter/material.dart';

import '../../models/meetup.dart';
import '../theme/app_colors.dart';

Color meetupAccent(Meetup meetup) {
  switch (meetup.category) {
    case '스터디':
      return AppColors.blue;
    case '취미':
      return AppColors.orange;
    case '운동':
    default:
      return AppColors.primary;
  }
}

List<Color> meetupPhotoColors(Meetup meetup) {
  switch (meetup.title) {
    case '퇴근 후 영화 모임 🎬':
      return const [Color(0xFFB57C45), Color(0xFF2C2530)];
    case '감성 사진 출사 📸':
      return const [Color(0xFF9CBF6B), Color(0xFF244A38)];
    case '보드게임 모임 🎲':
      return const [Color(0xFFD09350), Color(0xFF3A2B31)];
    case '한강 러닝 크루 🏃':
    default:
      return const [Color(0xFFFFB66B), Color(0xFF352D45)];
  }
}

IconData meetupIcon(Meetup meetup) {
  switch (meetup.category) {
    case '스터디':
      return Icons.menu_book_outlined;
    case '취미':
      return Icons.photo_camera_outlined;
    case '운동':
    default:
      return Icons.directions_run;
  }
}
