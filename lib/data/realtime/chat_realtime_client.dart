import '../../models/chat_message.dart';

enum ChatRealtimeConnectionState {
  connecting,
  connected,
  disconnected,
}

class ChatRealtimeException implements Exception {
  const ChatRealtimeException(
    this.message, {
    this.code,
    this.reason,
    this.roomId,
  });

  final String message;
  final String? code;
  final String? reason;
  final int? roomId;

  bool get isAccessRevoked => code == 'CHAT_ACCESS_REVOKED';

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
