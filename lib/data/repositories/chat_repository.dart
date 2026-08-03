import '../../models/chat_message.dart';
import '../../models/chat_room.dart';

abstract interface class ChatRepository {
  Future<ChatRoomListPage> getRooms({
    int page = 0,
    int size = 20,
  });

  Future<ChatMessagePage> getMessages(
    int roomId, {
    int? beforeSequence,
    int? afterSequence,
    int size = 50,
  });

  Future<void> markRead(int roomId, int lastReadSequence);
}
