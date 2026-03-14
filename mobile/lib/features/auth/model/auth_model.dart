class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String role;
  final String fullName;
  final String email;
  final String? organizationName;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.fullName,
    required this.email,
    this.organizationName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'],
        refreshToken: json['refreshToken'],
        role: json['role'],
        fullName: json['fullName'],
        email: json['email'],
        organizationName: json['organizationName'],
      );
}
