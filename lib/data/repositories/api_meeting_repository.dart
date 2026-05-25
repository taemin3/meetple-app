import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/meeting.dart';
import 'meeting_repository.dart';

class ApiMeetingRepository implements MeetingRepository {
  ApiMeetingRepository({
    required ApiClient apiClient,
    this.status,
    this.page = 0,
    this.size = 20,
  }) : _apiClient = apiClient;

  ApiMeetingRepository.withBaseUrl({
    String baseUrl = AppConfig.apiBaseUrl,
    AccessTokenProvider? accessTokenProvider,
    String? status,
    int page = 0,
    int size = 20,
  }) : this(
          apiClient: HttpApiClient(
            baseUri: Uri.parse(baseUrl),
            accessTokenProvider: accessTokenProvider,
          ),
          status: status,
          page: page,
          size: size,
        );

  final ApiClient _apiClient;
  final String? status;
  final int page;
  final int size;

  @override
  Future<List<Meeting>> findAll() async {
    final response = await _apiClient.getJson(
      '/api/v1/meetings',
      queryParameters: {
        'status': status,
        'page': page.toString(),
        'size': size.toString(),
      },
    );

    _ensureSuccess(response);

    final data = _readMap(response['data'], 'data');
    final content = _readList(data['content'], 'data.content');

    return [
      for (final item in content)
        _meetingFromJson(_readMap(item, 'data.content[]')),
    ];
  }

  void _ensureSuccess(Map<String, dynamic> response) {
    if (response['success'] != true) {
      throw ApiException(
        statusCode: _readInt(response['status']),
        message:
            _readString(response['message'], fallback: 'API request failed.'),
        body: response,
      );
    }
  }
  }

  Meeting _meetingFromJson(Map<String, dynamic> json) {
    final category = _readString(json['categoryName'], fallback: '기타');
    final scheduledAt = _readDateTime(json['scheduledAt']);
    final area = _firstNonBlank([
      json['locationName'],
      json['address'],
    ], fallback: '장소 미정');

    return Meeting(
      id: _readNullableInt(json['id']),
      title: _readString(json['title'], fallback: '제목 없는 모임'),
      category: category,
      tags: category.isEmpty ? const [] : [category],
      area: area,
      date: _formatDate(scheduledAt),
      time: _formatTime(scheduledAt),
      distance: '거리 미정',
      capacity: _readInt(json['capacity']),
      joined: _readInt(json['currentPeople']),
      host: _readString(json['hostNickname'], fallback: '호스트'),
      description: _readString(json['description']),
      fee: '참가비 미정',
      rating: 0,
      reviewCount: 0,
      thumbnailImageUrl: _readNullableString(json['thumbnailImageUrl']),
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
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  int? _readNullableInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return fallback;
  }

  String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return null;
  }

  DateTime? _readDateTime(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String _firstNonBlank(List<Object?> values, {required String fallback}) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '일정 미정';
    }

    return '${dateTime.month}/${dateTime.day}';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '시간 미정';
    }

    return '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
