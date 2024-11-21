
import 'package:been_there/view_models/auth_view_model.dart';
import 'package:been_there/views/auth/my_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  void signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: Provider.apple,
        idToken: appleCredential.identityToken!,
        nonce: appleCredential.authorizationCode,
      );

      if (response.error == null) {
        ref.read(authViewModelProvider.notifier).setUser(response.user);
      } else {
        print("Error with Apple Sign-In: ${response.error!.message}");
      }
    } catch (e) {
      print("Error with Apple Sign-In: $e");
    }
  }

  void signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final response = await _supabaseClient.auth.signInWithIdToken(
          provider: Provider.google,
          idToken: googleAuth.idToken!,
          accessToken: googleAuth.accessToken!,
        );

        if (response.error == null) {
          ref.read(authViewModelProvider.notifier).setUser(response.user);
        } else {
          print("Error with Google Sign-In: ${response.error!.message}");
        }
      }
    } catch (e) {
      print("Error with Google Sign-In: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  MyButton(
                    title: "Sign in with Apple",
                    onTap: signInWithApple,
                  ),
                  const SizedBox(height: 10),
                  MyButton(
                    title: "Sign in with Google",
                    onTap: signInWithGoogle,
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
