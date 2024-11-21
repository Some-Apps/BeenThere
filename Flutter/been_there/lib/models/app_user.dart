class AppUser {
  final String id;
  final String email;
  final String displayName;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  // Factory constructor to create AppUser from Supabase data
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'].toString(),
      email: data['email'] ?? '',
      displayName: data['display_name'] ?? '',
    );
  }

  // Convert user to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
    };
  }

  // CopyWith method to create a copy of AppUser with optional changes
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }
}