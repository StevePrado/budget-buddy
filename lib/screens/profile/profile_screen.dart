import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.person_rounded,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 16),

            // Email
            Text(
              user?.email ?? 'Student',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'College Student',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),

            // Account Info Card
            Card(
              child: Column(
                children: [
                  _infoTile(
                    Icons.email_outlined,
                    'Email',
                    user?.email ?? '—',
                  ),
                  const Divider(height: 1, indent: 60),
                  _infoTile(
                    Icons.perm_identity_outlined,
                    'User ID',
                    user?.uid != null
                        ? '${user!.uid.substring(0, 8)}...'
                        : '—',
                  ),
                  const Divider(height: 1, indent: 60),
                  _infoTile(
                    Icons.verified_user_outlined,
                    'Account Status',
                    user?.emailVerified == true
                        ? 'Verified'
                        : 'Not Verified',
                    valueColor: user?.emailVerified == true
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // App Info Card
            Card(
              child: Column(
                children: [
                  _infoTile(Icons.info_outline, 'App', 'BudgetBuddy v1.0'),
                  const Divider(height: 1, indent: 60),
                  _infoTile(Icons.school_outlined, 'Purpose',
                      'Student Expense Tracker'),
                  const Divider(height: 1, indent: 60),
                  _infoTile(Icons.storage_outlined, 'Data Storage',
                      'Firebase Firestore'),
                ],
              ),
            ),

            const Spacer(),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text(
                          'Are you sure you want to log out of BudgetBuddy?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await authService.logout();
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {Color? valueColor}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
      subtitle: Text(value,
          style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14)),
    );
  }
}
