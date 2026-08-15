import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ProfileScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person),
          ),

          IconButton(
            onPressed: () =>
                AuthService().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: Center(
        child: Text(
          'Welcome ${user?.displayName ?? 'User'}',
          style: Theme.of(context)
              .textTheme
              .headlineSmall,
        ),
      ),
    );
  }
}