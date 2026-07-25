class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.meetingId,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final int? meetingId;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;
}
