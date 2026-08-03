class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.sequence,
    required this.clientMessageId,
    required this.senderId,
    required this.senderNickname,
    required this.content,
    required this.createdAt,
    this.senderProfileImageUrl,
  });

  final int id;
  final int roomId;
  final int sequence;
  final String clientMessageId;
  final int senderId;
  final String senderNickname;
  final String? senderProfileImageUrl;
  final String content;
  final DateTime createdAt;
}

class ChatMessagePage {
  const ChatMessagePage({
    required this.content,
    required this.hasMore,
    this.oldestSequence,
    this.latestSequence,
  });

  final List<ChatMessage> content;
  final bool hasMore;
  final int? oldestSequence;
  final int? latestSequence;
}
