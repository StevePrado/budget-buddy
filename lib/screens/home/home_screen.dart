import 'package:flutter/material.dart';
// 1. Import your new budget screen file
import '../budget/budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _titles = ['Expenses', 'Summary', 'Budget'];

  // 2. Replace the placeholder at index 2 with BudgetScreen()
  static const _pages = [
    Center(child: Text('Expense features will be added here.')),
    Center(child: Text('Budget summary will be added here.')),
    BudgetScreen(), // <-- Your Module B screen is plugged in here!
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BudgetBuddy — ${_titles[_selectedIndex]}')),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Budget',
          ),
        ],
      ),
    );
  }
}