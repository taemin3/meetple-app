import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/realtime/chat_client_message_id.dart';
import '../../data/realtime/chat_realtime_client.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_state_view.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.room,
    required this.chatRepository,
    required this.chatRealtimeClient,
    required this.currentMemberId,
    this.onReadStarted,
  });

  final ChatRoom room;
  final ChatRepository chatRepository;
  final ChatRealtimeClient chatRealtimeClient;
  final int currentMemberId;
  final ValueChanged<Future<void>>? onReadStarted;

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final ChatClientMessageIdGenerator _messageIdGenerator =
      ChatClientMessageIdGenerator();
  final List<ChatMessage> _messages = [];
  final List<StreamSubscription<dynamic>> _realtimeSubscriptions = [];
  ChatRealtimeSession? _realtimeSession;
  ChatRealtimeConnectionState _connectionState =
      ChatRealtimeConnectionState.connecting;
  bool _loading = true;
  bool _loadingOlder = false;
  bool _hasMore = false;
  bool _hasNewMessagesBelow = false;
  bool _disposing = false;
  int? _pendingReadSequence;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _scrollController.addListener(_onScrollChanged);
    _messageController.addListener(_onDraftChanged);
    unawaited(_loadInitial());
    unawaited(_connectRealtime());
  }

  @override
  void dispose() {
    _disposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScrollChanged);
    _messageController
      ..removeListener(_onDraftChanged)
      ..dispose();
    unawaited(_closeRealtime());
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _flushPendingRead();
      });
    }
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  void _onScrollChanged() {
    if (_hasNewMessagesBelow && _isNearLatest && mounted) {
      setState(() => _hasNewMessagesBelow = false);
    }
  }

  Future<void> _connectRealtime() async {
    if (_disposing) return;
    if (mounted) {
      setState(() => _connectionState = ChatRealtimeConnectionState.connecting);
    }
    await _closeRealtime();
    if (!mounted || _disposing) return;

    final session = widget.chatRealtimeClient.openRoom(
      roomId: widget.room.roomId,
      currentMemberId: widget.currentMemberId,
    );
    _realtimeSession = session;
    _realtimeSubscriptions.addAll([
      session.connectionStates.listen(_onConnectionStateChanged),
      session.messages.listen(_onRealtimeMessage),
      session.errors.listen(_onRealtimeError),
    ]);
    session.activate();
  }

  Future<void> _closeRealtime() async {
    final subscriptions = List<StreamSubscription<dynamic>>.of(
      _realtimeSubscriptions,
    );
    _realtimeSubscriptions.clear();
    final session = _realtimeSession;
    _realtimeSession = null;
    await Future.wait([
      ...subscriptions.map((subscription) => subscription.cancel()),
      if (session != null) session.close(),
    ]);
  }

  void _onConnectionStateChanged(ChatRealtimeConnectionState state) {
    if (!mounted || _disposing) return;
    setState(() => _connectionState = state);
  }

  void _onRealtimeMessage(ChatMessage message) {
    if (!mounted || _disposing || message.roomId != widget.room.roomId) return;
    final isDuplicate = _messages.any(
      (existing) =>
          existing.id == message.id ||
          existing.clientMessageId == message.clientMessageId,
    );
    if (isDuplicate) return;

    final isMine = message.senderId == widget.currentMemberId;
    final shouldScrollToLatest = isMine || _isNearLatest;
    setState(() {
      _messages.add(message);
      _messages.sort((left, right) => left.sequence.compareTo(right.sequence));
      _errorMessage = null;
      _hasNewMessagesBelow = !shouldScrollToLatest;
    });
    if (shouldScrollToLatest) _scrollToLatest();
    _queueRead(message.sequence);
  }

  void _onRealtimeError(ChatRealtimeException error) {
    if (!mounted || _disposing) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (!_canSubmit || content.isEmpty) return;

    try {
      _realtimeSession!.send(
        clientMessageId: _messageIdGenerator.generate(),
        content: content,
      );
      _messageController.clear();
    } on ChatRealtimeException catch (error) {
      _onRealtimeError(error);
    } on Exception {
      _onRealtimeError(
        const ChatRealtimeException('메시지를 전송하지 못했습니다.'),
      );
    }
  }

  bool get _canSubmit =>
      widget.room.canSend &&
      _connectionState == ChatRealtimeConnectionState.connected &&
      _messageController.text.trim().isNotEmpty;

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final page = await widget.chatRepository.getMessages(widget.room.roomId);
      if (!mounted) return;
      setState(() {
        final realtimeMessages = List<ChatMessage>.of(_messages);
        _messages
          ..clear()
          ..addAll(page.content);
        for (final message in realtimeMessages) {
          final isDuplicate = _messages.any(
            (existing) =>
                existing.id == message.id ||
                existing.clientMessageId == message.clientMessageId,
          );
          if (!isDuplicate) _messages.add(message);
        }
        _messages
            .sort((left, right) => left.sequence.compareTo(right.sequence));
        _hasMore = page.hasMore;
        _loading = false;
      });
      _scrollToLatest();
      final latestSequence = page.latestSequence;
      if (latestSequence != null) {
        _queueRead(latestSequence);
      }
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _messages.isEmpty
            ? error is ApiException
                ? error.message
                : '이전 메시지를 불러오지 못했습니다.'
            : null;
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

  void _queueRead(int latestSequence) {
    final pending = _pendingReadSequence;
    if (pending == null || latestSequence > pending) {
      _pendingReadSequence = latestSequence;
    }
    _flushPendingRead();
  }

  void _flushPendingRead() {
    final latestSequence = _pendingReadSequence;
    if (latestSequence == null || !_isRouteVisible) return;
    _pendingReadSequence = null;
    final completion = _markRead(latestSequence);
    widget.onReadStarted?.call(completion);
    unawaited(completion);
  }

  bool get _isRouteVisible =>
      mounted &&
      _appLifecycleState == AppLifecycleState.resumed &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  bool get _isNearLatest {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= 120;
  }

  void _scrollToLatest() {
    if (_hasNewMessagesBelow && mounted) {
      setState(() => _hasNewMessagesBelow = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
      WidgetsBinding.instance.scheduleFrame();
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
            _ChatComposer(
              controller: _messageController,
              canSend: widget.room.canSend,
              connectionState: _connectionState,
              canSubmit: _canSubmit,
              onSend: _sendMessage,
              onReconnect: _connectRealtime,
            ),
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

    return Stack(
      children: [
        ListView.builder(
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
        ),
        if (_hasNewMessagesBelow)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: FilledButton.icon(
                key: const Key('jump-to-latest-chat-message'),
                onPressed: _scrollToLatest,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.arrow_downward_rounded, size: 15),
                label: const Text('새 메시지'),
              ),
            ),
          ),
      ],
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

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.canSend,
    required this.connectionState,
    required this.canSubmit,
    required this.onSend,
    required this.onReconnect,
  });

  final TextEditingController controller;
  final bool canSend;
  final ChatRealtimeConnectionState connectionState;
  final bool canSubmit;
  final VoidCallback onSend;
  final Future<void> Function() onReconnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: canSend
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (connectionState != ChatRealtimeConnectionState.connected)
                  _ConnectionNotice(
                    state: connectionState,
                    onReconnect: onReconnect,
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('chat-message-input'),
                        controller: controller,
                        enabled: connectionState ==
                            ChatRealtimeConnectionState.connected,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1000),
                        ],
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력하세요',
                          filled: true,
                          fillColor: AppColors.softSurface,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(18)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('send-chat-message'),
                      tooltip: '메시지 전송',
                      onPressed: canSubmit ? onSend : null,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.softSurface,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: AppColors.subtle,
                      ),
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.softSurface,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Text(
                '종료된 모임에서는 메시지를 보낼 수 없어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _ConnectionNotice extends StatelessWidget {
  const _ConnectionNotice({
    required this.state,
    required this.onReconnect,
  });

  final ChatRealtimeConnectionState state;
  final Future<void> Function() onReconnect;

  @override
  Widget build(BuildContext context) {
    final isConnecting = state == ChatRealtimeConnectionState.connecting;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isConnecting)
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.muted,
              size: 17,
            ),
          const SizedBox(width: 7),
          Text(
            isConnecting ? '실시간 채팅에 연결하는 중입니다.' : '실시간 연결이 끊어졌습니다.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!isConnecting)
            TextButton(
              key: const Key('reconnect-chat'),
              onPressed: onReconnect,
              child: const Text('다시 연결'),
            ),
        ],
      ),
    );
  }
}
