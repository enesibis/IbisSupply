class UserResponse {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? organizationName;
  final bool active;
  final String createdAt;

  UserResponse({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.organizationName,
    required this.active,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
        id: json['id'] ?? '',
        fullName: json['fullName'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'],
        role: json['role'] ?? '',
        organizationName: json['organizationName'],
        active: json['active'] ?? true,
        createdAt: json['createdAt'] ?? '',
      );
}
