import 'dart:async';

import '../../models/chat_message.dart';
import 'chat_realtime_client.dart';

class MockChatRealtimeClient implements ChatRealtimeClient {
  const MockChatRealtimeClient();

  @override
  ChatRealtimeSession openRoom({
    required int roomId,
    required int currentMemberId,
  }) {
    return _MockChatRealtimeSession(
      roomId: roomId,
      currentMemberId: currentMemberId,
    );
  }
}

class _MockChatRealtimeSession implements ChatRealtimeSession {
  _MockChatRealtimeSession({
    required this.roomId,
    required this.currentMemberId,
  });

  final int roomId;
  final int currentMemberId;
  final StreamController<ChatRealtimeConnectionState> _stateController =
      StreamController<ChatRealtimeConnectionState>.broadcast();
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<ChatRealtimeException> _errorController =
      StreamController<ChatRealtimeException>.broadcast();

  bool _active = false;
  bool _closed = false;
  int _sequence = 1000;

  @override
  Stream<ChatRealtimeConnectionState> get connectionStates =>
      _stateController.stream;

  @override
  Stream<ChatMessage> get messages => _messageController.stream;

  @override
  Stream<ChatRealtimeException> get errors => _errorController.stream;

  @override
  bool get isConnected => _active && !_closed;

  @override
  void activate() {
    if (_active || _closed) return;
    _active = true;
    _stateController.add(ChatRealtimeConnectionState.connecting);
    scheduleMicrotask(() {
      if (!_closed) {
        _stateController.add(ChatRealtimeConnectionState.connected);
      }
    });
  }

  @override
  void send({
    required String clientMessageId,
    required String content,
  }) {
    if (!isConnected) {
      throw const ChatRealtimeException('실시간 채팅에 연결되어 있지 않습니다.');
    }

    final sequence = ++_sequence;
    _messageController.add(
      ChatMessage(
        id: sequence,
        roomId: roomId,
        sequence: sequence,
        clientMessageId: clientMessageId,
        senderId: currentMemberId,
        senderNickname: '나',
        content: content,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _active = false;
    _stateController.add(ChatRealtimeConnectionState.disconnected);
    await Future.wait([
      _stateController.close(),
      _messageController.close(),
      _errorController.close(),
    ]);
  }
}
