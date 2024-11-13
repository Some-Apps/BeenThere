// main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:been_there/view_models/auth_view_model.dart';
import 'package:been_there/views/pages/profile_page.dart';
import 'package:been_there/views/pages/map_page.dart';
import 'package:been_there/views/pages/leaderboards_page.dart';



class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 1; // Default to Map tab

  final List<Widget> _pages = const [
    ProfilePage(),
    MapPage(),
    LeaderboardsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(appUserProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    if (appUser == null) {
      authViewModel.logout(context, ref);
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
      BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboards'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: items,
      ),
    );
  }
}
