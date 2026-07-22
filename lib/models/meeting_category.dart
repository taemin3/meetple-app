class MeetingCategory {
  const MeetingCategory({
    required this.id,
    required this.name,
    this.defaultImageUrl,
  });

  final int id;
  final String name;
  final String? defaultImageUrl;
}
