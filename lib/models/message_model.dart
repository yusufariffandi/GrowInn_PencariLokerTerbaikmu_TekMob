class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String attachmentUrl;
  final bool readStatus;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.attachmentUrl = '',
    this.readStatus = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      text: json['text'] ?? '',
      attachmentUrl: json['attachment_url'] ?? '',
      readStatus: json['read_status'] ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ChatThread {
  final String peerId;
  final String peerName;
  final String peerAvatar;
  final String lastMessage;
  final DateTime lastTime;
  final int unreadCount;

  ChatThread({
    required this.peerId,
    required this.peerName,
    this.peerAvatar = '',
    this.lastMessage = '',
    required this.lastTime,
    this.unreadCount = 0,
  });
}
