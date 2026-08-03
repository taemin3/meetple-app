import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../core/network/api_client.dart';
import '../../models/chat_message.dart';
import 'chat_realtime_client.dart';

class StompChatRealtimeClient implements ChatRealtimeClient {
  const StompChatRealtimeClient({
    required this.baseUrl,
    required this.accessTokenProvider,
  });

  final String baseUrl;
  final AccessTokenProvider accessTokenProvider;

  @override
  ChatRealtimeSession openRoom({
    required int roomId,
    required int currentMemberId,
  }) {
    return _StompChatRealtimeSession(
      roomId: roomId,
      webSocketUrl: chatWebSocketUrl(baseUrl),
      accessTokenProvider: accessTokenProvider,
    );
  }
}

String chatWebSocketUrl(String baseUrl) {
  final baseUri = Uri.parse(baseUrl);
  final scheme = switch (baseUri.scheme) {
    'http' => 'ws',
    'https' => 'wss',
    'ws' || 'wss' => baseUri.scheme,
    _ => throw ArgumentError.value(baseUrl, 'baseUrl', '지원하지 않는 URL입니다.'),
  };
  final normalizedPath = baseUri.path.endsWith('/')
      ? baseUri.path.substring(0, baseUri.path.length - 1)
      : baseUri.path;

  return baseUri.replace(scheme: scheme, path: '$normalizedPath/ws').toString();
}

ChatMessage parseStompChatMessage(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const FormatException('STOMP 응답이 JSON 객체가 아닙니다.');
  }
  final response = decoded.map((key, value) => MapEntry(key.toString(), value));
  if (response['success'] != true) {
    throw ChatRealtimeException(
      _readString(response['message'], fallback: '메시지를 수신하지 못했습니다.'),
    );
  }
  final rawData = response['data'];
  if (rawData is! Map) {
    throw const FormatException('STOMP 응답에 메시지 데이터가 없습니다.');
  }
  final data = rawData.map((key, value) => MapEntry(key.toString(), value));

  return ChatMessage(
    id: _readInt(data['id']),
    roomId: _readInt(data['roomId']),
    sequence: _readInt(data['sequence']),
    clientMessageId: _readString(data['clientMessageId']),
    senderId: _readInt(data['senderId']),
    senderNickname: _readString(
      data['senderNickname'],
      fallback: '알 수 없는 사용자',
    ),
    senderProfileImageUrl: _readNullableString(data['senderProfileImageUrl']),
    content: _readString(data['content']),
    createdAt: _readDateTime(data['createdAt']),
  );
}

class _StompChatRealtimeSession implements ChatRealtimeSession {
  _StompChatRealtimeSession({
    required this.roomId,
    required this.webSocketUrl,
    required this.accessTokenProvider,
  });

  final int roomId;
  final String webSocketUrl;
  final AccessTokenProvider accessTokenProvider;
  final StreamController<ChatRealtimeConnectionState> _stateController =
      StreamController<ChatRealtimeConnectionState>.broadcast();
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<ChatRealtimeException> _errorController =
      StreamController<ChatRealtimeException>.broadcast();

  StompClient? _client;
  StompUnsubscribe? _unsubscribeRoom;
  StompUnsubscribe? _unsubscribeErrors;
  bool _activating = false;
  bool _connected = false;
  bool _closed = false;

  @override
  Stream<ChatRealtimeConnectionState> get connectionStates =>
      _stateController.stream;

  @override
  Stream<ChatMessage> get messages => _messageController.stream;

  @override
  Stream<ChatRealtimeException> get errors => _errorController.stream;

  @override
  bool get isConnected => _connected && !_closed;

  @override
  void activate() {
    if (_activating || _connected || _closed) return;
    _activating = true;
    _emitState(ChatRealtimeConnectionState.connecting);
    unawaited(_activateWithToken());
  }

