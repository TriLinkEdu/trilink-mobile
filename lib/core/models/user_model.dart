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
  
  // Profile fields
  final String? profileImageFileId;
  final String? profileImagePath;
  final String? country;
  final String? cityState;
  final String? postalCode;

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
    this.profileImageFileId,
    this.profileImagePath,
    this.country,
    this.cityState,
    this.postalCode,
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
    String? profileImageFileId,
    String? profileImagePath,
    String? country,
    String? cityState,
    String? postalCode,
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
      profileImageFileId: profileImageFileId ?? this.profileImageFileId,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      country: country ?? this.country,
      cityState: cityState ?? this.cityState,
      postalCode: postalCode ?? this.postalCode,
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

    // Helper function to handle "null" strings from API
    String? parseNullableString(dynamic value) {
      if (value == null || value == 'null') return null;
      final str = value as String?;
      return str?.trim().isEmpty == true ? null : str?.trim();
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _parseRole(json['role']),
      avatarUrl: parseNullableString(json['avatarUrl']),
      school: parseNullableString(json['school']),
      firstName: first,
      lastName: last,
      phone: parseNullableString(json['phone']),
      grade: parseNullableString(json['grade']),
      section: parseNullableString(json['section']),
      subject: parseNullableString(json['subject']),
      department: parseNullableString(json['department']),
      childName: parseNullableString(json['childName']),
      relationship: parseNullableString(json['relationship']),
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      createdAt: parseNullableString(json['createdAt']),
      updatedAt: parseNullableString(json['updatedAt']),
      profileImageFileId: parseNullableString(json['profileImageFileId']),
      profileImagePath: parseNullableString(json['profileImagePath']),
      country: parseNullableString(json['country']),
      cityState: parseNullableString(json['cityState']),
      postalCode: parseNullableString(json['postalCode']),
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
        'profileImageFileId': profileImageFileId,
        'profileImagePath': profileImagePath,
        'country': country,
        'cityState': cityState,
        'postalCode': postalCode,
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
