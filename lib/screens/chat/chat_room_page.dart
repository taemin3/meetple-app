import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/chat_repository.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_state_view.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.room,
    required this.chatRepository,
    required this.currentMemberId,
  });

  final ChatRoom room;
  final ChatRepository chatRepository;
  final int currentMemberId;

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _loadingOlder = false;
  bool _hasMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final page = await widget.chatRepository.getMessages(widget.room.roomId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(page.content);
        _hasMore = page.hasMore;
        _loading = false;
      });
      _scrollToLatest();
      final latestSequence = page.latestSequence;
      if (latestSequence != null) unawaited(_markRead(latestSequence));
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            error is ApiException ? error.message : '이전 메시지를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasMore || _messages.isEmpty) return;
    setState(() => _loadingOlder = true);
    try {
      final page = await widget.chatRepository.getMessages(
        widget.room.roomId,
        beforeSequence: _messages.first.sequence,
      );
      if (!mounted) return;
      final existingIds = _messages.map((message) => message.id).toSet();
      setState(() {
        _messages.insertAll(
          0,
          page.content.where((message) => !existingIds.contains(message.id)),
        );
        _hasMore = page.hasMore;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      final message =
          error is ApiException ? error.message : '이전 메시지를 더 불러오지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _markRead(int latestSequence) async {
    try {
      await widget.chatRepository.markRead(widget.room.roomId, latestSequence);
    } on Exception {
      // 읽음 처리 실패가 저장된 메시지 조회를 막지는 않는다.
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(title: widget.room.meetingTitle),
            Expanded(child: _buildBody()),
            _ReadOnlyComposer(canSend: widget.room.canSend),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingView(
        message: '이전 메시지를 불러오는 중입니다.',
        height: double.infinity,
      );
    }
    if (_errorMessage case final message?) {
      return AppErrorView(
        message: message,
        height: double.infinity,
        onRetry: _loadInitial,
      );
    }
    if (_messages.isEmpty) {
      return const AppEmptyView(
        message: '아직 주고받은 메시지가 없습니다.',
        height: double.infinity,
      );
    }

    return ListView.builder(
      key: const Key('chat-message-list'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          if (!_hasMore) return const SizedBox(height: 8);
          return Center(
            child: TextButton.icon(
              key: const Key('load-older-chat-messages'),
              onPressed: _loadingOlder ? null : _loadOlder,
              icon: _loadingOlder
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.history_rounded, size: 18),
              label: const Text('이전 메시지 더 보기'),
            ),
          );
        }
        final message = _messages[index - 1];
        return _MessageBubble(
          message: message,
          isMine: message.senderId == widget.currentMemberId,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 5),
                child: Text(
                  message.senderNickname,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isMine) ...[
                  _MessageTime(dateTime: message.createdAt),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isMine ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                      border: isMine ? null : Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isMine ? Colors.white : AppColors.ink,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (!isMine) ...[
                  const SizedBox(width: 6),
                  _MessageTime(dateTime: message.createdAt),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTime extends StatelessWidget {
  const _MessageTime({required this.dateTime});

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return Text(
      '$hour:$minute',
      style: const TextStyle(
        color: AppColors.subtle,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReadOnlyComposer extends StatelessWidget {
  const _ReadOnlyComposer({required this.canSend});

  final bool canSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.softSurface,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Text(
          canSend ? '실시간 연결 후 메시지를 보낼 수 있어요.' : '종료된 모임에서는 메시지를 보낼 수 없어요.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
