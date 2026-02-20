// lib/models/app_user.dart
class AppUser {
  final String id;
  final String email;
  final String name;
  final String passwordHash;
  final DateTime createdAt;

  const AppUser({
    required this.id, required this.email, required this.name,
    required this.passwordHash, required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'name': name,
    'passwordHash': passwordHash,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'], email: j['email'], name: j['name'],
    passwordHash: j['passwordHash'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}
