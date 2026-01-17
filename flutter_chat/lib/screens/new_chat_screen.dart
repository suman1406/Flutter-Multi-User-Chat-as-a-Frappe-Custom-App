import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chatNameController = TextEditingController();
  List<Map<String, String>> _availableUsers = [];
  final Set<String> _selectedUserEmails = {};
  bool _loading = false;
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final authService = context.read<AuthService>();
      final users = await authService.getUsers();
      if (mounted) {
        setState(() {
          _availableUsers = users;
          _loadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingUsers = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
      }
    }
  }

  @override
  void dispose() {
    _chatNameController.dispose();
    super.dispose();
  }

  Future<void> _createChat() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final authService = context.read<AuthService>();
      final chatService = ChatService(authService);
      await chatService.createChat(
        _chatNameController.text.trim(),
        _selectedUserEmails.toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Chat')),
      body: _loadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _chatNameController,
                      decoration: const InputDecoration(
                        labelText: 'Chat Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.chat),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Enter chat name' : null,
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Participants (${_selectedUserEmails.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _availableUsers.isEmpty
                        ? const Center(child: Text('No other users found'))
                        : ListView.builder(
                            itemCount: _availableUsers.length,
                            itemBuilder: (context, index) {
                              final user = _availableUsers[index];
                              final email =
                                  user['name']!; // 'name' is email in user doc
                              final fullName = user['full_name'] ?? email;
                              final isSelected = _selectedUserEmails.contains(
                                email,
                              );

                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(fullName),
                                subtitle: Text(email),
                                secondary: CircleAvatar(
                                  child: Text(fullName[0].toUpperCase()),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedUserEmails.add(email);
                                    } else {
                                      _selectedUserEmails.remove(email);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _createChat,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Chat'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
