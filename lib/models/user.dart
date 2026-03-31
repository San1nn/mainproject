/// User model with role-based access control
enum UserRole { admin, user, moderator }

class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.role,
    required this.createdAt,
  });

  /// Convert User to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
    'role': role.toString().split('.').last,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      photoUrl: json['photoUrl']?.toString(),
      role: UserRole.values.firstWhere(
        (role) => role.toString().split('.').last == json['role']?.toString(),
        orElse: () => UserRole.user,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Create a copy with modified fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
