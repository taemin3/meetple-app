import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetple/app/app_route_observer.dart';
import 'package:meetple/core/push/push_installation_id_store.dart';
import 'package:meetple/core/push/push_notification_message.dart';
import 'package:meetple/core/push/push_notification_service.dart';
import 'package:meetple/data/repositories/chat_repository.dart';
import 'package:meetple/data/repositories/push_device_token_repository.dart';
import 'package:meetple/data/realtime/chat_realtime_client.dart';
import 'package:meetple/models/chat_message.dart';
import 'package:meetple/models/chat_room.dart';
import 'package:meetple/screens/chat/chat_room_page.dart';
import 'package:meetple/widgets/network_image_with_skeleton.dart';

void main() {
  testWidgets('loads and toggles the chat room notification setting', (
    WidgetTester tester,
  ) async {
    final repository = _ChatNotificationSettingRepository(enabled: false);

    await tester.pumpWidget(
      MaterialApp(
        home: ChatRoomPage(
          room: _room,
          chatRepository: repository,
          chatRealtimeClient: _FakeChatRealtimeClient(),
          currentMemberId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-notification-toggle')));
    await tester.pumpAndSettle();

    expect(repository.updatedValues, [true]);
    expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
    expect(find.text('채팅방 알림을 켰습니다.'), findsOneWidget);
  });

  testWidgets(
    'suppresses active-room push only while realtime is connected',
    (WidgetTester tester) async {
      final realtimeClient = _FakeChatRealtimeClient();
      final pushNotificationService = FirebasePushNotificationService(
        tokenRepository: _NoopPushDeviceTokenRepository(),
        installationIdStore: MemoryPushInstallationIdStore(),
      );
      const activeRoomMessage = PushNotificationMessage({
        'route': 'CHAT_ROOM',
        'roomId': '10',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomPage(
            room: _room,
            chatRepository: _ChatRoomRepository(),
            chatRealtimeClient: realtimeClient,
            currentMemberId: 1,
            pushNotificationService: pushNotificationService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        pushNotificationService.shouldShowForeground(activeRoomMessage),
        isFalse,
      );

      realtimeClient.session.disconnect();
      await tester.pump();

      expect(
        pushNotificationService.shouldShowForeground(activeRoomMessage),
        isTrue,
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();
    },
  );

  testWidgets('sends and receives messages through the realtime session', (
    WidgetTester tester,
  ) async {
    final repository = _ChatRoomRepository();
    final realtimeClient = _FakeChatRealtimeClient();
    const draft = '  안녕하세요  ';

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
      draft,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-chat-message')));
    await tester.pump();

    expect(realtimeClient.session.sentContent, draft);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-input')))
          .controller
          ?.text,
      draft,
    );
    expect(
      realtimeClient.session.sentClientMessageId,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );

    realtimeClient.session.addMessage(
      _chatMessage(
        id: 2,
        sequence: 2,
        senderId: 1,
        clientMessageId: realtimeClient.session.sentClientMessageId,
        content: draft,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-input')))
          .controller
          ?.text,
      isEmpty,
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
    const draft = '전송에 실패해도 남아야 하는 메시지';

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
    await tester.enterText(inputFinder, draft);
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-chat-message')));
    await tester.pump();
    final firstClientMessageId = realtimeClient.session.sentClientMessageId;

    realtimeClient.session.addError('채팅방에 접근할 수 없습니다.');
    await tester.pump();
    expect(find.text('채팅방에 접근할 수 없습니다.'), findsOneWidget);
    expect(tester.widget<TextField>(inputFinder).controller?.text, draft);

    await tester.tap(find.byKey(const Key('send-chat-message')));
    await tester.pump();
    expect(realtimeClient.session.sentContent, draft);
    expect(realtimeClient.session.sentClientMessageId, firstClientMessageId);

    realtimeClient.session.disconnect();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reconnect-chat')), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(realtimeClient.session.closed, isTrue);
  });

  testWidgets('stops reconnecting after chat access is revoked', (
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

    realtimeClient.session.revokeAccess();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-access-revoked-notice')), findsOneWidget);
    expect(find.byKey(const Key('reconnect-chat')), findsNothing);
    expect(realtimeClient.session.closed, isTrue);

    await tester.pump(const Duration(minutes: 1));
    expect(realtimeClient.sessions, hasLength(1));
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
        clientMessageId: realtimeClient.session.sentClientMessageId,
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
    final repository = _ChatRoomRepository(loadError: Exception());

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

    expect(find.text('이전 메시지를 불러오지 못했습니다.'), findsOneWidget);

    realtimeClient.session.addMessage(_receivedMessage);
    await tester.pumpAndSettle();

    expect(find.text('반가워요.'), findsOneWidget);
    expect(find.text('이전 메시지를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.byKey(const Key('retry-chat-history')), findsOneWidget);

    repository.loadError = null;
    await tester.tap(find.byKey(const Key('retry-chat-history')));
    await tester.pumpAndSettle();

    expect(find.text('이전 메시지를 불러오지 못했습니다.'), findsNothing);
    expect(find.byKey(const Key('retry-chat-history')), findsNothing);
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

  testWidgets('recovers messages missed while realtime was disconnected', (
    WidgetTester tester,
  ) async {
    final messages = [
      _chatMessage(id: 1, sequence: 1, content: '연결 전 메시지'),
    ];
    final repository = _ChatRoomRepository(messages: messages);
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
    repository.afterSequenceRequests.clear();

    realtimeClient.session.disconnect();
    messages.add(
      _chatMessage(id: 2, sequence: 2, content: '연결 중 누락된 메시지'),
    );
    realtimeClient.session.reconnect();
    await tester.pumpAndSettle();

    expect(repository.afterSequenceRequests, [1]);
    expect(find.text('연결 중 누락된 메시지'), findsOneWidget);
  });

  testWidgets('automatically reconnects after a transport disconnect', (
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

    final firstSession = realtimeClient.session;
    firstSession.disconnect();
    await tester.pump();

    expect(realtimeClient.sessions, hasLength(1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(firstSession.closed, isTrue);
    expect(realtimeClient.sessions, hasLength(2));
    expect(realtimeClient.session.connected, isTrue);
  });

  testWidgets(
    'recovers from the persisted cursor when a live message arrives first',
    (WidgetTester tester) async {
      final messages = [
        _chatMessage(id: 1, sequence: 1, content: 'before disconnect'),
      ];
      final repository = _ChatRoomRepository(messages: messages);
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
      repository.afterSequenceRequests.clear();

      realtimeClient.session.disconnect();
      messages.add(
        _chatMessage(id: 2, sequence: 2, content: 'missed message'),
      );
      realtimeClient.session.reconnect();
      realtimeClient.session.addMessage(
        _chatMessage(id: 3, sequence: 3, content: 'live message'),
      );
      await tester.pumpAndSettle();

      expect(repository.afterSequenceRequests, [1]);
      expect(find.text('missed message'), findsOneWidget);
      expect(find.text('live message'), findsOneWidget);
    },
  );

  testWidgets('recovers a live sequence gap without reconnecting', (
    WidgetTester tester,
  ) async {
    final messages = [
      _chatMessage(id: 1, sequence: 1, content: 'first message'),
    ];
    final repository = _ChatRoomRepository(messages: messages);
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
    repository.afterSequenceRequests.clear();

    final missedMessage = _chatMessage(
      id: 2,
      sequence: 2,
      content: 'missed live message',
    );
    final receivedMessage = _chatMessage(
      id: 3,
      sequence: 3,
      content: 'received live message',
    );
    messages.addAll([missedMessage, receivedMessage]);
    realtimeClient.session.addMessage(receivedMessage);
    await tester.pumpAndSettle();

    expect(realtimeClient.sessions, hasLength(1));
    expect(repository.afterSequenceRequests, [1]);
    expect(find.text('missed live message'), findsOneWidget);
    expect(find.text('received live message'), findsOneWidget);
  });

  testWidgets('coalesces live gap recovery while a request is in progress', (
    WidgetTester tester,
  ) async {
    final messages = [
      _chatMessage(id: 1, sequence: 1, content: 'first message'),
    ];
    final repository = _ChatRoomRepository(messages: messages);
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
    repository.afterSequenceRequests.clear();
    repository.afterSequenceGate = Completer<void>();

    final missedMessage = _chatMessage(
      id: 2,
      sequence: 2,
      content: 'missed message',
    );
    final firstLiveMessage = _chatMessage(
      id: 3,
      sequence: 3,
      content: 'first live message',
    );
    final secondLiveMessage = _chatMessage(
      id: 4,
      sequence: 4,
      content: 'second live message',
    );
    messages.addAll([missedMessage, firstLiveMessage, secondLiveMessage]);

    realtimeClient.session.addMessage(firstLiveMessage);
    await tester.pump();
    expect(repository.afterSequenceRequests, [1]);

    realtimeClient.session.addMessage(secondLiveMessage);
    await tester.pump();
    expect(repository.afterSequenceRequests, [1]);

    repository.afterSequenceGate!.complete();
    await tester.pumpAndSettle();

    expect(repository.afterSequenceRequests, [1]);
    expect(find.text('missed message'), findsOneWidget);
    expect(find.text('first live message'), findsOneWidget);
    expect(find.text('second live message'), findsOneWidget);
  });

  testWidgets('retries live gap recovery after a request failure', (
    WidgetTester tester,
  ) async {
    final messages = [
      _chatMessage(id: 1, sequence: 1, content: 'first message'),
    ];
    final repository = _ChatRoomRepository(messages: messages);
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
    repository.afterSequenceRequests.clear();
    repository.afterSequenceFailuresRemaining = 1;

    final missedMessage = _chatMessage(
      id: 2,
      sequence: 2,
      content: 'retried missed message',
    );
    final receivedMessage = _chatMessage(
      id: 3,
      sequence: 3,
      content: 'retry trigger message',
    );
    messages.addAll([missedMessage, receivedMessage]);
    realtimeClient.session.addMessage(receivedMessage);
    await tester.pump();

    expect(repository.afterSequenceRequests, [1]);
    expect(find.text('retried missed message'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(repository.afterSequenceRequests, [1, 1]);
    expect(find.text('retried missed message'), findsOneWidget);
    expect(find.text('retry trigger message'), findsOneWidget);
  });

  testWidgets('retries live gap recovery after an empty response', (
    WidgetTester tester,
  ) async {
    final messages = [
      _chatMessage(id: 1, sequence: 1, content: 'first message'),
    ];
    final repository = _ChatRoomRepository(messages: messages);
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
    repository.afterSequenceRequests.clear();
    repository.emptyAfterSequenceResponsesRemaining = 1;

    final missedMessage = _chatMessage(
      id: 2,
      sequence: 2,
      content: 'eventually visible message',
    );
    final receivedMessage = _chatMessage(
      id: 3,
      sequence: 3,
      content: 'later live message',
    );
    messages.addAll([missedMessage, receivedMessage]);
    realtimeClient.session.addMessage(receivedMessage);
    await tester.pump();

    expect(repository.afterSequenceRequests, [1]);
    expect(find.text('eventually visible message'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(repository.afterSequenceRequests, [1, 1]);
    expect(find.text('eventually visible message'), findsOneWidget);
    expect(find.text('later live message'), findsOneWidget);
  });

  testWidgets('does not recover when live sequences are contiguous', (
    WidgetTester tester,
  ) async {
    final messages = [
      _chatMessage(id: 1, sequence: 1, content: 'first message'),
    ];
    final repository = _ChatRoomRepository(messages: messages);
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
    repository.afterSequenceRequests.clear();

    final nextMessage = _chatMessage(
      id: 2,
      sequence: 2,
      content: 'next live message',
    );
    messages.add(nextMessage);
    realtimeClient.session.addMessage(nextMessage);
    await tester.pumpAndSettle();

    expect(repository.afterSequenceRequests, isEmpty);
    expect(find.text('next live message'), findsOneWidget);
  });

  testWidgets('marks pending messages as read after returning to the route', (
    WidgetTester tester,
  ) async {
    final repository = _ChatRoomRepository();
    final realtimeClient = _FakeChatRealtimeClient();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appRouteObserver],
        home: ChatRoomPage(
          room: _room,
          chatRepository: repository,
          chatRealtimeClient: realtimeClient,
          currentMemberId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chatContext = tester.element(find.byType(ChatRoomPage));
    unawaited(
      Navigator.of(chatContext).push<void>(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      ),
    );
    await tester.pumpAndSettle();

    realtimeClient.session.addMessage(_receivedMessage);
    await tester.pump();
    expect(repository.markedSequence, isNull);

    Navigator.of(chatContext).pop();
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
    final repository = _ChatRoomRepository(messages: history);

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

    final messageList = find.byKey(const Key('chat-message-list'));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: messageList, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    await tester.drag(messageList, const Offset(0, 500));
    await tester.pumpAndSettle();
    final positionBeforeMessage = scrollable.position.pixels;
    expect(repository.markedSequence, 30);
    expect(
      scrollable.position.maxScrollExtent - positionBeforeMessage,
      greaterThan(120),
    );
    final jumpButton = find.byKey(
      const Key('jump-to-latest-chat-message'),
    );
    expect(jumpButton, findsOneWidget);
    expect(
      find.descendant(
        of: jumpButton,
        matching: find.byIcon(Icons.arrow_downward_rounded),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(jumpButton).width, lessThanOrEqualTo(48));
    expect(
      tester.getRect(messageList).right - tester.getRect(jumpButton).right,
      closeTo(16, 1),
    );

    realtimeClient.session.addMessage(
      _chatMessage(id: 31, sequence: 31, content: '새로 도착한 메시지'),
    );
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, closeTo(positionBeforeMessage, 1));
    expect(jumpButton, findsOneWidget);
    expect(repository.markedSequence, 30);

    await tester.tap(jumpButton);
    await tester.pumpAndSettle();

    expect(
      scrollable.position.maxScrollExtent - scrollable.position.pixels,
      closeTo(0, 1),
    );
    expect(repository.markedSequence, 31);

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

  testWidgets('groups consecutive messages from the same sender in a minute', (
    WidgetTester tester,
  ) async {
    final sameMinute = DateTime(2026, 8, 4, 10, 15);
    const profileImageUrl = 'https://example.com/profile.png';
    final history = [
      _chatMessage(
        id: 1,
        sequence: 1,
        content: '첫 번째 메시지',
        createdAt: sameMinute,
        senderProfileImageUrl: profileImageUrl,
      ),
      _chatMessage(
        id: 2,
        sequence: 2,
        content: '두 번째 메시지',
        createdAt: sameMinute.add(const Duration(seconds: 30)),
        senderProfileImageUrl: profileImageUrl,
      ),
      _chatMessage(
        id: 3,
        sequence: 3,
        content: '다음 분 메시지',
        createdAt: sameMinute.add(const Duration(minutes: 1)),
        senderProfileImageUrl: profileImageUrl,
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
    expect(find.text('10:16'), findsOneWidget);
    expect(find.byKey(const Key('chat-message-sender-1')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-sender-2')), findsNothing);
    expect(find.byKey(const Key('chat-message-sender-3')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-avatar-1')), findsOneWidget);
    expect(find.byKey(const Key('chat-message-avatar-2')), findsNothing);
    expect(find.byKey(const Key('chat-message-avatar-3')), findsOneWidget);
    final avatarImage = tester.widget<NetworkImageWithSkeleton>(
      find.byKey(const Key('chat-message-avatar-image-1')),
    );
    expect(avatarImage.imageUrl, profileImageUrl);
    expect(find.text(history.first.senderNickname), findsNWidgets(2));
  });

  testWidgets('shows date separators and labels the current date as today', (
    WidgetTester tester,
  ) async {
    final today = DateTime.now();
    final previousDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 1));
    final previousDateLabel =
        '${previousDate.year}년 ${previousDate.month}월 ${previousDate.day}일';
    final history = [
      _chatMessage(
        id: 1,
        sequence: 1,
        content: '어제 첫 메시지',
        createdAt: previousDate.add(const Duration(hours: 10)),
      ),
      _chatMessage(
        id: 2,
        sequence: 2,
        content: '어제 두 번째 메시지',
        createdAt: previousDate.add(const Duration(hours: 11)),
      ),
      _chatMessage(
        id: 3,
        sequence: 3,
        content: '오늘 메시지',
        createdAt: DateTime(today.year, today.month, today.day, 9),
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

    expect(find.text(previousDateLabel), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
  });
}

class _ChatRoomRepository implements ChatRepository {
  _ChatRoomRepository({
    this.messages = const [],
    this.loadError,
  });

  final List<ChatMessage> messages;
  Object? loadError;
  int? markedSequence;
  final List<int> afterSequenceRequests = [];
  Completer<void>? afterSequenceGate;
  int afterSequenceFailuresRemaining = 0;
  int emptyAfterSequenceResponsesRemaining = 0;

  @override
  Future<ChatRoom> getRoom(int roomId) {
    throw UnimplementedError();
  }

  @override
  Future<ChatMessagePage> getMessages(
    int roomId, {
    int? beforeSequence,
    int? afterSequence,
    int size = 50,
  }) async {
    if (loadError case final error?) throw error;
    if (afterSequence != null) {
      afterSequenceRequests.add(afterSequence);
      final gate = afterSequenceGate;
      if (gate != null) await gate.future;
      if (afterSequenceFailuresRemaining > 0) {
        afterSequenceFailuresRemaining -= 1;
        throw Exception('temporary recovery failure');
      }
      if (emptyAfterSequenceResponsesRemaining > 0) {
        emptyAfterSequenceResponsesRemaining -= 1;
        return const ChatMessagePage(content: [], hasMore: false);
      }
    }
    var filtered = messages.where((message) {
      if (beforeSequence != null) return message.sequence < beforeSequence;
      if (afterSequence != null) return message.sequence > afterSequence;
      return true;
    }).toList()
      ..sort((left, right) => left.sequence.compareTo(right.sequence));
    final hasMore = filtered.length > size;
    if (hasMore) {
      filtered = beforeSequence == null
          ? filtered.take(size).toList()
          : filtered.skip(filtered.length - size).toList();
    }
    return ChatMessagePage(
      content: filtered,
      hasMore: hasMore,
      latestSequence: filtered.isEmpty ? null : filtered.last.sequence,
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

class _ChatNotificationSettingRepository extends _ChatRoomRepository
    implements ChatNotificationSettingsRepository {
  _ChatNotificationSettingRepository({required this.enabled});

  bool enabled;
  final List<bool> updatedValues = [];

  @override
  Future<bool> getChatNotificationEnabled(int roomId) async => enabled;

  @override
  Future<bool> updateChatNotificationEnabled(int roomId, bool enabled) async {
    updatedValues.add(enabled);
    this.enabled = enabled;
    return enabled;
  }
}

class _FakeChatRealtimeClient implements ChatRealtimeClient {
  final List<_FakeChatRealtimeSession> sessions = [];

  _FakeChatRealtimeSession get session => sessions.last;

  @override
  ChatRealtimeSession openRoom({
    required int roomId,
    required int currentMemberId,
  }) {
    final session = _FakeChatRealtimeSession();
    sessions.add(session);
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

  void revokeAccess() {
    _errorController.add(
      const ChatRealtimeException(
        '참여 승인이 취소되어 채팅방 접근 권한이 해제되었습니다.',
        code: 'CHAT_ACCESS_REVOKED',
        reason: 'PARTICIPATION_APPROVAL_REVOKED',
        roomId: 10,
      ),
    );
  }

  void disconnect() {
    connected = false;
    _stateController.add(ChatRealtimeConnectionState.disconnected);
  }

  void reconnect() {
    connected = true;
    _stateController.add(ChatRealtimeConnectionState.connected);
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

class _NoopPushDeviceTokenRepository implements PushDeviceTokenRepository {
  @override
  Future<void> register({
    required String deviceId,
    required String token,
    required String platform,
  }) async {}
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
  String? clientMessageId,
  DateTime? createdAt,
  String? senderProfileImageUrl,
}) {
  return ChatMessage(
    id: id,
    roomId: 10,
    sequence: sequence,
    clientMessageId: clientMessageId ?? 'client-message-$id',
    senderId: senderId,
    senderNickname: '민준',
    senderProfileImageUrl: senderProfileImageUrl,
    content: content,
    createdAt:
        createdAt ?? DateTime(2026, 8, 4, 10).add(Duration(minutes: sequence)),
  );
}
