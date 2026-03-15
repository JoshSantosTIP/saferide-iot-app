class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String? profilePictureUrl;
  final String role; // "user" or "operator"
  final String? assignedJeepney;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.profilePictureUrl,
    required this.role,
    this.assignedJeepney,
  });

  factory UserProfile.fromMap(Map<dynamic, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? 'Unknown User',
      profilePictureUrl: map['profile_picture'],
      role: map['role'] ?? 'user',
      assignedJeepney: map['assigned_jeepney'] ?? map['assignedJeepney'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      if (profilePictureUrl != null) 'profile_picture': profilePictureUrl,
      'role': role,
      'assigned_jeepney': assignedJeepney,
    };
  }

  bool get isOperator => role == 'operator';
}
