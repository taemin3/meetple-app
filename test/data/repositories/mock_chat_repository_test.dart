import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/mock_chat_repository.dart';

void main() {
  test('applies page and size to mock chat room paging', () async {
    const repository = MockChatRepository();

    final first = await repository.getRooms(page: 0, size: 2);
    final second = await repository.getRooms(page: 1, size: 2);

    expect(first.content, hasLength(2));
    expect(first.isFirst, isTrue);
    expect(first.isLast, isFalse);
    expect(first.totalPages, 2);
    expect(second.content, hasLength(1));
    expect(second.content.single.roomId, isNot(first.content.first.roomId));
    expect(second.isFirst, isFalse);
    expect(second.isLast, isTrue);
  });
}
