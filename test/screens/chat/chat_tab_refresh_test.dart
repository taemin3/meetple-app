import 'dart:async';

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
    final pendingReload = Completer<ChatRoomListPage>();
    repository.pendingReload = pendingReload;
    await tester.tap(find.text('채팅'));
    await tester.pump();

    expect(repository.getRoomsCount, 2);
    expect(find.text('채팅방을 불러오는 중입니다.'), findsNothing);
    expect(find.text('참여 중인 채팅방이 없습니다.'), findsOneWidget);

    pendingReload.complete(_emptyPage);
    await tester.pumpAndSettle();
  });
}

class _CountingChatRepository implements ChatRepository {
  int getRoomsCount = 0;
  Completer<ChatRoomListPage>? pendingReload;

  @override
  Future<ChatRoom> getRoom(int roomId) {
    throw UnimplementedError();
  }

  @override
  Future<ChatRoomListPage> getRooms({int page = 0, int size = 20}) async {
    getRoomsCount++;
    if (pendingReload case final pending?) return pending.future;
    return _emptyPage;
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

const _emptyPage = ChatRoomListPage(
  content: [],
  page: 0,
  size: 20,
  totalElements: 0,
  totalPages: 0,
  isFirst: true,
  isLast: true,
);
