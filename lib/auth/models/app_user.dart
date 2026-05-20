class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    required this.totalExp,
    required this.isActive,
    required this.createdAt,
    required this.currentStreak,
    required this.lastStudyDate,
  });

  final String id;
  final String fullName;
  final String email;
  final String password;
  final UserRole role;
  final int totalExp;
  final bool isActive;
  final DateTime createdAt;
  final int currentStreak;
  final DateTime? lastStudyDate;

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? password,
    UserRole? role,
    int? totalExp,
    bool? isActive,
    DateTime? createdAt,
    int? currentStreak,
    DateTime? lastStudyDate,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      totalExp: totalExp ?? this.totalExp,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role.name,
      'totalEXP': totalExp,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'currentStreak': currentStreak,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: UserRole.values.byName(json['role'] as String),
      totalExp: (json['totalEXP'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      lastStudyDate: DateTime.tryParse(json['lastStudyDate'] as String? ?? ''),
    );
  }
}

enum UserRole { admin, user }
