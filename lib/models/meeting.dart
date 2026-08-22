class Meeting {
  const Meeting({
    this.id,
    this.hostId,
    required this.title,
    required this.category,
    required this.tags,
    required this.area,
    this.address,
    this.latitude,
    this.longitude,
    required this.date,
    required this.time,
    required this.distance,
    required this.capacity,
    required this.joined,
    required this.host,
    this.hostProfileImageUrl,
    this.hostIntroduction,
    required this.description,
    required this.fee,
    required this.rating,
    required this.reviewCount,
    this.thumbnailImageUrl,
    this.imageUrls = const [],
    this.imageObjectKeys = const [],
    this.status = 'RECRUITING',
    this.scheduledAt,
    this.endsAt,
    this.cancelReason,
  });

  final int? id;
  final int? hostId;
  final String title;
  final String category;
  final List<String> tags;
  final String area;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String date;
  final String time;
  final String distance;
  final int capacity;
  final int joined;
  final String host;
  final String? hostProfileImageUrl;
  final String? hostIntroduction;
  final String description;
  final String fee;
  final double rating;
  final int reviewCount;
  final String? thumbnailImageUrl;
  final List<String> imageUrls;
  final List<String> imageObjectKeys;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? endsAt;
  final String? cancelReason;

  bool get hasCoordinate => latitude != null && longitude != null;

  String? get primaryImageUrl {
    final thumbnail = thumbnailImageUrl?.trim();
    if (thumbnail != null && thumbnail.isNotEmpty) {
      return thumbnail;
    }

    for (final imageUrl in imageUrls) {
      final normalizedUrl = imageUrl.trim();
      if (normalizedUrl.isNotEmpty) {
        return normalizedUrl;
      }
    }
    return null;
  }

  Meeting copyWith({
    int? id,
    int? hostId,
    String? title,
    String? category,
    List<String>? tags,
    String? area,
    String? address,
    double? latitude,
    double? longitude,
    String? date,
    String? time,
    String? distance,
    int? capacity,
    int? joined,
    String? host,
    String? hostProfileImageUrl,
    bool clearHostProfileImageUrl = false,
    String? hostIntroduction,
    bool clearHostIntroduction = false,
    String? description,
    String? fee,
    double? rating,
    int? reviewCount,
    String? thumbnailImageUrl,
    bool clearThumbnailImageUrl = false,
    List<String>? imageUrls,
    List<String>? imageObjectKeys,
    String? status,
    DateTime? scheduledAt,
    DateTime? endsAt,
    bool clearEndsAt = false,
    String? cancelReason,
  }) {
    return Meeting(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      area: area ?? this.area,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      date: date ?? this.date,
      time: time ?? this.time,
      distance: distance ?? this.distance,
      capacity: capacity ?? this.capacity,
      joined: joined ?? this.joined,
      host: host ?? this.host,
      hostProfileImageUrl: clearHostProfileImageUrl
          ? null
          : hostProfileImageUrl ?? this.hostProfileImageUrl,
      hostIntroduction: clearHostIntroduction
          ? null
          : hostIntroduction ?? this.hostIntroduction,
      description: description ?? this.description,
      fee: fee ?? this.fee,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      thumbnailImageUrl: clearThumbnailImageUrl
          ? null
          : thumbnailImageUrl ?? this.thumbnailImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      imageObjectKeys: imageObjectKeys ?? this.imageObjectKeys,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      endsAt: clearEndsAt ? null : endsAt ?? this.endsAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }
}
