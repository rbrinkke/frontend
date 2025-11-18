import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

/// Home screen shown after successful authentication
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (user != null) ...[
                Text(
                  'Email: ${user.email}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (user.name != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Name: ${user.name}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 24),
              Text(
                'Architecture Features',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.security,
                'JWT Authentication',
                'Secure token-based auth with auto-refresh',
              ),
              _buildFeatureItem(
                Icons.cable,
                'Dio HTTP Client',
                'Production-ready with interceptors',
              ),
              _buildFeatureItem(
                Icons.stream,
                'WebSocket Ready',
                'Real-time bidirectional AI streaming',
              ),
              _buildFeatureItem(
                Icons.dashboard_customize,
                'Riverpod State',
                'Modern dependency injection',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
