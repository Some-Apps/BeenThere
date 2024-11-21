import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository({
    SupabaseClient? supabaseClient,
  }) : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  // Fetch user by ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return AppUser.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // Get the current Supabase user
  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }

  // Sign out user
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    // Create or update user document with device settings
    final response = await _supabaseClient.from('users').upsert({
      'id': uid,
      'email': email.trim(),
      'displayName': displayName.trim(),
    });

    if (response.error != null) {
      throw response.error!;
    }
  }
}