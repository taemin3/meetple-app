import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/chat_repository.dart';
import 'package:meetple/models/chat_message.dart';
import 'package:meetple/models/chat_room.dart';
import 'package:meetple/screens/chat/chat_page.dart';

void main() {
  testWidgets('shows chat rooms and opens persisted message history', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _StaticChatRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatPage(
            chatRepository: repository,
            currentMemberId: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('채팅'), findsOneWidget);
    expect(find.text('한강 러닝 크루'), findsOneWidget);
    expect(find.text('민준: 곧 도착해요.'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-room-10')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);
    expect(find.text('곧 도착해요.'), findsOneWidget);
    expect(find.text('저도 가는 중이에요.'), findsOneWidget);
    expect(find.text('실시간 연결 후 메시지를 보낼 수 있어요.'), findsOneWidget);
    expect(repository.markedRoomId, 10);
    expect(repository.markedSequence, 2);
  });
}

class _StaticChatRepository implements ChatRepository {
  int? markedRoomId;
  int? markedSequence;

  @override
  Future<ChatRoomListPage> getRooms({int page = 0, int size = 20}) async {
    return ChatRoomListPage(
      content: [
        ChatRoom(
          roomId: 10,
          meetingId: 10,
          meetingTitle: '한강 러닝 크루',
          meetingStatus: 'RECRUITING',
          lastMessage: _messages.first,
          unreadCount: 3,
          canSend: true,
        ),
      ],
      page: 0,
      size: 20,
      totalElements: 1,
      totalPages: 1,
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
    return ChatMessagePage(
      content: _messages,
      hasMore: false,
      oldestSequence: 1,
      latestSequence: 2,
    );
  }

  @override
  Future<void> markRead(int roomId, int lastReadSequence) async {
    markedRoomId = roomId;
    markedSequence = lastReadSequence;
  }
}

final _messages = [
  ChatMessage(
    id: 1,
    roomId: 10,
    sequence: 1,
    clientMessageId: 'client-1',
    senderId: 2,
    senderNickname: '민준',
    content: '곧 도착해요.',
    createdAt: DateTime(2026, 8, 4, 9, 30),
  ),
  ChatMessage(
    id: 2,
    roomId: 10,
    sequence: 2,
    clientMessageId: 'client-2',
    senderId: 1,
    senderNickname: '김모임',
    content: '저도 가는 중이에요.',
    createdAt: DateTime(2026, 8, 4, 9, 31),
  ),
];
