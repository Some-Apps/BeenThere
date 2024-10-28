import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  AuthRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // Fetch user by ID
  Future<AppUser?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return AppUser.fromDocument(doc);
    }

    return null;
  }


  // Get the current Firebase user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Sign out user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  

  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    // Create or update user document with device settings
    await _firestore.collection('users').doc(uid).set({
      'email': email.trim(),
      'displayName': displayName.trim(),
    }, SetOptions(merge: true));
  }
}