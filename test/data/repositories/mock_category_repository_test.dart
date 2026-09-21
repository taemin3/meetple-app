import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/mock_category_repository.dart';

void main() {
  test('returns the fixed meeting categories in display order', () async {
    const repository = MockCategoryRepository();

    final categories = await repository.findAll();

    expect(
      categories.map((category) => category.name),
      [
        '운동',
        '스터디',
        '취미',
        '친목',
        '여행',
        '맛집',
        '비즈니스',
        '반려동물',
      ],
    );
  });
}
