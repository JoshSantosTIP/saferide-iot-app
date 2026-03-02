class UserProfile {
  final String uid;
  final String email;
  final String role; // "user" or "operator"
  final String? assignedJeepney;

  UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    this.assignedJeepney,
  });

  factory UserProfile.fromMap(Map<dynamic, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      assignedJeepney: map['assigned_jeepney'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'assigned_jeepney': assignedJeepney,
    };
  }

  bool get isOperator => role == 'operator';
}
