enum UserRole { admin, student, teacher, parent }

class UserModel {
  final String id;
  final String email;
  final UserRole role;
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

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
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
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _parseRole(json['role']),
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role.name,
        'firstName': firstName,
        'lastName': lastName,
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
