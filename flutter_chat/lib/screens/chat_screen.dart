import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/realtime_service.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late RealtimeService _realtimeService;
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    _chatService = ChatService(authService);
    _realtimeService = RealtimeService(_chatService);
    _realtimeService.subscribeToChat(widget.chat.name);
    _realtimeService.loadInitialMessages();
    _realtimeService.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _realtimeService.removeListener(_scrollToBottom);
    _realtimeService.unsubscribe();
    _realtimeService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    await _realtimeService.sendMessage(content);
  }

  List<Map<String, String>> _participants = [];

  Future<void> _getParticipants() async {
    try {
      final participants = await _chatService.getChatParticipants(
        widget.chat.name,
      );
      if (mounted) {
        setState(() => _participants = participants);
      }
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.chatName),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () async {
              await _getParticipants();
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Participants'),
                  content: _participants.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No participants found'),
                        )
                      : SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _participants.length,
                            itemBuilder: (context, index) {
                              final participant = _participants[index];
                              final fullName = participant['full_name'] ?? '';
                              final email = participant['email'] ?? '';
                              final initial = fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : (email.isNotEmpty
                                        ? email[0].toUpperCase()
                                        : '?');
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Text(initial),
                                ),
                                title: Text(fullName),
                                subtitle: Text(email),
                              );
                            },
                          ),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: _realtimeService,
              builder: (context, _) {
                final messages = _realtimeService.messages;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.sender == currentUser;
                    return _MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? Radius.zero : null,
            bottomLeft: !isMe ? Radius.zero : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.sender.split('@').first,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : null),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.creation.hour.toString().padLeft(2, '0')}:${message.creation.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
