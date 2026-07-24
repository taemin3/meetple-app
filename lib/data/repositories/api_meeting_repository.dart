import 'dart:math' as math;

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

  @override
  Future<List<Meeting>> findNearby(NearbyMeetingQuery query) async {
    final response = await _apiClient.getJson(
      '/api/v1/meetings/nearby',
      queryParameters: {
        'latitude': query.latitude.toString(),
        'longitude': query.longitude.toString(),
        'radiusMeters': query.radiusMeters.toString(),
        'category': query.category,
        'page': query.page.toString(),
        'size': query.size.toString(),
      },
    );

    _ensureSuccess(response);

    final data = _readMap(response['data'], 'data');
    final content = _readList(data['content'], 'data.content');

    return [
      for (final item in content)
        _meetingFromJson(
          _readMap(item, 'data.content[]'),
          originLatitude: query.latitude,
          originLongitude: query.longitude,
        ),
    ];
  }

  @override
  Future<Meeting> createMeeting(CreateMeetingInput input) async {
    final response = await _apiClient.postJson(
      '/api/v1/meetings',
      body: {
        'title': input.title,
        'category': input.category,
        'locationName': input.locationName,
        'address': input.address,
        'latitude': input.latitude,
        'longitude': input.longitude,
        'scheduledAt': _formatApiDateTime(input.scheduledAt),
        'capacity': input.capacity,
        'description': input.description,
        if (input.imageUrls.isNotEmpty) 'imageUrls': input.imageUrls,
      },
    );

    _ensureSuccess(response);

    return _meetingFromJson(_readMap(response['data'], 'data'));
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

  Meeting _meetingFromJson(
    Map<String, dynamic> json, {
    double? originLatitude,
    double? originLongitude,
  }) {
    final category = _readString(json['categoryName'], fallback: '기타');
    final scheduledAt = _readDateTime(json['scheduledAt']);
    final latitude = _readNullableDouble(json['latitude']);
    final longitude = _readNullableDouble(json['longitude']);
    final area = _firstNonBlank([
      json['locationName'],
      json['address'],
    ], fallback: '장소 미정');
    final distance = originLatitude != null &&
            originLongitude != null &&
            latitude != null &&
            longitude != null
        ? _formatDistance(
            _distanceMeters(
              originLatitude,
              originLongitude,
              latitude,
              longitude,
            ),
          )
        : '거리 미정';

    return Meeting(
      id: _readNullableInt(json['id']),
      hostId: _readNullableInt(json['hostId']),
      title: _readString(json['title'], fallback: '제목 없는 모임'),
      category: category,
      tags: category.isEmpty ? const [] : [category],
      area: area,
      address: _readNullableString(json['address']),
      latitude: latitude,
      longitude: longitude,
      date: _formatDate(scheduledAt),
      time: _formatTime(scheduledAt),
      distance: distance,
      capacity: _readInt(json['capacity']),
      joined: _readInt(json['currentPeople']),
      host: _readString(json['hostNickname'], fallback: '호스트'),
      description: _readString(json['description']),
      fee: '참가비 미정',
      rating: 0,
      reviewCount: 0,
      thumbnailImageUrl: _readNullableString(json['thumbnailImageUrl']),
      imageUrls: _readStringList(json['imageUrls']),
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

  double? _readNullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
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

  List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item,
    ];
  }

  DateTime? _readDateTime(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toLocal();
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

  String _formatApiDateTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();

    return '${localDateTime.year}-'
        '${_twoDigits(localDateTime.month)}-'
        '${_twoDigits(localDateTime.day)}T'
        '${_twoDigits(localDateTime.hour)}:'
        '${_twoDigits(localDateTime.minute)}:00';
  }

  double _distanceMeters(
    double fromLatitude,
    double fromLongitude,
    double toLatitude,
    double toLongitude,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _toRadians(toLatitude - fromLatitude);
    final longitudeDelta = _toRadians(toLongitude - fromLongitude);
    final fromLatitudeRadians = _toRadians(fromLatitude);
    final toLatitudeRadians = _toRadians(toLatitude);

    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
            math.cos(fromLatitudeRadians) *
                math.cos(toLatitudeRadians) *
                math.sin(longitudeDelta / 2) *
                math.sin(longitudeDelta / 2);

    return earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    }

    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}
