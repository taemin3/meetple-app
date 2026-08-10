import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/app_notification.dart';
import 'notification_repository.dart';

class ApiNotificationRepository extends NotificationRepository {
  ApiNotificationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  ApiNotificationRepository.withBaseUrl({
    String baseUrl = AppConfig.apiBaseUrl,
    AccessTokenProvider? accessTokenProvider,
  }) : this(
          apiClient: HttpApiClient(
            baseUri: Uri.parse(baseUrl),
            accessTokenProvider: accessTokenProvider,
          ),
        );

  final ApiClient _apiClient;

  @override
  Future<List<AppNotification>> getNotifications() async {
    final notifications = <AppNotification>[];
    var page = 0;

    while (true) {
      final response = await _apiClient.getJson(
        '/api/v1/notifications',
        queryParameters: {'page': '$page', 'size': '100'},
      );
      _ensureSuccess(response);
      final data = _readMap(response['data'], 'data');
      notifications.addAll([
        for (final item in _readList(data['content'], 'data.content'))
          _notificationFromJson(_readMap(item, 'data.content[]')),
      ]);

      final totalPages = _readInt(data['totalPages']);
      final isLast = data['last'] == true;
      if (isLast || totalPages == 0 || page + 1 >= totalPages) {
        break;
      }
      page += 1;
    }

    return notifications;
  }

  @override
  Future<void> markNotificationRead(int notificationId) async {
    _ensureSuccess(
      await _apiClient.patchJson(
        '/api/v1/notifications/$notificationId/read',
      ),
    );
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw ApiException(
        statusCode: _readInt(response['status']),
        message: _readString(
          response['message'],
          fallback: 'API request failed.',
        ),
        body: response,
      );
    }
  }

  AppNotification _notificationFromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _readInt(json['id']),
      type: _readString(json['type']),
      title: _readString(json['title'], fallback: '알림'),
      message: _readString(json['message']),
      meetingId: _readNullableInt(json['meetingId']),
      readAt: _readDateTime(json['readAt']),
      createdAt: _readDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> _readMap(Object? value, String fieldName) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw FormatException('Expected $fieldName to be an object.');
  }

  List<Object?> _readList(Object? value, String fieldName) {
    if (value is List) {
      return value;
    }
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
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  DateTime? _readDateTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
