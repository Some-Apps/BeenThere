import 'package:been_there/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainPage extends ConsumerWidget {
  final Widget child;
  final String currentLocation; // Pass the location as a parameter

  const MainPage({
    super.key,
    required this.child,
    required this.currentLocation, // Initialize the location
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider); // Fetch appUser from provider
    final authViewModel = ref.read(authViewModelProvider.notifier);

    if (appUser == null) {
      authViewModel.logout(context, ref);
      return const Center(child: CircularProgressIndicator());
    }


    // Define the items and routes
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Profile'),
      BottomNavigationBarItem(icon: Icon(Icons.archive), label: 'Map'),
      BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Leaderboards'),
    ];

    const routes = ['/profile', '/map', '/leaderboards'];

    

    
    // Determine the current index based on the current location
    final currentIndex = routes.indexOf(currentLocation);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        currentIndex: currentIndex,
        onTap: (index) {
          context.go(routes[index]);
        },
        items: items,
      ),
    );
  }
}