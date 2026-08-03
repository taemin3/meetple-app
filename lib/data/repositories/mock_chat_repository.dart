import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import 'chat_repository.dart';

class MockChatRepository implements ChatRepository {
  const MockChatRepository();

  @override
  Future<ChatRoomListPage> getRooms({int page = 0, int size = 20}) async {
    final rooms = _rooms();
    return ChatRoomListPage(
      content: rooms.take(size).toList(),
      page: page,
      size: size,
      totalElements: rooms.length,
      totalPages: rooms.isEmpty ? 0 : 1,
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
    final messages = _messages()
        .where((message) => message.roomId == roomId)
        .where(
          (message) =>
              beforeSequence == null || message.sequence < beforeSequence,
        )
        .where(
          (message) =>
              afterSequence == null || message.sequence > afterSequence,
        )
        .take(size)
        .toList();
    return ChatMessagePage(
      content: messages,
      hasMore: false,
      oldestSequence: messages.isEmpty ? null : messages.first.sequence,
      latestSequence: messages.isEmpty ? null : messages.last.sequence,
    );
  }

  @override
  Future<void> markRead(int roomId, int lastReadSequence) async {}

  List<ChatRoom> _rooms() {
    final messages = _messages();
    return [
      ChatRoom(
        roomId: 10,
        meetingId: 10,
        meetingTitle: '한강 러닝 크루 🏃',
        meetingStatus: 'RECRUITING',
        lastMessage: messages[2],
        unreadCount: 2,
        canSend: true,
      ),
      ChatRoom(
        roomId: 11,
        meetingId: 11,
        meetingTitle: '퇴근 후 영어 회화 모임',
        meetingStatus: 'FULL',
        lastMessage: ChatMessage(
          id: 4,
          roomId: 11,
          sequence: 1,
          clientMessageId: 'mock-4',
          senderId: 4,
          senderNickname: 'Alice',
          content: '역세권 자료 올려둘게요!',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        unreadCount: 1,
        canSend: true,
      ),
      ChatRoom(
        roomId: 12,
        meetingId: 12,
        meetingTitle: '감성 사진 출사 📷',
        meetingStatus: 'COMPLETED',
        lastMessage: ChatMessage(
          id: 5,
          roomId: 12,
          sequence: 1,
          clientMessageId: 'mock-5',
          senderId: 5,
          senderNickname: '모임장',
          content: '모임 장소를 변경했어요.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        unreadCount: 0,
        canSend: false,
      ),
    ];
  }

  List<ChatMessage> _messages() => [
        ChatMessage(
          id: 1,
          roomId: 10,
          sequence: 1,
          clientMessageId: 'mock-1',
          senderId: 2,
          senderNickname: '민준',
          content: '오늘은 여의나루역 2번 출구에서 만나요.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        ),
        ChatMessage(
          id: 2,
          roomId: 10,
          sequence: 2,
          clientMessageId: 'mock-2',
          senderId: 1,
          senderNickname: '김모임',
          content: '좋아요. 10분 전에 도착할게요.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 14)),
        ),
        ChatMessage(
          id: 3,
          roomId: 10,
          sequence: 3,
          clientMessageId: 'mock-3',
          senderId: 3,
          senderNickname: '서연',
          content: '러닝 전에 준비 운동부터 같이 해요 🙂',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
}
