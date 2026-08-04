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

    expect(realtimeClient.session.sentContent, '  안녕하세요  ');
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

  testWidgets('preserves line breaks when sending and displaying a message', (
    WidgetTester tester,
  ) async {
    const multilineMessage = '  첫 번째 줄\n  두 번째 줄  ';
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

    final inputFinder = find.byKey(const Key('chat-message-input'));
    final input = tester.widget<TextField>(inputFinder);
    expect(input.keyboardType, TextInputType.multiline);

    await tester.enterText(inputFinder, multilineMessage);
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-chat-message')));
    await tester.pump();

    expect(realtimeClient.session.sentContent, multilineMessage);

    realtimeClient.session.addMessage(
      _chatMessage(
        id: 20,
        sequence: 20,
        senderId: 1,
        content: multilineMessage,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(multilineMessage), findsOneWidget);
  });

  testWidgets('shows realtime messages after persisted history fails', (
    WidgetTester tester,
  ) async {
    final realtimeClient = _FakeChatRealtimeClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatRoomPage(
          room: _room,
          chatRepository: _ChatRoomRepository(loadError: Exception()),
          chatRealtimeClient: realtimeClient,
          currentMemberId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이전 메시지를 불러오지 못했습니다.'), findsOneWidget);

    realtimeClient.session.addMessage(_receivedMessage);
    await tester.pumpAndSettle();

    expect(find.text('반가워요.'), findsOneWidget);
    expect(find.text('이전 메시지를 불러오지 못했습니다.'), findsNothing);
  });

  testWidgets('marks background messages as read only after resuming', (
    WidgetTester tester,
  ) async {
    final repository = _ChatRoomRepository();
    final realtimeClient = _FakeChatRealtimeClient();
    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

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

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    realtimeClient.session.addMessage(_receivedMessage);
    await tester.pump();

    expect(repository.markedSequence, isNull);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(repository.markedSequence, 3);
  });

  testWidgets('keeps scroll position when a message arrives above the bottom', (
    WidgetTester tester,
  ) async {
    final realtimeClient = _FakeChatRealtimeClient();
    final history = List<ChatMessage>.generate(
      30,
      (index) => _chatMessage(
        id: index + 1,
        sequence: index + 1,
        content: '이전 메시지 ${index + 1}',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatRoomPage(
          room: _room,
          chatRepository: _ChatRoomRepository(messages: history),
          chatRealtimeClient: realtimeClient,
          currentMemberId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final messageList = find.byKey(const Key('chat-message-list'));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: messageList, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    await tester.drag(messageList, const Offset(0, 500));
    await tester.pumpAndSettle();
    final positionBeforeMessage = scrollable.position.pixels;
    expect(
      scrollable.position.maxScrollExtent - positionBeforeMessage,
      greaterThan(120),
    );

    realtimeClient.session.addMessage(
      _chatMessage(id: 31, sequence: 31, content: '새로 도착한 메시지'),
    );
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, closeTo(positionBeforeMessage, 1));
    expect(
      find.byKey(const Key('jump-to-latest-chat-message')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('jump-to-latest-chat-message')))
          .width,
      lessThan(120),
    );

    await tester.tap(find.byKey(const Key('jump-to-latest-chat-message')));
    await tester.pumpAndSettle();

    expect(
      scrollable.position.maxScrollExtent - scrollable.position.pixels,
      closeTo(0, 1),
    );

    await tester.drag(messageList, const Offset(0, 500));
    await tester.pumpAndSettle();
    realtimeClient.session.addMessage(
      _chatMessage(
        id: 32,
        sequence: 32,
        senderId: 1,
        content: '내가 보낸 메시지',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      scrollable.position.maxScrollExtent - scrollable.position.pixels,
      closeTo(0, 1),
    );
    expect(
      find.byKey(const Key('jump-to-latest-chat-message')),
      findsNothing,
    );
  });

  testWidgets('shows time only on the last message in a same-minute group', (
    WidgetTester tester,
  ) async {
    final sameMinute = DateTime(2026, 8, 4, 10, 15);
    final history = [
      _chatMessage(
        id: 1,
        sequence: 1,
        content: '첫 번째 메시지',
        createdAt: sameMinute,
      ),
      _chatMessage(
        id: 2,
        sequence: 2,
        content: '두 번째 메시지',
        createdAt: sameMinute.add(const Duration(seconds: 30)),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ChatRoomPage(
          room: _room,
          chatRepository: _ChatRoomRepository(messages: history),
          chatRealtimeClient: _FakeChatRealtimeClient(),
          currentMemberId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('10:15'), findsOneWidget);
  });
}

class _ChatRoomRepository implements ChatRepository {
  _ChatRoomRepository({
    this.messages = const [],
    this.loadError,
  });

  final List<ChatMessage> messages;
  final Object? loadError;
  int? markedSequence;

  @override
  Future<ChatMessagePage> getMessages(
    int roomId, {
    int? beforeSequence,
    int? afterSequence,
    int size = 50,
  }) async {
    if (loadError case final error?) throw error;
    return ChatMessagePage(
      content: messages,
      hasMore: false,
      latestSequence: messages.isEmpty ? null : messages.last.sequence,
    );
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

final _receivedMessage = _chatMessage(
  id: 3,
  sequence: 3,
  content: '반가워요.',
);

ChatMessage _chatMessage({
  required int id,
  required int sequence,
  required String content,
  int senderId = 2,
  DateTime? createdAt,
}) {
  return ChatMessage(
    id: id,
    roomId: 10,
    sequence: sequence,
    clientMessageId: 'client-message-$id',
    senderId: senderId,
    senderNickname: '민준',
    content: content,
    createdAt:
        createdAt ?? DateTime(2026, 8, 4, 10).add(Duration(minutes: sequence)),
  );
}
