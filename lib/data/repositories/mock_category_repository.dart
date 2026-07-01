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
    ];
  }
}
