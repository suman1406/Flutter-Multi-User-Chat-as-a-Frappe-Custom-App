import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> _chats = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadChats();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadChats();
    });
  }

  Future<void> _loadChats() async {
    final authService = context.read<AuthService>();
    final chatService = ChatService(authService);

    try {
      final chats = await chatService.getChats();
      if (mounted) setState(() => _chats = chats);
    } catch (e) {
      debugPrint('Error loading chats: $e');
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  String? _name;

  Future<void> _loadName() async {
    try {
      final authService = context.read<AuthService>();
      _name = authService.currentUser?.fullName;
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_name ?? 'Chats'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadChats),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadChats,
              child: ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(chat.chatName[0].toUpperCase()),
                    ),
                    title: Text(chat.chatName),
                    subtitle: chat.lastMessage != null
                        ? Text(
                            chat.lastMessage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: chat.lastMessageAt != null
                        ? Text(
                            _formatTime(chat.lastMessageAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NewChatScreen()),
          );
          if (result == true) _loadChats();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}
