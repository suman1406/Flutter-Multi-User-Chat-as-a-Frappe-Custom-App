import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'chat_service.dart';

class RealtimeService extends ChangeNotifier {
  final ChatService _chatService;
  Timer? _pollTimer;
  String? _currentChat;
  List<Message> _messages = [];
  DateTime? _lastMessageTime;
  bool _isPolling = false;
  int _pollIntervalMs = 500;

  List<Message> get messages => _messages;
  bool get isPolling => _isPolling;

  RealtimeService(this._chatService);

  void subscribeToChat(String chatId) {
    _currentChat = chatId;
    _messages = [];
    _lastMessageTime = null;
    _pollIntervalMs = 500;
    _startPolling();
  }

  void unsubscribe() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _currentChat = null;
    _isPolling = false;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _isPolling = true;
    _fetchMessages();
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollTimer = Timer(Duration(milliseconds: _pollIntervalMs), () {
      _fetchMessages();
      if (_currentChat != null) _scheduleNextPoll();
    });
  }

  Future<void> _fetchMessages() async {
    if (_currentChat == null || !_isPolling) return;

    try {
      final newMessages = await _chatService.getMessages(
        _currentChat!,
        after: _lastMessageTime?.toIso8601String(),
      );

      if (newMessages.isNotEmpty) {
        _messages.addAll(newMessages);
        _lastMessageTime = newMessages.last.creation;
        _pollIntervalMs = 500;
        notifyListeners();
      } else {
        _pollIntervalMs = (_pollIntervalMs * 1.2).clamp(500, 3000).toInt();
      }
    } catch (e) {
      debugPrint('Polling error: $e');
      _pollIntervalMs = 2000;
    }
  }

  Future<void> sendMessage(String content) async {
    if (_currentChat == null) return;

    final message = await _chatService.sendMessage(_currentChat!, content);
    _messages.add(message);
    _lastMessageTime = message.creation;
    _pollIntervalMs = 500;
    notifyListeners();
  }

  Future<void> loadInitialMessages() async {
    if (_currentChat == null) return;

    try {
      _messages = await _chatService.getMessages(_currentChat!, limit: 50);
      if (_messages.isNotEmpty) {
        _lastMessageTime = _messages.last.creation;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load messages error: $e');
    }
  }

  void clearMessages() {
    _messages = [];
    _lastMessageTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _isPolling = false;
    super.dispose();
  }
}
