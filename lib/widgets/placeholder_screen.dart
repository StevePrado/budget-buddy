import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Placeholder screen widget for group tabs
// Teammates: Swap your actual screen widget inside main_shell.dart when your feature is ready!
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String owner;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.owner,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Coming soon: $owner',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
