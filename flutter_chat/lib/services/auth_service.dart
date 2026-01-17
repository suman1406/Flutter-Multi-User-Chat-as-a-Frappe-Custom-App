import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  User? _currentUser;
  String? _authToken;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _authToken = await _storage.read(key: 'auth_token');
    final userData = await _storage.read(key: 'user_data');
    if (userData != null && _authToken != null) {
      _currentUser = User.fromJson(jsonDecode(userData));
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(AppConfig.loginUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Expect': '',
        },
        body: {'usr': email, 'pwd': password},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final messageData = data['message'];

        // Handle both standard login and custom API response (nested vs flat)
        final statusMsg = messageData is Map
            ? messageData['message']
            : messageData;

        if (statusMsg == 'Logged In') {
          final apiKey = messageData is Map
              ? messageData['api_key']
              : data['api_key'];
          final apiSecret = messageData is Map
              ? messageData['api_secret']
              : data['api_secret'];
          final userName = messageData is Map
              ? messageData['full_name']
              : data['full_name'];
          final userEmail = messageData is Map
              ? messageData['email']
              : data['email'];

          if (apiKey != null && apiSecret != null) {
            _authToken = 'token $apiKey:$apiSecret';

            _currentUser = User(
              name: userName ?? email,
              email: userEmail ?? email,
              fullName: userName,
            );

            await _storage.write(key: 'auth_token', value: _authToken);
            await _storage.write(
              key: 'user_data',
              value: jsonEncode(_currentUser!.toJson()),
            );

            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      }
      debugPrint('Login failed: ${response.body}');
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<String?> signup(String email, String password, String fullName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(AppConfig.signupUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Expect': '',
        },
        body: {'email': email, 'password': password, 'full_name': fullName},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Frappe returns { "message": { "message": "User Created", ... } }
        final messageData = data['message'];

        // Handle nested structure or flat structure
        final statusMsg = messageData is Map
            ? messageData['message']
            : messageData;

        if (statusMsg == 'User Created') {
          final apiKey = messageData is Map
              ? messageData['api_key']
              : data['api_key'];
          final apiSecret = messageData is Map
              ? messageData['api_secret']
              : data['api_secret'];
          final userName = messageData is Map
              ? messageData['full_name']
              : data['full_name'];
          final userEmail = messageData is Map
              ? messageData['email']
              : data['email'];

          if (apiKey != null && apiSecret != null) {
            _authToken = 'token $apiKey:$apiSecret';

            _currentUser = User(
              name: userName ?? email,
              email: userEmail ?? email,
              fullName: userName,
            );

            await _storage.write(key: 'auth_token', value: _authToken);
            await _storage.write(
              key: 'user_data',
              value: jsonEncode(_currentUser!.toJson()),
            );

            _isLoading = false;
            notifyListeners();
            return null; // Null means success (no error)
          }
        }
      }

      // Parse error messages from Frappe response
      if (data['_server_messages'] != null) {
        try {
          final List<dynamic> messages = jsonDecode(data['_server_messages']);
          // Extract the first error message, stripping HTML tags if present
          final errorJson = jsonDecode(messages.first);
          String errorMessage = errorJson['message'] ?? 'Signup failed';
          // Simple regex to strip basic HTML tags like <div>, <br>
          errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          _isLoading = false;
          notifyListeners();
          return errorMessage;
        } catch (_) {}
      }

      if (data['exception'] != null) {
        // Try to extract readable part of exception
        final exc = data['exception'].toString();
        final parts = exc.split(':');
        if (parts.length > 1) {
          _isLoading = false;
          notifyListeners();
          return parts.last.trim();
        }
      }

      debugPrint('Signup failed: ${response.body}');
      _isLoading = false;
      notifyListeners();
      return 'Signup failed: ${response.reasonPhrase ?? "Unknown error"}';
    } catch (e) {
      debugPrint('Signup error: $e');
      _isLoading = false;
      notifyListeners();
      return 'Network error: $e';
    }
  }

  Future<List<Map<String, String>>> getUsers() async {
    if (_authToken == null) return [];

    try {
      final response = await http.get(
        Uri.parse(AppConfig.getUsersUrl),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> users = data['message'] ?? [];
        return users
            .map(
              (u) => {
                'name': u['name']?.toString() ?? '',
                'full_name': u['full_name']?.toString() ?? '',
                'email': u['email']?.toString() ?? '',
              },
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Get Users error: $e');
    }
    return [];
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _currentUser = null;
    _authToken = null;
    notifyListeners();
  }

  Map<String, String> get authHeaders => {
    if (_authToken != null) 'Authorization': _authToken!,
  };
}
