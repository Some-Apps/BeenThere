
import 'package:been_there/models/app_user.dart';
import 'package:been_there/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


final appUserProvider = StateProvider<AppUser?>((ref) => null);

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthViewModel(authRepository);
});

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository) : super(AuthState.loading()) {
    _checkAuthStatus();
  }
  Future<void> _checkAuthStatus() async {
    print("Checking authentication status...");
    try {
      final user = _authRepository.getCurrentUser();
      if (user != null) {
        print("User found: ${user.id}");
        final appUser = await _authRepository.getUserById(user.id);
        if (appUser != null) {
          print("AppUser found: ${appUser.id}");
          state = AuthState.authenticated(appUser);
        } else {
          print("AppUser not found, unauthenticated state.");
          state = AuthState.unauthenticated();
        }
      } else {
        print("No user found, unauthenticated state.");
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      print("Error checking auth status: ${e.toString()}");
      state = AuthState.error(e.toString());
    }
  }

  void setUser(User? user) async {
    if (user != null) {
      _authRepository.createUserDocument(
        uid: user.id,
        email: user.email ?? '',
        displayName: user.aud,
      );
      final appUser = await _authRepository.getUserById(user.id);
      if (appUser != null) {
        state = AuthState.authenticated(appUser);
      } else {
        state = AuthState.unauthenticated();
      }
    }
  }

  void resetState() {
    state = AuthState.unauthenticated();
  }



  // Logout method
  Future<void> logout(BuildContext context, WidgetRef ref) async {
    try {
      // Sign out from authentication provider (e.g., Firebase)
      await _authRepository.signOut();

      // Clear the appUserProvider (set to null)
      ref.read(appUserProvider.notifier).state = null;

      // Reset the authentication state
      state = AuthState.unauthenticated();

      // Navigate back to the login/auth page
      context.go('/');
    } catch (e) {
      // Handle any errors that occur during logout
      state = AuthState.error("Failed to log out: ${e.toString()}");
    }
  }
}

enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
  final String? loadingMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.loadingMessage,
  });

  // Convenience constructors
  factory AuthState.loading({String? message}) =>
      AuthState(status: AuthStatus.loading, loadingMessage: message);
  factory AuthState.authenticated(AppUser user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}