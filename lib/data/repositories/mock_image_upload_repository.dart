import 'image_upload_repository.dart';

class MockImageUploadRepository implements ImageUploadRepository {
  const MockImageUploadRepository();

  @override
  Future<List<UploadedImage>> uploadMeetingImages(
    List<ImageUploadFile> images,
  ) async {
    return [
      for (var index = 0; index < images.length; index += 1)
        UploadedImage(
          objectKey: 'images/meeting/mock/mock-image-$index.jpg',
          fileUrl: 'https://example.com/meetings/mock-image-$index.jpg',
        ),
    ];
  }

  @override
  Future<UploadedImage> uploadProfileImage(ImageUploadFile image) async {
    return const UploadedImage(
      objectKey: 'images/profile/mock/mock-profile-image.jpg',
      fileUrl: 'https://example.com/profile/mock-profile-image.jpg',
    );
  }
}