  Future<void> _activateWithToken() async {
    try {
      final token = await accessTokenProvider.call();
      if (_closed) return;
      if (token == null || token.trim().isEmpty) {
        _activating = false;
        _emitError('로그인 정보가 없어 실시간 채팅에 연결하지 못했습니다.');
        _emitState(ChatRealtimeConnectionState.disconnected);
        return;
      }

      final client = StompClient(
        config: StompConfig(
          url: webSocketUrl,
          reconnectDelay: Duration.zero,
          heartbeatIncoming: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 10),
          connectionTimeout: const Duration(seconds: 10),
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          onConnect: _onConnect,
          onDisconnect: (_) => _handleDisconnected(),
          onStompError: _onStompError,
          onWebSocketError: (_) {
            _handleTransportError('실시간 채팅 연결에 실패했습니다.');
          },
          onWebSocketDone: _handleDisconnected,
        ),
      );
      _client = client;
      client.activate();
    } on Exception {
      _activating = false;
      _emitError('실시간 채팅 연결에 실패했습니다.');
      _emitState(ChatRealtimeConnectionState.disconnected);
    }
  }

  void _onConnect(StompFrame frame) {
    if (_closed) return;
    final client = _client;
    if (client == null) return;

    try {
      _unsubscribeRoom = client.subscribe(
        destination: '/topic/chat/rooms/$roomId',
        callback: _onRoomMessage,
      );
      _unsubscribeErrors = client.subscribe(
        destination: '/user/queue/chat/errors',
        callback: _onUserError,
      );
      _activating = false;
      _connected = true;
      _emitState(ChatRealtimeConnectionState.connected);
    } on Exception {
      _handleTransportError('채팅방 구독에 실패했습니다.');
    }
  }

  void _onRoomMessage(StompFrame frame) {
    if (_closed) return;
    final body = frame.body;
    if (body == null || body.isEmpty) {
      _emitError('빈 채팅 메시지를 수신했습니다.');
      return;
    }

    try {
      final message = parseStompChatMessage(body);
      if (message.roomId == roomId) {
        _messageController.add(message);
      }
    } on ChatRealtimeException catch (error) {
      _errorController.add(error);
    } on FormatException {
      _emitError('채팅 메시지 형식을 확인할 수 없습니다.');
    }
  }

  void _onUserError(StompFrame frame) {
    if (_closed) return;
    _emitError(_errorMessageFrom(frame.body));
  }

  void _onStompError(StompFrame frame) {
    if (_closed) return;
    final headerMessage = frame.headers['message'];
    _emitError(
      _errorMessageFrom(
        frame.body,
        fallback: headerMessage ?? '실시간 채팅 처리 중 오류가 발생했습니다.',
      ),
    );
    _handleDisconnected();
  }

  void _handleTransportError(String message) {
    if (_closed) return;
    _emitError(message);
    _handleDisconnected();
  }

  void _handleDisconnected() {
    if (_closed) return;
    _activating = false;
    _connected = false;
    _emitState(ChatRealtimeConnectionState.disconnected);
  }

  @override
  void send({
    required String clientMessageId,
    required String content,
  }) {
    final client = _client;
    if (!isConnected || client == null) {
      throw const ChatRealtimeException('실시간 채팅에 연결되어 있지 않습니다.');
    }

    client.send(
      destination: '/app/chat/rooms/$roomId/messages',
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'clientMessageId': clientMessageId,
        'content': content,
      }),
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _activating = false;
    _connected = false;
    _unsubscribeRoom?.call();
    _unsubscribeErrors?.call();
    _client?.deactivate();
    await Future.wait([
      _stateController.close(),
      _messageController.close(),
      _errorController.close(),
    ]);
  }

  void _emitState(ChatRealtimeConnectionState state) {
    if (!_closed && !_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void _emitError(String message) {
    if (!_closed && !_errorController.isClosed) {
      _errorController.add(ChatRealtimeException(message));
    }
  }
}

String _errorMessageFrom(String? body, {String? fallback}) {
  if (body != null && body.isNotEmpty) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } on FormatException {
      // JSON 오류 응답이 아니면 아래의 안전한 문구를 사용한다.
    }
  }
  return fallback ?? '메시지 전송 중 오류가 발생했습니다.';
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}

String? _readNullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return null;
}

DateTime _readDateTime(Object? value) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw const FormatException('올바른 메시지 시간이 아닙니다.');
}
