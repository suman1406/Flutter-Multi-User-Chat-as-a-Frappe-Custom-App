import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'auth_service.dart';

class ChatService {
  final AuthService _authService;

  ChatService(this._authService);

  Future<List<Chat>> getChats() async {
    final response = await http.get(
      Uri.parse(AppConfig.getChatsUrl),
      headers: {..._authService.authHeaders, 'Expect': ''},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> chats = data['message'] ?? [];
      return chats.map((c) => Chat.fromJson(c)).toList();
    }

    throw Exception('Failed to load chats: ${response.statusCode}');
  }

  Future<String> createChat(
    String chatName,
    List<String> participants, {
    String chatType = 'Direct',
  }) async {
    final response = await http.post(
      Uri.parse(AppConfig.createChatUrl),
      headers: {
        ..._authService.authHeaders,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Expect': '',
      },
      body: {
        'chat_name': chatName,
        'participants': jsonEncode(participants),
        'chat_type': chatType,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'];
    }

    throw Exception('Failed to create chat: ${response.statusCode}');
  }

  Future<List<Message>> getMessages(
    String chat, {
    String? after,
    int limit = 50,
  }) async {
    var url = '${AppConfig.getMessagesUrl}?chat=$chat&limit=$limit';
    if (after != null) url += '&after=$after';

    final response = await http.get(
      Uri.parse(url),
      headers: {..._authService.authHeaders, 'Expect': ''},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> messages = data['message'] ?? [];
      return messages.map((m) => Message.fromJson(m)).toList();
    }

    throw Exception('Failed to load messages: ${response.statusCode}');
  }

  Future<Message> sendMessage(
    String chat,
    String content, {
    String messageType = 'text',
  }) async {
    final response = await http.post(
      Uri.parse(AppConfig.sendMessageUrl),
      headers: {
        ..._authService.authHeaders,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Expect': '',
      },
      body: {'chat': chat, 'content': content, 'message_type': messageType},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Message.fromJson(data['message']);
    }

    throw Exception('Failed to send message: ${response.statusCode}');
  }

  Future<void> markAsRead(String chat) async {
    await http.post(
      Uri.parse(AppConfig.markAsReadUrl),
      headers: {
        ..._authService.authHeaders,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Expect': '',
      },
      body: {'chat': chat},
    );
  }

  Future<List<Map<String, String>>> getChatParticipants(String chat) async {
    final response = await http.get(
      Uri.parse('${AppConfig.getParticipantsUrl}?chat=$chat'),
      headers: {..._authService.authHeaders, 'Expect': ''},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> participants = data['message'] ?? [];
      return participants
          .map(
            (p) => {
              'email': p['user']?.toString() ?? '',
              'full_name':
                  p['full_name']?.toString() ?? p['user']?.toString() ?? '',
            },
          )
          .toList();
    }

    throw Exception('Failed to load participants: ${response.statusCode}');
  }
}
