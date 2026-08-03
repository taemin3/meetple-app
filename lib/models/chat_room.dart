import 'chat_message.dart';

class ChatRoom {
  const ChatRoom({
    required this.roomId,
    required this.meetingId,
    required this.meetingTitle,
    required this.meetingStatus,
    required this.unreadCount,
    required this.canSend,
    this.thumbnailImageUrl,
    this.lastMessage,
  });

  final int roomId;
  final int meetingId;
  final String meetingTitle;
  final String meetingStatus;
  final String? thumbnailImageUrl;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool canSend;
}

class ChatRoomListPage {
  const ChatRoomListPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isFirst,
    required this.isLast,
  });

  final List<ChatRoom> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isFirst;
  final bool isLast;
}
