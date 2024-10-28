
import 'package:been_there/firebase_options.dart';
import 'package:been_there/views/auth/auth_page.dart';
import 'package:been_there/views/pages/profile_page.dart';
import 'package:been_there/views/pages/main_page.dart';
import 'package:been_there/views/pages/leaderboards_page.dart';
import 'package:been_there/views/pages/map_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(
      child: MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      themeMode: ThemeMode.system,
      // themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
    );
  }
}

final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => const MaterialPage(child: AuthPage()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainPage(
            currentLocation: state.uri.toString(),
            child: child, // Pass the current location to MainPage
          );
        },
        routes: [
          GoRoute(
            path:
                '/profile', // No need for ':id' since we're passing the object directly
            pageBuilder: (context, state) {
              return const MaterialPage(
                child: ProfilePage(),
              );
            },
          ),
          GoRoute(
            path:
                '/map', // No need for ':id' since we're passing the object directly
            pageBuilder: (context, state) {
              return const MaterialPage(
                child: MapPage(),
              );
            },
          ),
          GoRoute(
            path:
                '/leaderboards', // No need for ':id' since we're passing the object directly
            pageBuilder: (context, state) {
              return const MaterialPage(
                child: LeaderboardsPage(),
              );
            },
          ),
          
        ]
      ),
    ],
  );
  