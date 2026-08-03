import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/data/repositories/chat_repository.dart';
import 'package:meetple/data/realtime/chat_realtime_client.dart';
import 'package:meetple/models/chat_message.dart';
import 'package:meetple/models/chat_room.dart';
import 'package:meetple/screens/chat/chat_room_page.dart';

void main() {
  testWidgets('sends and receives messages through the realtime session', (
    WidgetTester tester,
  ) async {
    final repository = _ChatRoomRepository();
    final realtimeClient = _FakeChatRealtimeClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatRoomPage(
          room: _room,
          chatRepository: repository,
          chatRealtimeClient: realtimeClient,
          currentMemberId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-message-input')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('chat-message-input')),
      '  안녕하세요  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-chat-message')));
    await tester.pump();

    expect(realtimeClient.session.sentContent, '안녕하세요');
    expect(
      realtimeClient.session.sentClientMessageId,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );

    realtimeClient.session.addMessage(_receivedMessage);
    await tester.pumpAndSettle();

    expect(find.text('반가워요.'), findsOneWidget);
    expect(repository.markedSequence, 3);

    realtimeClient.session.addMessage(_receivedMessage);
    await tester.pumpAndSettle();
    expect(find.text('반가워요.'), findsOneWidget);
  });

  testWidgets('shows STOMP errors and allows a manual reconnect', (
    WidgetTester tester,
  ) async {
    final realtimeClient = _FakeChatRealtimeClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatRoomPage(
          room: _room,
          chatRepository: _ChatRoomRepository(),
          chatRealtimeClient: realtimeClient,
          currentMemberId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    realtimeClient.session.addError('채팅방에 접근할 수 없습니다.');
    await tester.pump();
    expect(find.text('채팅방에 접근할 수 없습니다.'), findsOneWidget);

    realtimeClient.session.disconnect();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reconnect-chat')), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(realtimeClient.session.closed, isTrue);
  });
}

class _ChatRoomRepository implements ChatRepository {
  int? markedSequence;

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
  Future<ChatRoomListPage> getRooms({int page = 0, int size = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<void> markRead(int roomId, int lastReadSequence) async {
    markedSequence = lastReadSequence;
  }
}

class _FakeChatRealtimeClient implements ChatRealtimeClient {
  final _FakeChatRealtimeSession session = _FakeChatRealtimeSession();

  @override
  ChatRealtimeSession openRoom({
    required int roomId,
    required int currentMemberId,
  }) {
    return session;
  }
}

class _FakeChatRealtimeSession implements ChatRealtimeSession {
  final StreamController<ChatRealtimeConnectionState> _stateController =
      StreamController<ChatRealtimeConnectionState>.broadcast(sync: true);
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast(sync: true);
  final StreamController<ChatRealtimeException> _errorController =
      StreamController<ChatRealtimeException>.broadcast(sync: true);

  String? sentClientMessageId;
  String? sentContent;
  bool connected = false;
  bool closed = false;

  @override
  Stream<ChatRealtimeConnectionState> get connectionStates =>
      _stateController.stream;

  @override
  Stream<ChatRealtimeException> get errors => _errorController.stream;

  @override
  bool get isConnected => connected;

  @override
  Stream<ChatMessage> get messages => _messageController.stream;

  @override
  void activate() {
    connected = true;
    _stateController.add(ChatRealtimeConnectionState.connected);
  }

  @override
  void send({
    required String clientMessageId,
    required String content,
  }) {
    sentClientMessageId = clientMessageId;
    sentContent = content;
  }

  void addMessage(ChatMessage message) => _messageController.add(message);

  void addError(String message) {
    _errorController.add(ChatRealtimeException(message));
  }

  void disconnect() {
    connected = false;
    _stateController.add(ChatRealtimeConnectionState.disconnected);
  }

  @override
  Future<void> close() async {
    closed = true;
    connected = false;
    await Future.wait([
      _stateController.close(),
      _messageController.close(),
      _errorController.close(),
    ]);
  }
}

const _room = ChatRoom(
  roomId: 10,
  meetingId: 10,
  meetingTitle: '한강 러닝 크루',
  meetingStatus: 'RECRUITING',
  unreadCount: 0,
  canSend: true,
);

final _receivedMessage = ChatMessage(
  id: 3,
  roomId: 10,
  sequence: 3,
  clientMessageId: '8d36a57b-fbd1-4910-a02d-91ddcbaf8911',
  senderId: 2,
  senderNickname: '민준',
  content: '반가워요.',
  createdAt: DateTime(2026, 8, 4, 10),
);
