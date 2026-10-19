import 'package:flutter/material.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/summary/summary_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/expenses/add_edit_expense_screen.dart';
import '../widgets/app_drawer.dart';

// Main Navigation Shell with Bottom Navigation Bar + FAB
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<Widget> _screens = [
    SummaryScreen(),
    ExpensesScreen(),
    BudgetScreen(),
    ProfileScreen(),
  ];

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      // ── Left Drawer ──────────────────────────────────────────────
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigate: (index) => setState(() => _currentIndex = index),
      ),

      // ── Body ─────────────────────────────────────────────────────
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Hamburger button pinned top-left so every screen has access
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openDrawer,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111B3A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF9AA6D1),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditExpenseScreen()),
              ),
              child: const Icon(Icons.add_rounded),
            )
          : null,

      // ── Bottom Navigation Bar ─────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
