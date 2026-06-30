import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../models/meeting_category.dart';
import 'category_repository.dart';

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  ApiCategoryRepository.withBaseUrl({
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
  Future<List<MeetingCategory>> findAll() async {
    final response = await _apiClient.getJson('/api/v1/categories');

    _ensureSuccess(response);

    final data = _readList(response['data'], 'data');
    return [
      for (final item in data) _categoryFromJson(_readMap(item, 'data[]')),
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

  MeetingCategory _categoryFromJson(Map<String, dynamic> json) {
    return MeetingCategory(
      id: _readInt(json['id']),
      name: _readString(json['name'], fallback: '카테고리'),
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

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return fallback;
  }
}
