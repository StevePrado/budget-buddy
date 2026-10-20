import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/expenses/add_edit_expense_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_dialog.dart';

class AppDrawer extends StatelessWidget {
  /// Currently selected bottom-nav index (0=Summary,1=Expenses,2=Budget,3=Profile)
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── User Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person_rounded,
                        size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Student',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'College Student',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Navigation ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel('Navigation'),
                    _navItem(
                      context,
                      icon: Icons.pie_chart_outline_rounded,
                      activeIcon: Icons.pie_chart_rounded,
                      label: 'Summary',
                      index: 0,
                    ),
                    _navItem(
                      context,
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                      label: 'Expenses',
                      index: 1,
                    ),
                    _navItem(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      activeIcon: Icons.account_balance_wallet_rounded,
                      label: 'Budget Setup',
                      index: 2,
                    ),
                    _navItem(
                      context,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      index: 3,
                    ),

                    const SizedBox(height: 8),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 8),

                    // ── Quick Actions ─────────────────────────────────
                    _sectionLabel('Quick Actions'),
                    _actionItem(
                      context,
                      icon: Icons.add_circle_outline_rounded,
                      iconColor: AppColors.success,
                      label: 'Add Expense',
                      onTap: () async {
                        Navigator.pop(context); // close drawer
                        final hasBudget = await BudgetService().hasBudget();
                        if (!context.mounted) return;
                        if (!hasBudget) {
                          final confirmed = await showAppConfirmDialog(
                            context: context,
                            title: 'Set your budget first',
                            message:
                                'You need to set a budget before adding expenses.',
                            cancelText: 'Cancel',
                            confirmText: 'Set Budget',
                            confirmColor: AppColors.primary,
                          );
                          if (confirmed == true && context.mounted) {
                            onNavigate(2); // go to Budget tab
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showSetBudgetDialog(context);
                            });
                          }
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddEditExpenseScreen(),
                          ),
                        );
                      },
                    ),
                    _actionItem(
                      context,
                      icon: Icons.calculate_outlined,
                      iconColor: AppColors.secondary,
                      label: 'Edit Budgets',
                      onTap: () {
                        Navigator.pop(context); // close drawer
                        onNavigate(2); // go to Budget tab
                      },
                    ),

                  ],
                ),
              ),
            ),

            // ── Footer: App info + Logout ─────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      const Text(
                        'BudgetBuddy v1.0 · Student Expense Tracker',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                        foregroundColor: AppColors.danger,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: AppColors.danger.withValues(alpha: 0.4)),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context); // close drawer first
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
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(
        isActive ? activeIcon : icon,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isActive
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      onTap: () {
        Navigator.pop(context); // close drawer
        onNavigate(index);
      },
    );
  }

  Widget _actionItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
