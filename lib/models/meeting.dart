class Meeting {
  const Meeting({
    this.id,
    required this.title,
    required this.category,
    required this.tags,
    required this.area,
    required this.date,
    required this.time,
    required this.distance,
    required this.capacity,
    required this.joined,
    required this.host,
    required this.description,
    required this.fee,
    required this.rating,
    required this.reviewCount,
    this.thumbnailImageUrl,
  });

  final int? id;
  final String title;
  final String category;
  final List<String> tags;
  final String area;
  final String date;
  final String time;
  final String distance;
  final int capacity;
  final int joined;
  final String host;
  final String description;
  final String fee;
  final double rating;
  final int reviewCount;
  final String? thumbnailImageUrl;
}
