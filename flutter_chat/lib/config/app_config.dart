class AppConfig {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String apiPath = '/api/method/frappe_chat.api';

  static String get loginUrl => '$baseUrl/api/method/frappe_chat.api.login';
  static String get signupUrl => '$baseUrl/api/method/frappe_chat.api.signup';
  static String get getUsersUrl =>
      '$baseUrl/api/method/frappe_chat.api.get_users';
  static String get logoutUrl => '$baseUrl/api/method/logout';
  static String get getChatsUrl => '$baseUrl$apiPath.get_chats';
  static String get createChatUrl => '$baseUrl$apiPath.create_chat';
  static String get getMessagesUrl => '$baseUrl$apiPath.get_messages';
  static String get sendMessageUrl => '$baseUrl$apiPath.send_message';
  static String get markAsReadUrl => '$baseUrl$apiPath.mark_as_read';
  static String get getParticipantsUrl =>
      '$baseUrl$apiPath.get_chat_participants';
}
