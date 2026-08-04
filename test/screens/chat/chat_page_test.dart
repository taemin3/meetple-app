import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/core/network/api_client.dart';
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
    expect(
      tester.getCenter(find.byKey(const Key('chat-room-time-10'))).dy,
      greaterThan(tester.getCenter(find.text('3')).dy),
    );

    await tester.tap(find.byKey(const Key('chat-room-10')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-message-list')), findsOneWidget);
    expect(find.text('곧 도착해요.'), findsOneWidget);
    expect(find.text('저도 가는 중이에요.'), findsOneWidget);
    expect(find.byKey(const Key('chat-message-input')), findsOneWidget);
    expect(repository.markedRoomId, 10);
    expect(repository.markedSequence, 2);
  });

  testWidgets('loads every chat room page', (WidgetTester tester) async {
    final repository = _PagedChatRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatPage(chatRepository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [0, 1]);
    expect(find.text('첫 번째 채팅방'), findsOneWidget);
    expect(find.text('두 번째 채팅방'), findsOneWidget);
  });

  testWidgets('waits for read completion before refreshing room list', (
    WidgetTester tester,
  ) async {
    final repository = _DelayedReadChatRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatPage(chatRepository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-room-10')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();

    expect(repository.getRoomsCount, 1);

    repository.completeRead();
    await tester.pumpAndSettle();

    expect(repository.getRoomsCount, 2);
  });

  testWidgets('handles a failed refresh without an unhandled async error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatPage(chatRepository: _FailingChatRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-refresh')));
    await tester.pumpAndSettle();

    expect(find.text('채팅방을 불러오지 못했습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _StaticChatRepository implements ChatRepository {
  int? markedRoomId;
  int? markedSequence;
  int getRoomsCount = 0;

  @override
  Future<ChatRoomListPage> getRooms({int page = 0, int size = 20}) async {
    getRoomsCount++;
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

class _DelayedReadChatRepository extends _StaticChatRepository {
  final Completer<void> _readCompleter = Completer<void>();

  @override
  Future<void> markRead(int roomId, int lastReadSequence) async {
    markedRoomId = roomId;
    markedSequence = lastReadSequence;
    await _readCompleter.future;
  }

  void completeRead() => _readCompleter.complete();
}

class _PagedChatRepository implements ChatRepository {
  final List<int> requestedPages = [];

  @override
  Future<ChatRoomListPage> getRooms({int page = 0, int size = 20}) async {
    requestedPages.add(page);
    return ChatRoomListPage(
      content: [
        ChatRoom(
          roomId: page + 1,
          meetingId: page + 1,
          meetingTitle: page == 0 ? '첫 번째 채팅방' : '두 번째 채팅방',
          meetingStatus: 'RECRUITING',
          unreadCount: 0,
          canSend: true,
        ),
      ],
      page: page,
      size: size,
      totalElements: 2,
      totalPages: 2,
      isFirst: page == 0,
      isLast: page == 1,
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

class _FailingChatRepository implements ChatRepository {
  @override
  Future<ChatRoomListPage> getRooms({int page = 0, int size = 20}) {
    throw const ApiException(
      statusCode: 500,
      message: '채팅방을 불러오지 못했습니다.',
    );
  }

  @override
  Future<ChatMessagePage> getMessages(
    int roomId, {
    int? beforeSequence,
    int? afterSequence,
    int size = 50,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markRead(int roomId, int lastReadSequence) {
    throw UnimplementedError();
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
