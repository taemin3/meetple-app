import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/mock_chat_repository.dart';
import '../../data/realtime/chat_realtime_client.dart';
import '../../data/realtime/mock_chat_realtime_client.dart';
import '../../models/chat_room.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/network_image_with_skeleton.dart';
import 'chat_room_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.chatRepository = const MockChatRepository(),
    this.chatRealtimeClient = const MockChatRealtimeClient(),
    this.currentMemberId = 1,
    this.refreshToken = 0,
  });

  final ChatRepository chatRepository;
  final ChatRealtimeClient chatRealtimeClient;
  final int currentMemberId;
  final int refreshToken;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<List<ChatRoom>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _loadAllRooms();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatRepository != widget.chatRepository ||
        oldWidget.refreshToken != widget.refreshToken) {
      _roomsFuture = _loadAllRooms();
    }
  }

  Future<void> _refresh() async {
    final future = _loadAllRooms();
    setState(() {
      _roomsFuture = future;
    });
    try {
      await future;
    } on Exception {
      // 오류 표시는 FutureBuilder가 담당하고 콜백의 비동기 오류는 소비한다.
    }
  }

  Future<List<ChatRoom>> _loadAllRooms() async {
    const pageSize = 20;
    final rooms = <ChatRoom>[];
    var pageNumber = 0;

    while (true) {
      final page = await widget.chatRepository.getRooms(
        page: pageNumber,
        size: pageSize,
      );
      rooms.addAll(page.content);

      final nextPage = page.page + 1;
      if (page.isLast || page.totalPages == 0 || nextPage >= page.totalPages) {
        return rooms;
      }
      pageNumber = nextPage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          _ChatListHeader(onRefresh: _refresh),
          Expanded(
            child: FutureBuilder<List<ChatRoom>>(
              future: _roomsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const AppLoadingView(
                    message: '채팅방을 불러오는 중입니다.',
                    height: double.infinity,
                  );
                }
                if (snapshot.hasError) {
                  return AppErrorView(
                    message: _errorMessage(snapshot.error),
                    height: double.infinity,
                    onRetry: _refresh,
                  );
                }

                final rooms = snapshot.data ?? const <ChatRoom>[];
                if (rooms.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 140),
                        AppEmptyView(
                          message: '참여 중인 채팅방이 없습니다.',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    key: const Key('chat-room-list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return _ChatRoomTile(
                        room: room,
                        onTap: () => _openRoom(room),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRoom(ChatRoom room) async {
    Future<void>? readCompletion;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomPage(
          room: room,
          chatRepository: widget.chatRepository,
          chatRealtimeClient: widget.chatRealtimeClient,
          currentMemberId: widget.currentMemberId,
          onReadStarted: (completion) => readCompletion = completion,
        ),
      ),
    );
    if (readCompletion case final completion?) {
      await completion;
    }
    if (mounted) await _refresh();
  }

  String _errorMessage(Object? error) {
    if (error is ApiException) return error.message;
    return '채팅방을 불러오지 못했습니다.';
  }
}

class _ChatListHeader extends StatelessWidget {
  const _ChatListHeader({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '채팅',
              style: TextStyle(
                color: AppColors.ink,
                fontFamily: AppTheme.fontFamily,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          IconButton(
            key: const Key('chat-refresh'),
            tooltip: '채팅방 새로고침',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 24),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  const _ChatRoomTile({required this.room, required this.onTap});

  final ChatRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastMessage = room.lastMessage;
    final preview = lastMessage == null
        ? '아직 메시지가 없습니다.'
        : '${lastMessage.senderNickname}: ${lastMessage.content}';

    return Semantics(
      button: true,
      label: '${room.meetingTitle} 채팅방',
      child: InkWell(
        key: ValueKey('chat-room-${room.roomId}'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
          child: Row(
            children: [
              _RoomAvatar(
                imageUrl: room.thumbnailImageUrl,
                title: room.meetingTitle,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.meetingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (room.unreadCount > 0)
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Text(
                          room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 20),
                    const SizedBox(height: 7),
                    Text(
                      _formatRoomTime(lastMessage?.createdAt),
                      key: ValueKey('chat-room-time-${room.roomId}'),
                      style: const TextStyle(
                        color: AppColors.subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomAvatar extends StatelessWidget {
  const _RoomAvatar({required this.imageUrl, required this.title});

  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppColors.softSurface,
      alignment: Alignment.center,
      child: Text(
        title.isEmpty ? 'M' : title.characters.first,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: 54,
        child: imageUrl == null
            ? fallback
            : NetworkImageWithSkeleton(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                cacheWidth: 108,
                cacheHeight: 108,
                skeleton: fallback,
                errorWidget: fallback,
              ),
      ),
    );
  }
}

String _formatRoomTime(DateTime? dateTime) {
  if (dateTime == null) return '';
  final now = DateTime.now();
  final local = dateTime.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final difference = today.difference(date).inDays;
  if (difference == 0) {
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  if (difference == 1) return '어제';
  return '${local.month}/${local.day}';
}
