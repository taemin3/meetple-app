import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meetple/widgets/category_icon.dart';

void main() {
  test('maps the fixed categories to the supplied SVG assets', () {
    expect(categoryIconAsset('운동'), 'assets/category_icons/dumbbell.svg');
    expect(
      categoryIconAsset('스터디'),
      'assets/category_icons/book-open-text.svg',
    );
    expect(categoryIconAsset('취미'), 'assets/category_icons/palette.svg');
    expect(categoryIconAsset('친목'), 'assets/category_icons/users.svg');
    expect(categoryIconAsset('여행'), 'assets/category_icons/plane.svg');
    expect(categoryIconAsset('맛집'), 'assets/category_icons/utensils.svg');
    expect(categoryIconAsset('비즈니스'), 'assets/category_icons/briefcase.svg');
    expect(categoryIconAsset('반려동물'), 'assets/category_icons/paw-print.svg');
  });

  testWidgets('renders a supplied category icon as SVG', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryIcon(category: '운동'),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('falls back to a Material icon for an unknown category', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryIcon(category: '알 수 없음'),
      ),
    );

    expect(find.byIcon(Icons.interests_outlined), findsOneWidget);
  });
}
