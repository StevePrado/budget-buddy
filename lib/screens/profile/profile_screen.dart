import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';

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
      body: SingleChildScrollView(
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
                    'Active',
                    valueColor: AppColors.success,
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
            const SizedBox(height: 24),

            // Device Feature: Local Notifications Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active_outlined,
                            color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Device Feature: Notifications',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test your device local notification banner and sound.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Send Test Notification',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          await NotificationService().showTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notification sent! Check your notification bar.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () async {
                  final confirmed = await showAppConfirmDialog(
                    context: context,
                    title: 'Log out?',
                    message: 'Are you sure you want to log out?',
                    cancelText: 'Cancel',
                    confirmText: 'Log Out',
                    confirmColor: AppColors.danger,
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
