class NotificationModel {
  final String id;
  final String userId;
  final String category; // job | status | message | tips
  final String title;
  final String body;
  final String actionUrl;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.category = 'job',
    required this.title,
    this.body = '',
    this.actionUrl = '',
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] ?? '',
      category: json['category'] ?? 'job',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      actionUrl: json['action_url'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
