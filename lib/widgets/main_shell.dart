import 'package:flutter/material.dart';
import '../screens/budget/budget_screen.dart';
import 'placeholder_screen.dart';

// Main Navigation Shell with Bottom Navigation Bar
// Teammates: Swap your screen in the _screens list below when your module is ready!
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // List of screens for each tab on the bottom navigation bar
  // Teammates: Replace PlaceholderScreen with your real screen widget here!
  final List<Widget> _screens = const [
    // 1. Expenses tab (Add, List, Filter, Receipts)
    PlaceholderScreen(
      title: 'Expenses',
      icon: Icons.receipt_long_rounded,
      owner: 'Teammates (Expense Module)',
    ),

    // 2. Budget tab (Daily, Weekly, Monthly budget allowances)
    BudgetScreen(),

    // 3. Summary & Analytics tab (Charts & Budget breakdown)
    PlaceholderScreen(
      title: 'Summary',
      icon: Icons.pie_chart_rounded,
      owner: 'Teammates (Analytics & Charts)',
    ),

    // 4. Profile & Auth tab (Account settings & Logout)
    PlaceholderScreen(
      title: 'Profile',
      icon: Icons.person_rounded,
      owner: 'Teammates (Firebase Auth & Profile)',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body displays current selected screen
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Bottom Navigation Bar to switch between screens
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          // Navigation item 1: Expenses
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),

          // Navigation item 2: Budget
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budget',
          ),

          // Navigation item 3: Summary
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Summary',
          ),

          // Navigation item 4: Profile
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
