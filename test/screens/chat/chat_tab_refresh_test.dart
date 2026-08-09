import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/meetple_app.dart';
import 'package:meetple/data/repositories/chat_repository.dart';
import 'package:meetple/models/chat_message.dart';
import 'package:meetple/models/chat_room.dart';

void main() {
  testWidgets('reloads chat rooms when returning to the chat tab', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _CountingChatRepository();

    await tester.pumpWidget(MeetpleApp(chatRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('채팅'));
    await tester.pumpAndSettle();
    expect(repository.getRoomsCount, 1);

    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('채팅'));
    await tester.pumpAndSettle();

    expect(repository.getRoomsCount, 2);
  });
}

class _CountingChatRepository implements ChatRepository {
  int getRoomsCount = 0;

  @override
  Future<ChatRoom> getRoom(int roomId) {
    throw UnimplementedError();
  }

  @override
  Future<ChatRoomListPage> getRooms({int page = 0, int size = 20}) async {
    getRoomsCount++;
    return ChatRoomListPage(
      content: const [],
      page: page,
      size: size,
      totalElements: 0,
      totalPages: 0,
      isFirst: true,
      isLast: true,
    );
  }

  @override
  Future<ChatMessagePage> getMessages(
    int roomId, {
    int? beforeSequence,
    int? afterSequence,
    int size = 50,
  }) async {
    return const ChatMessagePage(content: [], hasMore: false);
  }

  @override
  Future<void> markRead(int roomId, int lastReadSequence) async {}
}
