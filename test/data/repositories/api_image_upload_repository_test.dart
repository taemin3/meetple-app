import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meetple/core/network/api_client.dart';
import 'package:meetple/data/repositories/api_image_upload_repository.dart';
import 'package:meetple/data/repositories/image_upload_repository.dart';

void main() {
  test('requests upload URLs and uploads image bytes', () async {
    final putRequests = <http.Request>[];
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': [
          {
            'uploadUrl': 'https://upload.example.com/first',
            'fileUrl': 'https://cdn.example.com/first.png',
            'objectKey': 'images/meeting/1/first.png',
            'method': 'PUT',
            'headers': {
              'Content-Type': 'image/png',
              'Content-Length': '3',
              'Host': 'upload.example.com',
            },
            'expiresInSeconds': 300,
          },
        ],
      },
    );
    final repository = ApiImageUploadRepository(
      apiClient: apiClient,
      httpClient: MockClient((request) async {
        putRequests.add(request);
        expect(request.bodyBytes, [1, 2, 3]);
        return http.Response('', 200);
      }),
    );

    final uploadedImages = await repository.uploadMeetingImages([
      ImageUploadFile(
        name: 'first.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    ]);

    expect(apiClient.path, '/api/v1/images/upload-urls');
    expect(apiClient.body, {
      'images': [
        {
          'purpose': 'MEETING',
          'fileName': 'first.png',
          'contentType': 'image/png',
          'contentLength': 3,
        },
      ],
    });
    expect(uploadedImages.single.objectKey, 'images/meeting/1/first.png');
    expect(uploadedImages.single.fileUrl, 'https://cdn.example.com/first.png');
    expect(putRequests, hasLength(1));
    expect(putRequests.single.method, 'PUT');
    expect(
        putRequests.single.url.toString(), 'https://upload.example.com/first');
    expect(putRequests.single.headers['Content-Type'], 'image/png');
    expect(putRequests.single.headers, isNot(contains('Content-Length')));
    expect(putRequests.single.headers, isNot(contains('Host')));
  });

  test('returns empty list without API call when no images are selected',
      () async {
    final repository = ApiImageUploadRepository(
      apiClient: FakeApiClient(response: const {}),
      httpClient: MockClient((_) async => http.Response('', 500)),
    );

    final fileUrls = await repository.uploadMeetingImages(const []);

    expect(fileUrls, isEmpty);
  });

  test('uploads a profile image and links it to the current user', () async {
    final apiClient = FakeApiClient(
      response: {
        'status': 200,
        'success': true,
        'data': {
          'uploadUrl': 'https://upload.example.com/avatar',
          'fileUrl': 'https://cdn.example.com/avatar.png',
          'objectKey': 'images/profile/1/avatar.png',
          'headers': {'Content-Type': 'image/png'},
        },
      },
      patchResponse: {
        'status': 200,
        'success': true,
        'data': {'profileImageUrl': 'https://cdn.example.com/avatar.png'},
      },
    );
    final repository = ApiImageUploadRepository(
      apiClient: apiClient,
      httpClient: MockClient((request) async {
        expect(request.bodyBytes, [1, 2, 3]);
        return http.Response('', 200);
      }),
    );

    final uploadedImage = await repository.uploadProfileImage(
      ImageUploadFile(
        name: 'avatar.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    expect(apiClient.path, '/api/v1/images/upload-url');
    expect(apiClient.body, {
      'purpose': 'PROFILE',
      'fileName': 'avatar.png',
      'contentType': 'image/png',
      'contentLength': 3,
    });
    expect(apiClient.patchPath, '/api/v1/users/me/profile-image');
    expect(apiClient.patchBody, {
      'profileImageObjectKey': 'images/profile/1/avatar.png',
    });
    expect(uploadedImage.objectKey, 'images/profile/1/avatar.png');
    expect(uploadedImage.fileUrl, 'https://cdn.example.com/avatar.png');
  });

  test('throws ImageUploadException when storage upload fails', () async {
    final repository = ApiImageUploadRepository(
      apiClient: FakeApiClient(
        response: {
          'status': 200,
          'success': true,
          'data': [
            {
              'uploadUrl': 'https://upload.example.com/first',
              'fileUrl': 'https://cdn.example.com/first.png',
              'objectKey': 'images/meeting/1/first.png',
              'headers': {'Content-Type': 'image/png'},
            },
          ],
        },
      ),
      httpClient: MockClient((_) async => http.Response('', 403)),
    );

    await expectLater(
      repository.uploadMeetingImages([
        ImageUploadFile(
          name: 'first.png',
          contentType: 'image/png',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ]),
      throwsA(isA<ImageUploadException>()),
    );
  });
}

class FakeApiClient extends ApiClient {
  FakeApiClient({required this.response, this.patchResponse});

  final Map<String, dynamic> response;
  final Map<String, dynamic>? patchResponse;
  String? path;
  Map<String, dynamic>? body;
  String? patchPath;
  Map<String, dynamic>? patchBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  }) async {
    this.path = path;
    this.body = body;
    return response;
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    patchPath = path;
    patchBody = body;
    return patchResponse ?? response;
  }
}
