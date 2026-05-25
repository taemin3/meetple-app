import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

abstract interface class ApiClient {
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  });
}

typedef AccessTokenProvider = FutureOr<String?> Function();

class HttpApiClient implements ApiClient {
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
    final decoded = _decodeBody(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _messageFrom(decoded) ?? 'API request failed.',
        body: decoded,
      );
    }

    return decoded;
  }

  void close() {
    _httpClient.close();
  }

  Future<Map<String, String>> _headers() async {
    final headers = {'Accept': 'application/json'};
    final token = await _accessTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Uri _buildUri(String path, Map<String, String?> queryParameters) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = _baseUri.resolve(normalizedPath);
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
