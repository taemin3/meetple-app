import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class ApiClient {
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  });

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  });

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) {
    throw UnimplementedError('PATCH is not implemented by this API client.');
  }

  Future<Map<String, dynamic>> deleteJson(String path) {
    throw UnimplementedError('DELETE is not implemented by this API client.');
  }
}

typedef AccessTokenProvider = FutureOr<String?> Function();

class HttpApiClient extends ApiClient {
  HttpApiClient({
    required Uri baseUri,
    http.Client? httpClient,
    AccessTokenProvider? accessTokenProvider,
  })  : _baseUri = _normalizeBaseUri(baseUri),
        _httpClient = httpClient ?? http.Client(),
        _accessTokenProvider = accessTokenProvider;

  final Uri _baseUri;
  final http.Client _httpClient;
  final AccessTokenProvider? _accessTokenProvider;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await _httpClient.get(uri, headers: await _headers());

    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
    bool includeAuthorization = true,
  }) async {
    final uri = _buildUri(path, const {});
    final response = await _httpClient.post(
      uri,
      headers: await _headers(
        contentType: 'application/json',
        includeAuthorization: includeAuthorization,
      ),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    final response = await _httpClient.patch(
      _buildUri(path, const {}),
      headers: await _headers(contentType: 'application/json'),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _httpClient.delete(
      _buildUri(path, const {}),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _tryDecodeBody(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: _messageFrom(decoded) ?? 'API request failed.',
        body: decoded,
      );
    }

    final decoded = _decodeBody(response);
    return decoded;
  }

  void close() {
    _httpClient.close();
  }

  Future<Map<String, String>> _headers({
    String? contentType,
    bool includeAuthorization = true,
  }) async {
    final headers = {'Accept': 'application/json'};
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }

    final token =
        includeAuthorization ? await _accessTokenProvider?.call() : null;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Uri _buildUri(String path, Map<String, String?> queryParameters) {
    final uri = _baseUri.resolve(path);
    final query = <String, String>{
      ...uri.queryParameters,
      for (final entry in queryParameters.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value!,
    };

    return uri.replace(queryParameters: query.isEmpty ? null : query);
  }

  static Uri _normalizeBaseUri(Uri baseUri) {
    if (baseUri.path.endsWith('/')) {
      return baseUri;
    }

    return baseUri.replace(path: '${baseUri.path}/');
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const FormatException('Expected API response body to be an object.');
  }

  static Map<String, dynamic> _tryDecodeBody(http.Response response) {
    try {
      return _decodeBody(response);
    } on FormatException {
      return const {};
    }
  }

  static String? _messageFrom(Map<String, dynamic> body) {
    return body['message']?.toString();
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.body = const {},
  });

  final int statusCode;
  final String message;
  final Map<String, dynamic> body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
