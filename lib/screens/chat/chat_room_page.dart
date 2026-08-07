import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_route_observer.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/realtime/chat_client_message_id.dart';
import '../../data/realtime/chat_realtime_client.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../widgets/app_page_header.dart';
import '../../widgets/app_state_view.dart';
import '../../widgets/network_image_with_skeleton.dart';

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
    with WidgetsBindingObserver, RouteAware {
  static const List<Duration> _reconnectDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
  ];
  static const List<Duration> _recoveryRetryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final ChatClientMessageIdGenerator _messageIdGenerator =
      ChatClientMessageIdGenerator();
  final List<ChatMessage> _messages = [];
  final List<StreamSubscription<dynamic>> _realtimeSubscriptions = [];
  late final Future<void> _initialLoadFuture;
  ChatRealtimeSession? _realtimeSession;
  ModalRoute<dynamic>? _subscribedRoute;
  ChatRealtimeConnectionState _connectionState =
      ChatRealtimeConnectionState.connecting;
  bool _loading = true;
  bool _loadingOlder = false;
  bool _hasMore = false;
  bool _showJumpToLatest = false;
  bool _disposing = false;
  int? _pendingReadSequence;
  String? _pendingClientMessageId;
  String? _pendingMessageContent;
  bool _awaitingSendConfirmation = false;
  bool _initialHistoryLoaded = false;
  bool _accessRevoked = false;
  String? _accessRevokedMessage;
  int _historySyncSequence = 0;
  bool _recoveryInProgress = false;
  int _recoveryRetryAttempt = 0;
  int _reconnectAttempt = 0;
  Timer? _recoveryRetryTimer;
  Timer? _reconnectTimer;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  String? _historyErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _scrollController.addListener(_onScrollChanged);
    _messageController.addListener(_onDraftChanged);
    _initialLoadFuture = _loadInitial();
    unawaited(_initialLoadFuture);
    unawaited(_connectRealtime());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == _subscribedRoute) return;
    final previousRoute = _subscribedRoute;
    if (previousRoute != null) appRouteObserver.unsubscribe(this);
    _subscribedRoute = route;
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    _disposing = true;
    _reconnectTimer?.cancel();
    _recoveryRetryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _scrollController.removeListener(_onScrollChanged);
    _messageController
      ..removeListener(_onDraftChanged)
      ..dispose();
    unawaited(_closeRealtime());
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _flushPendingRead();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _flushPendingRead();
        if (!_accessRevoked &&
            _connectionState == ChatRealtimeConnectionState.disconnected) {
          _scheduleReconnect(immediate: true);
        }
      });
    } else {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
    }
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  void _onScrollChanged() {
    final shouldShowJumpButton = !_isNearLatest;
    if (_showJumpToLatest != shouldShowJumpButton && mounted) {
      setState(() => _showJumpToLatest = shouldShowJumpButton);
    }
    if (!shouldShowJumpButton) _flushPendingRead();
  }

  Future<void> _connectRealtime() async {
    if (_disposing || _accessRevoked) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
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
      session.connectionStates.listen(
        (state) => _onConnectionStateChanged(session, state),
      ),
      session.messages.listen(_onRealtimeMessage),
      session.errors.listen(_onRealtimeError),
    ]);
    session.activate();
  }

  Future<void> _closeRealtime() {
    final subscriptions = List<StreamSubscription<dynamic>>.of(
      _realtimeSubscriptions,
    );
    _realtimeSubscriptions.clear();
    final session = _realtimeSession;
    _realtimeSession = null;
    if (session != null) {
      unawaited(_completeRealtimeCleanup(session.close()));
    }
    for (final subscription in subscriptions) {
      unawaited(_completeRealtimeCleanup(subscription.cancel()));
    }
    return Future<void>.value();
  }

  Future<void> _completeRealtimeCleanup(Future<void> cleanup) async {
    try {
      await cleanup;
    } on Exception {
      // 이전 연결 정리 실패가 새 연결 시도를 막지 않게 한다.
    }
  }

  void _onConnectionStateChanged(
    ChatRealtimeSession session,
    ChatRealtimeConnectionState state,
  ) {
    if (!mounted || _disposing || session != _realtimeSession) return;
    setState(() {
      _connectionState = state;
      if (state == ChatRealtimeConnectionState.disconnected) {
        _awaitingSendConfirmation = false;
      }
    });
    if (state == ChatRealtimeConnectionState.connected) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _reconnectAttempt = 0;
      unawaited(
        _scheduleMissedMessageRecovery(session, resetRetryAttempt: true),
      );
    } else if (state == ChatRealtimeConnectionState.disconnected) {
      _recoveryRetryTimer?.cancel();
      _recoveryRetryTimer = null;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect({bool immediate = false}) {
    if (_disposing ||
        _accessRevoked ||
        _reconnectTimer?.isActive == true ||
        _appLifecycleState != AppLifecycleState.resumed ||
        _reconnectAttempt >= _reconnectDelays.length) {
      return;
    }

    final delay =
        immediate ? Duration.zero : _reconnectDelays[_reconnectAttempt];
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!mounted ||
          _disposing ||
          _appLifecycleState != AppLifecycleState.resumed ||
          _connectionState != ChatRealtimeConnectionState.disconnected) {
        return;
      }
      _reconnectAttempt += 1;
      unawaited(_connectRealtime());
    });
  }

  Future<void> _retryRealtime() async {
    if (_accessRevoked) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    await _connectRealtime();
  }

  Future<void> _scheduleMissedMessageRecovery(
    ChatRealtimeSession session, {
    bool resetRetryAttempt = false,
  }) async {
    if (resetRetryAttempt) {
      _recoveryRetryTimer?.cancel();
      _recoveryRetryTimer = null;
      _recoveryRetryAttempt = 0;
    }
    if (_recoveryInProgress || _recoveryRetryTimer?.isActive == true) return;

    _recoveryInProgress = true;
    try {
      await _initialLoadFuture;
      if (!_isRecoverySessionActive(session) || !_initialHistoryLoaded) {
        return;
      }

      final recovered = await _recoverMissedMessages(
        session,
        showError: _recoveryRetryAttempt == 0,
      );
      if (!_isRecoverySessionActive(session) || recovered == null) return;

      _advanceHistorySyncSequenceThroughLoadedMessages();
      if (!recovered || _hasSequenceGap) {
        _scheduleRecoveryRetry(session);
      } else {
        _recoveryRetryAttempt = 0;
      }
    } finally {
      _recoveryInProgress = false;
      final currentSession = _realtimeSession;
      if (currentSession != null &&
          currentSession != session &&
          _isRecoverySessionActive(currentSession)) {
        unawaited(
          _scheduleMissedMessageRecovery(
            currentSession,
            resetRetryAttempt: true,
          ),
        );
      }
    }
  }

  Future<bool?> _recoverMissedMessages(
    ChatRealtimeSession session, {
    required bool showError,
  }) async {
    var afterSequence = _historySyncSequence;
    final recoveredMessages = <ChatMessage>[];

    try {
      while (true) {
        final page = await widget.chatRepository.getMessages(
          widget.room.roomId,
          afterSequence: afterSequence,
          size: 100,
        );
        if (!_isRecoverySessionActive(session)) {
          return null;
        }
        if (page.content.isEmpty) break;

        recoveredMessages.addAll(page.content);
        final nextSequence = page.content
            .map((message) => message.sequence)
            .reduce((left, right) => left > right ? left : right);
        if (nextSequence <= afterSequence) break;
        afterSequence = nextSequence;
        if (!page.hasMore) break;
      }

      recoveredMessages.sort(
        (left, right) => left.sequence.compareTo(right.sequence),
      );
      for (final message in recoveredMessages) {
        _onRealtimeMessage(message, recoverSequenceGap: false);
      }
      if (afterSequence > _historySyncSequence) {
        _historySyncSequence = afterSequence;
      }
      _advanceHistorySyncSequenceThroughLoadedMessages();
      return true;
    } on Exception catch (error) {
      if (!mounted || !_isRecoverySessionActive(session)) return null;
      if (!showError) return false;
      final message =
          error is ApiException ? error.message : '누락된 메시지를 불러오지 못했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return false;
    }
  }

  void _scheduleRecoveryRetry(ChatRealtimeSession session) {
    if (!_isRecoverySessionActive(session) ||
        _recoveryRetryTimer?.isActive == true) {
      return;
    }

    final delay = _recoveryRetryDelays[_recoveryRetryAttempt];
    if (_recoveryRetryAttempt < _recoveryRetryDelays.length - 1) {
      _recoveryRetryAttempt += 1;
    }
    _recoveryRetryTimer = Timer(delay, () {
      _recoveryRetryTimer = null;
      if (_isRecoverySessionActive(session)) {
        unawaited(_scheduleMissedMessageRecovery(session));
      }
    });
  }

  bool _isRecoverySessionActive(ChatRealtimeSession session) =>
      mounted &&
      !_disposing &&
      !_accessRevoked &&
      session == _realtimeSession &&
      session.isConnected;

  bool get _hasSequenceGap =>
      _messages.any((message) => message.sequence > _historySyncSequence);

  void _onRealtimeMessage(
    ChatMessage message, {
    bool recoverSequenceGap = true,
  }) {
    if (!mounted || _disposing || message.roomId != widget.room.roomId) return;
    final isDuplicate = _messages.any(
      (existing) =>
          existing.id == message.id ||
          existing.clientMessageId == message.clientMessageId,
    );
    final confirmsPendingSend =
        message.clientMessageId == _pendingClientMessageId;
    final shouldClearDraft = confirmsPendingSend &&
        _messageController.text == _pendingMessageContent;

    final isMine = message.senderId == widget.currentMemberId;
    final shouldScrollToLatest = isMine || _isNearLatest;
    setState(() {
      if (confirmsPendingSend) {
        _pendingClientMessageId = null;
        _pendingMessageContent = null;
        _awaitingSendConfirmation = false;
      }
      if (!isDuplicate) {
        _messages.add(message);
        _messages.sort(
          (left, right) => left.sequence.compareTo(right.sequence),
        );
        _showJumpToLatest = !shouldScrollToLatest;
      }
    });
    if (recoverSequenceGap) {
      _recoverSequenceGapIfNeeded(message.sequence);
    }
    if (shouldClearDraft) _messageController.clear();
    if (isDuplicate) return;
    if (shouldScrollToLatest) _scrollToLatest();
    _queueRead(message.sequence);
  }

  void _recoverSequenceGapIfNeeded(int receivedSequence) {
    if (!_initialHistoryLoaded || receivedSequence <= _historySyncSequence) {
      return;
    }

    _advanceHistorySyncSequenceThroughLoadedMessages();
    if (receivedSequence <= _historySyncSequence) return;

    final session = _realtimeSession;
    if (session != null && session.isConnected) {
      unawaited(_scheduleMissedMessageRecovery(session));
    }
  }

  void _advanceHistorySyncSequenceThroughLoadedMessages() {
    final loadedSequences =
        _messages.map((message) => message.sequence).toSet();
    while (loadedSequences.contains(_historySyncSequence + 1)) {
      _historySyncSequence += 1;
    }
  }

  void _onRealtimeError(ChatRealtimeException error) {
    if (!mounted || _disposing) return;
    if (error.isAccessRevoked) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _recoveryRetryTimer?.cancel();
      _recoveryRetryTimer = null;
      setState(() {
        _accessRevoked = true;
        _accessRevokedMessage = error.message;
        _awaitingSendConfirmation = false;
        _connectionState = ChatRealtimeConnectionState.disconnected;
      });
      scheduleMicrotask(() => unawaited(_closeRealtime()));
      return;
    }
    if (_awaitingSendConfirmation) {
      setState(() => _awaitingSendConfirmation = false);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }

  void _sendMessage() {
    final content = _messageController.text;
    if (!_canSubmit) return;
    final clientMessageId =
        _pendingMessageContent == content && _pendingClientMessageId != null
            ? _pendingClientMessageId!
            : _messageIdGenerator.generate();

    try {
      setState(() {
        _pendingClientMessageId = clientMessageId;
        _pendingMessageContent = content;
        _awaitingSendConfirmation = true;
      });
      _realtimeSession!.send(
        clientMessageId: clientMessageId,
        content: content,
      );
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
      !_awaitingSendConfirmation &&
      _messageController.text.trim().isNotEmpty;

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _historyErrorMessage = null;
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
        _initialHistoryLoaded = true;
        _historySyncSequence = page.latestSequence ?? 0;
        _advanceHistorySyncSequenceThroughLoadedMessages();
      });
      _scrollToLatest();
      final latestSequence = page.latestSequence;
      if (latestSequence != null) {
        _queueRead(latestSequence);
      }
      final session = _realtimeSession;
      if (session != null && session.isConnected) {
        unawaited(_scheduleMissedMessageRecovery(session));
      }
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _historyErrorMessage =
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

  void _queueRead(int latestSequence) {
    final pending = _pendingReadSequence;
    if (pending == null || latestSequence > pending) {
      _pendingReadSequence = latestSequence;
    }
    _flushPendingRead();
  }

  void _flushPendingRead() {
    final latestSequence = _pendingReadSequence;
    if (latestSequence == null || !_isRouteVisible || !_isNearLatest) return;
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
    if (_showJumpToLatest && mounted) {
      setState(() => _showJumpToLatest = false);
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
              onReconnect: _retryRealtime,
              accessRevokedMessage: _accessRevokedMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _messages.isEmpty) {
      return const AppLoadingView(
        message: '이전 메시지를 불러오는 중입니다.',
        height: double.infinity,
      );
    }
    if (_historyErrorMessage case final message? when _messages.isEmpty) {
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
              return _buildHistoryHeader();
            }
            final messageIndex = index - 1;
            final message = _messages[messageIndex];
            final showDateSeparator = messageIndex == 0 ||
                !_isSameCalendarDay(
                  _messages[messageIndex - 1].createdAt,
                  message.createdAt,
                );
            final showTime = messageIndex == _messages.length - 1 ||
                !_isSameMessageGroup(
                  message,
                  _messages[messageIndex + 1],
                );
            final showSender = messageIndex == 0 ||
                !_isSameMessageGroup(
                  _messages[messageIndex - 1],
                  message,
                );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showDateSeparator)
                  _ChatDateSeparator(dateTime: message.createdAt),
                _MessageBubble(
                  message: message,
                  isMine: message.senderId == widget.currentMemberId,
                  showSender: showSender,
                  showTime: showTime,
                ),
              ],
            );
          },
        ),
        if (_showJumpToLatest)
          Positioned(
            right: 16,
            bottom: 12,
            child: IconButton.filled(
              key: const Key('jump-to-latest-chat-message'),
              tooltip: '최신 메시지로 이동',
              onPressed: _scrollToLatest,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.square(42),
                padding: const EdgeInsets.all(9),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.arrow_downward_rounded, size: 22),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryHeader() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_historyErrorMessage case final message?) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              key: const Key('retry-chat-history'),
              onPressed: _loadInitial,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
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
}

