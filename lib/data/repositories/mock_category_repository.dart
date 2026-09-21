import '../../models/meeting_category.dart';
import 'category_repository.dart';

class MockCategoryRepository implements CategoryRepository {
  const MockCategoryRepository();

  @override
  Future<List<MeetingCategory>> findAll() async {
    return const [
      MeetingCategory(id: 1, name: '운동'),
      MeetingCategory(id: 2, name: '스터디'),
      MeetingCategory(id: 3, name: '취미'),
      MeetingCategory(id: 4, name: '친목'),
      MeetingCategory(id: 5, name: '여행'),
      MeetingCategory(id: 6, name: '맛집'),
      MeetingCategory(id: 7, name: '비즈니스'),
      MeetingCategory(id: 8, name: '반려동물'),
    ];
  }
}
