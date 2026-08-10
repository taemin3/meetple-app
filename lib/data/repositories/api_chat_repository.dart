import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import 'chat_repository.dart';

class ApiChatRepository
    implements ChatRepository, ChatNotificationSettingsRepository {
  ApiChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  ApiChatRepository.withBaseUrl({
    String baseUrl = AppConfig.apiBaseUrl,
    AccessTokenProvider? accessTokenProvider,
    UnauthorizedTokenRefresher? unauthorizedTokenRefresher,
  }) : this(
          apiClient: HttpApiClient(
            baseUri: Uri.parse(baseUrl),
            accessTokenProvider: accessTokenProvider,
            unauthorizedTokenRefresher: unauthorizedTokenRefresher,
          ),
        );

  final ApiClient _apiClient;

  @override
  Future<ChatRoomListPage> getRooms({int page = 0, int size = 20}) async {
    final response = await _apiClient.getJson(
      '/api/v1/chat/rooms',
      queryParameters: {'page': '$page', 'size': '$size'},
    );
    final data = _readData(response);
    final content = _readList(data['content'], 'data.content');

    return ChatRoomListPage(
      content: [
        for (final item in content)
          _roomFromJson(_readMap(item, 'data.content[]')),
      ],
      page: _readInt(data['page']),
      size: _readInt(data['size'], fallback: size),
      totalElements: _readInt(data['totalElements']),
      totalPages: _readInt(data['totalPages']),
      isFirst: data['first'] == true,
      isLast: data['last'] == true,
    );
  }

  @override
  Future<ChatRoom> getRoom(int roomId) async {
    final response = await _apiClient.getJson('/api/v1/chat/rooms/$roomId');
    return _roomFromJson(_readData(response));
  }

  @override
  Future<ChatMessagePage> getMessages(
    int roomId, {
    int? beforeSequence,
    int? afterSequence,
    int size = 50,
  }) async {
    final response = await _apiClient.getJson(
      '/api/v1/chat/rooms/$roomId/messages',
      queryParameters: {
        if (beforeSequence != null) 'beforeSequence': '$beforeSequence',
        if (afterSequence != null) 'afterSequence': '$afterSequence',
        'size': '$size',
      },
    );
    final data = _readData(response);

    return ChatMessagePage(
      content: [
        for (final item in _readList(data['content'], 'data.content'))
          _messageFromJson(_readMap(item, 'data.content[]')),
      ],
      hasMore: data['hasMore'] == true,
      oldestSequence: _readNullableInt(data['oldestSequence']),
      latestSequence: _readNullableInt(data['latestSequence']),
    );
  }

  @override
  Future<void> markRead(int roomId, int lastReadSequence) async {
    _ensureSuccess(
      await _apiClient.patchJson(
        '/api/v1/chat/rooms/$roomId/read',
        body: {'lastReadSequence': lastReadSequence},
      ),
    );
  }

  @override
  Future<bool> getChatNotificationEnabled(int roomId) async {
    final response = await _apiClient.getJson(
      '/api/v1/chat/rooms/$roomId/notification-setting',
    );
    return _readEnabled(_readData(response));
  }

  @override
  Future<bool> updateChatNotificationEnabled(int roomId, bool enabled) async {
    final response = await _apiClient.patchJson(
      '/api/v1/chat/rooms/$roomId/notification-setting',
      body: {'enabled': enabled},
    );
    return _readEnabled(_readData(response));
  }

  ChatRoom _roomFromJson(Map<String, dynamic> json) {
    final lastMessage = json['lastMessage'];
    return ChatRoom(
      roomId: _readInt(json['roomId']),
      meetingId: _readInt(json['meetingId']),
      meetingTitle: _readString(json['meetingTitle'], fallback: '이름 없는 채팅방'),
      meetingStatus: _readString(json['meetingStatus']),
      thumbnailImageUrl: _readNullableString(json['thumbnailImageUrl']),
      lastMessage: lastMessage == null
          ? null
          : _messageFromJson(_readMap(lastMessage, 'lastMessage')),
      unreadCount: _readInt(json['unreadCount']),
      canSend: json['canSend'] == true,
    );
  }

  ChatMessage _messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _readInt(json['id']),
      roomId: _readInt(json['roomId']),
      sequence: _readInt(json['sequence']),
      clientMessageId: _readString(json['clientMessageId']),
      senderId: _readInt(json['senderId']),
      senderNickname: _readString(
        json['senderNickname'],
        fallback: '알 수 없는 사용자',
      ),
      senderProfileImageUrl: _readNullableString(json['senderProfileImageUrl']),
      content: _readString(json['content']),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> _readData(Map<String, dynamic> response) {
    _ensureSuccess(response);
    return _readMap(response['data'], 'data');
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw ApiException(
        statusCode: _readInt(response['status']),
        message: _readString(
          response['message'],
          fallback: '채팅 정보를 불러오지 못했습니다.',
        ),
        body: response,
      );
    }
  }

  Map<String, dynamic> _readMap(Object? value, String fieldName) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw FormatException('Expected $fieldName to be an object.');
  }

  List<dynamic> _readList(Object? value, String fieldName) {
    if (value is List) return value;
    throw FormatException('Expected $fieldName to be a list.');
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  int? _readNullableInt(Object? value) {
    if (value == null) return null;
    final parsed = _readInt(value, fallback: -1);
    return parsed < 0 ? null : parsed;
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  bool _readEnabled(Map<String, dynamic> data) {
    final enabled = data['enabled'];
    if (enabled is bool) return enabled;
    throw const FormatException('Expected data.enabled to be a boolean.');
  }

  DateTime _readDateTime(Object? value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const FormatException('Expected a valid date-time value.');
  }
}
