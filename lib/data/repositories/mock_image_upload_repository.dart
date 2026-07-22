import 'image_upload_repository.dart';

class MockImageUploadRepository implements ImageUploadRepository {
  const MockImageUploadRepository();

  @override
  Future<List<String>> uploadMeetingImages(List<ImageUploadFile> images) async {
    return [
      for (var index = 0; index < images.length; index += 1)
        'https://example.com/meetings/mock-image-$index.jpg',
    ];
  }
}
