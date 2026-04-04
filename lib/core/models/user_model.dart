enum UserRole { admin, student, teacher, parent }

class UserModel {
  final String id;
  final String email;
  final UserRole role;

  // Legacy fields
  final String? avatarUrl;
  final String? school;

  // New fields
  final String firstName;
  final String lastName;
  final String? phone;
  final String? grade;
  final String? section;
  final String? subject;
  final String? department;
  final String? childName;
  final String? relationship;
  final bool mustChangePassword;
  final String? createdAt;
  final String? updatedAt;
  final String? legacyName;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.school,
    this.firstName = '',
    this.lastName = '',
    this.phone,
    this.grade,
    this.section,
    this.subject,
    this.department,
    this.childName,
    this.relationship,
    this.mustChangePassword = false,
    this.createdAt,
    this.updatedAt,
    String? name,
  }) : legacyName = name;

  String get fullName {
    final v = '$firstName $lastName'.trim();
    if (v.isNotEmpty) return v;
    if (legacyName != null && legacyName!.trim().isNotEmpty) {
      return legacyName!.trim();
    }
    return 'Student';
  }

  // Backward compatibility
  String get name => fullName;

  UserModel copyWith({
    String? id,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? school,
    String? firstName,
    String? lastName,
    String? phone,
    String? grade,
    String? section,
    String? subject,
    String? department,
    String? childName,
    String? relationship,
    bool? mustChangePassword,
    String? createdAt,
    String? updatedAt,
    String? name,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      school: school ?? this.school,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      department: department ?? this.department,
      childName: childName ?? this.childName,
      relationship: relationship ?? this.relationship,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? legacyName,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final legacyName = (json['name'] as String?)?.trim() ?? '';
    var first = (json['firstName'] as String?)?.trim() ?? '';
    var last = (json['lastName'] as String?)?.trim() ?? '';

    if (first.isEmpty && legacyName.isNotEmpty) {
      final parts = legacyName.split(' ');
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _parseRole(json['role']),
      avatarUrl: json['avatarUrl'] as String?,
      school: json['school'] as String?,
      firstName: first,
      lastName: last,
      phone: json['phone'] as String?,
      grade: json['grade'] as String?,
      section: json['section'] as String?,
      subject: json['subject'] as String?,
      department: json['department'] as String?,
      childName: json['childName'] as String?,
      relationship: json['relationship'] as String?,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      name: legacyName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role.name,
        'name': fullName, // backward compatibility
        'firstName': firstName,
        'lastName': lastName,
        'avatarUrl': avatarUrl,
        'school': school,
        'phone': phone,
        'grade': grade,
        'section': section,
        'subject': subject,
        'department': department,
        'childName': childName,
        'relationship': relationship,
        'mustChangePassword': mustChangePassword,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  static UserRole _parseRole(dynamic role) {
    if (role is String) {
      return UserRole.values.firstWhere(
        (r) => r.name == role,
        orElse: () => UserRole.student,
      );
    }
    return UserRole.student;
  }
}