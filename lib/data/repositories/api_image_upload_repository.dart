import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import 'image_upload_repository.dart';

class ApiImageUploadRepository implements ImageUploadRepository {
  ApiImageUploadRepository({
    required ApiClient apiClient,
    http.Client? httpClient,
  })  : _apiClient = apiClient,
        _httpClient = httpClient ?? http.Client();

  ApiImageUploadRepository.withBaseUrl({
    String baseUrl = AppConfig.apiBaseUrl,
    AccessTokenProvider? accessTokenProvider,
    UnauthorizedTokenRefresher? unauthorizedTokenRefresher,
    http.Client? httpClient,
  }) : this(
          apiClient: HttpApiClient(
            baseUri: Uri.parse(baseUrl),
            accessTokenProvider: accessTokenProvider,
            unauthorizedTokenRefresher: unauthorizedTokenRefresher,
          ),
          httpClient: httpClient,
        );

  final ApiClient _apiClient;
  final http.Client _httpClient;

  static const Set<String> _clientManagedHeaderNames = {
    'connection',
    'content-length',
    'host',
    'transfer-encoding',
  };

  @override
  Future<List<UploadedImage>> uploadMeetingImages(
    List<ImageUploadFile> images,
  ) async {
    if (images.isEmpty) {
      return const [];
    }

    final response = await _apiClient.postJson(
      '/api/v1/images/upload-urls',
      body: {
        'images': [
          for (final image in images)
            {
              'purpose': 'MEETING',
              'fileName': image.name,
              'contentType': image.contentType,
              'contentLength': image.contentLength,
            },
        ],
      },
    );
    _ensureSuccess(response);

    final uploads = [
      for (final item in _readList(response['data'], 'data'))
        _UploadUrlContract.fromJson(_readMap(item, 'data[]')),
    ];

    if (uploads.length != images.length) {
      throw const FormatException('Upload URL count does not match images.');
    }

    final uploadedImages = <UploadedImage>[];
    for (var index = 0; index < images.length; index += 1) {
      await _uploadImage(uploads[index], images[index]);
      uploadedImages.add(
        UploadedImage(
          objectKey: uploads[index].objectKey,
          fileUrl: uploads[index].fileUrl,
        ),
      );
    }

    return uploadedImages;
  }

  @override
  Future<UploadedImage> uploadProfileImage(ImageUploadFile image) async {
    final response = await _apiClient.postJson(
      '/api/v1/images/upload-url',
      body: {
        'purpose': 'PROFILE',
        'fileName': image.name,
        'contentType': image.contentType,
        'contentLength': image.contentLength,
      },
    );
    _ensureSuccess(response);

    final upload = _UploadUrlContract.fromJson(
      _readMap(response['data'], 'data'),
    );
    await _uploadImage(upload, image);

    final profileResponse = await _apiClient.patchJson(
      '/api/v1/users/me/profile-image',
      body: {'profileImageObjectKey': upload.objectKey},
    );
    _ensureSuccess(profileResponse);

    return UploadedImage(objectKey: upload.objectKey, fileUrl: upload.fileUrl);
  }

  Future<void> _uploadImage(
    _UploadUrlContract upload,
    ImageUploadFile image,
  ) async {
    final response = await _httpClient.put(
      Uri.parse(upload.uploadUrl),
      headers: _uploadHeaders(upload.headers),
      body: image.bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ImageUploadException('이미지 업로드에 실패했습니다.');
    }
  }

  static Map<String, String> _uploadHeaders(Map<String, String> headers) {
    return {
      for (final entry in headers.entries)
        if (!_isClientManagedHeader(entry.key)) entry.key: entry.value,
    };
  }

  static bool _isClientManagedHeader(String name) {
    final normalizedName = name.toLowerCase();
    return _clientManagedHeaderNames.contains(normalizedName) ||
        normalizedName.startsWith('proxy-') ||
        normalizedName.startsWith('sec-');
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

  static Map<String, dynamic> _readMap(Object? value, String fieldName) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    throw FormatException('Expected $fieldName to be an object.');
  }

  static List<Object?> _readList(Object? value, String fieldName) {
    if (value is List) {
      return value;
    }

    throw FormatException('Expected $fieldName to be a list.');
  }

  static int _readInt(Object? value, {int fallback = 0}) {
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

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return fallback;
  }
}

class _UploadUrlContract {
  const _UploadUrlContract({
    required this.uploadUrl,
    required this.fileUrl,
    required this.objectKey,
    required this.headers,
  });

  factory _UploadUrlContract.fromJson(Map<String, dynamic> json) {
    final uploadUrl = ApiImageUploadRepository._readString(json['uploadUrl']);
    final fileUrl = ApiImageUploadRepository._readString(json['fileUrl']);
    final objectKey = ApiImageUploadRepository._readString(json['objectKey']);
    if (uploadUrl.isEmpty || fileUrl.isEmpty || objectKey.isEmpty) {
      throw const FormatException(
        'Upload response must include uploadUrl, fileUrl, and objectKey.',
      );
    }
    return _UploadUrlContract(
      uploadUrl: uploadUrl,
      fileUrl: fileUrl,
      objectKey: objectKey,
      headers: _readHeaders(json['headers']),
    );
  }

  final String uploadUrl;
  final String fileUrl;
  final String objectKey;
  final Map<String, String> headers;

  static Map<String, String> _readHeaders(Object? value) {
    if (value is! Map) {
      return const {};
    }

    return {
      for (final entry in value.entries)
        if (entry.value != null) entry.key.toString(): entry.value.toString(),
    };
  }
}
