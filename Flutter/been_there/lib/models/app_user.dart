import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;


  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  // Factory constructor to create AppUser from Firestore document
  factory AppUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'],
      displayName: data['displayName'],
    );
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