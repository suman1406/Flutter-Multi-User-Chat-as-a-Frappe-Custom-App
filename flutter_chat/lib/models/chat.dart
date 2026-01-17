class Chat {
  final String name;
  final String chatName;
  final String chatType;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  Chat({
    required this.name,
    required this.chatName,
    required this.chatType,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      name: json['name'] ?? '',
      chatName: json['chat_name'] ?? '',
      chatType: json['chat_type'] ?? 'Direct',
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'])
          : null,
    );
  }

  set participants(List<dynamic> participants) {}
}
