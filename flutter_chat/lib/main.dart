import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/chat_list_screen.dart';

void main() {
  runApp(const FrappeChatApp());
}

class FrappeChatApp extends StatelessWidget {
  const FrappeChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService()..init(),
      child: MaterialApp(
        title: 'Frappe Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        routes: {'/signup': (context) => const SignupScreen()},
        home: Consumer<AuthService>(
          builder: (context, authService, _) {
            if (authService.isAuthenticated) {
              return const ChatListScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
