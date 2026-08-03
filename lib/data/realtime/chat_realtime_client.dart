import '../../models/chat_message.dart';

enum ChatRealtimeConnectionState {
  connecting,
  connected,
  disconnected,
}

class ChatRealtimeException implements Exception {
  const ChatRealtimeException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ChatRealtimeClient {
  ChatRealtimeSession openRoom({
    required int roomId,
    required int currentMemberId,
  });
}

abstract interface class ChatRealtimeSession {
  Stream<ChatRealtimeConnectionState> get connectionStates;

  Stream<ChatMessage> get messages;

  Stream<ChatRealtimeException> get errors;

  bool get isConnected;

  void activate();

  void send({
    required String clientMessageId,
    required String content,
  });

  Future<void> close();
}
