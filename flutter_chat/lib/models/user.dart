class User {
  final String name;
  final String email;
  final String? fullName;

  User({required this.name, required this.email, this.fullName});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? json['email'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'full_name': fullName,
  };
}
