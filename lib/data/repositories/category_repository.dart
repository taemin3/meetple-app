import '../../models/meeting_category.dart';

abstract interface class CategoryRepository {
  Future<List<MeetingCategory>> findAll();
}
