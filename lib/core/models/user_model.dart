enum UserRole { student, teacher, parent }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final String? school;
  final String? grade;
  final String? section;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.school,
    this.grade,
    this.section,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? phone,
    String? school,
    String? grade,
    String? section,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      section: section ?? this.section,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.student,
      ),
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      school: json['school'] as String?,
      grade: json['grade'] as String?,
      section: json['section'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'avatarUrl': avatarUrl,
        'phone': phone,
        'school': school,
        'grade': grade,
        'section': section,
      };
}
