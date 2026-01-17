class Message {
  final String name;
  final String sender;
  final String content;
  final String messageType;
  final DateTime creation;
  final bool isRead;

  Message({
    required this.name,
    required this.sender,
    required this.content,
    required this.messageType,
    required this.creation,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      name: json['name'] ?? '',
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'text',
      creation: DateTime.tryParse(json['creation'] ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }
}
