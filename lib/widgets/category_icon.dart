import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _categoryIconAssets = <String, String>{
  '운동': 'assets/category_icons/dumbbell.svg',
  '스터디': 'assets/category_icons/book-open-text.svg',
  '취미': 'assets/category_icons/palette.svg',
  '친목': 'assets/category_icons/users.svg',
  '여행': 'assets/category_icons/plane.svg',
  '맛집': 'assets/category_icons/utensils.svg',
  '비즈니스': 'assets/category_icons/briefcase.svg',
  '반려동물': 'assets/category_icons/paw-print.svg',
};

String? categoryIconAsset(String category) {
  return _categoryIconAssets[category.trim()];
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.color,
    this.size = 24,
  });

  final String category;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = categoryIconAsset(category);
    if (asset == null) {
      return Icon(Icons.interests_outlined, color: color, size: size);
    }

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
