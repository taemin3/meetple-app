import 'dart:typed_data';

abstract interface class ImageUploadRepository {
  Future<List<String>> uploadMeetingImages(List<ImageUploadFile> images);
}

class ImageUploadFile {
  const ImageUploadFile({
    required this.name,
    required this.contentType,
    required this.bytes,
  });

  final String name;
  final String contentType;
  final Uint8List bytes;

  int get contentLength => bytes.length;
}

class ImageUploadException implements Exception {
  const ImageUploadException(this.message);

  final String message;

  @override
  String toString() => 'ImageUploadException: $message';
}