class _ChatDateSeparator extends StatelessWidget {
  const _ChatDateSeparator({required this.dateTime});

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatChatDate(dateTime),
              style: const TextStyle(
                color: AppColors.subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.line)),
        ],
      ),
    );
  }
}

String _formatChatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final today = DateTime.now();
  if (_isSameCalendarDay(local, today)) return '오늘';
  return '${local.year}년 ${local.month}월 ${local.day}일';
}

bool _isSameCalendarDay(DateTime left, DateTime right) {
  final localLeft = left.toLocal();
  final localRight = right.toLocal();
  return localLeft.year == localRight.year &&
      localLeft.month == localRight.month &&
      localLeft.day == localRight.day;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showSender,
    required this.showTime,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showSender;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isMine && showSender)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 5),
            child: Text(
              key: Key('chat-message-sender-${message.id}'),
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
            if (isMine && showTime) ...[
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
            if (!isMine && showTime) ...[
              const SizedBox(width: 6),
              _MessageTime(dateTime: message.createdAt),
            ],
          ],
        ),
      ],
    );

    final bottomPadding = EdgeInsets.only(bottom: showTime ? 12 : 4);
    if (isMine) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(padding: bottomPadding, child: content),
      );
    }

    return Padding(
      padding: bottomPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSender)
            _ChatSenderAvatar(message: message)
          else
            const SizedBox(width: 36),
          const SizedBox(width: 8),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _ChatSenderAvatar extends StatelessWidget {
  const _ChatSenderAvatar({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      key: Key('chat-message-avatar-fallback-${message.id}'),
      color: AppColors.softSurface,
      alignment: Alignment.center,
      child: Text(
        message.senderNickname.isEmpty
            ? 'M'
            : message.senderNickname.characters.first,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final imageUrl = message.senderProfileImageUrl;

    return ClipOval(
      key: Key('chat-message-avatar-${message.id}'),
      child: SizedBox.square(
        dimension: 36,
        child: imageUrl == null || imageUrl.trim().isEmpty
            ? fallback
            : NetworkImageWithSkeleton(
                key: Key('chat-message-avatar-image-${message.id}'),
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                cacheWidth: 72,
                cacheHeight: 72,
                skeleton: fallback,
                errorWidget: fallback,
              ),
      ),
    );
  }
}

bool _isSameMessageGroup(ChatMessage current, ChatMessage next) {
  if (current.senderId != next.senderId) return false;
  final currentTime = current.createdAt.toLocal();
  final nextTime = next.createdAt.toLocal();
  return currentTime.year == nextTime.year &&
      currentTime.month == nextTime.month &&
      currentTime.day == nextTime.day &&
      currentTime.hour == nextTime.hour &&
      currentTime.minute == nextTime.minute;
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
    required this.accessRevokedMessage,
  });

  final TextEditingController controller;
  final bool canSend;
  final ChatRealtimeConnectionState connectionState;
  final bool canSubmit;
  final VoidCallback onSend;
  final Future<void> Function() onReconnect;
  final String? accessRevokedMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: accessRevokedMessage != null
          ? _AccessRevokedNotice(message: accessRevokedMessage!)
          : canSend
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (connectionState !=
                        ChatRealtimeConnectionState.connected)
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
                                    ChatRealtimeConnectionState.connected &&
                                accessRevokedMessage == null,
                            keyboardType: TextInputType.multiline,
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
                                borderRadius:
                                    BorderRadius.all(Radius.circular(18)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _AccessRevokedNotice extends StatelessWidget {
  const _AccessRevokedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chat-access-revoked-notice'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.softSurface,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.muted, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
