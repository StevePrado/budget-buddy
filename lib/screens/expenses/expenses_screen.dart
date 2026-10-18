import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/expense_categories.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../theme/app_colors.dart';
import 'add_edit_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _expenseService = ExpenseService();
  String? _filterCategory; // null = all categories
  DateTime? _filterDate;   // null = all dates

  void _openAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
    );
  }

  void _openEditExpense(ExpenseModel expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditExpenseScreen(expense: expense)),
    );
  }

  Future<void> _confirmDelete(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
            'Are you sure you want to delete "${expense.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _expenseService.deleteExpense(expense);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showFilterDialog(List<ExpenseModel> allExpenses) {
    String? tempCategory = _filterCategory;
    DateTime? tempDate = _filterDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Expenses'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: tempCategory == null,
                    onSelected: (_) =>
                        setDialogState(() => tempCategory = null),
                  ),
                  ...ExpenseCategories.all.map((cat) => ChoiceChip(
                        label: Text(cat.name),
                        selected: tempCategory == cat.name,
                        onSelected: (_) =>
                            setDialogState(() => tempCategory = cat.name),
                      )),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Date',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    tempDate != null
                        ? DateFormat('MMM dd, yyyy').format(tempDate!)
                        : 'No date filter',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => tempDate = picked);
                      }
                    },
                    child: const Text('Pick Date'),
                  ),
                  if (tempDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setDialogState(() => tempDate = null),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterCategory = null;
                  _filterDate = null;
                });
                Navigator.pop(context);
              },
              child: const Text('Clear All'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterCategory = tempCategory;
                  _filterDate = tempDate;
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  List<ExpenseModel> _applyFilters(List<ExpenseModel> all) {
    return all.where((e) {
      final categoryMatch =
          _filterCategory == null || e.category == _filterCategory;
      final dateMatch = _filterDate == null ||
          (e.date.year == _filterDate!.year &&
              e.date.month == _filterDate!.month &&
              e.date.day == _filterDate!.day);
      return categoryMatch && dateMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFilter = _filterCategory != null || _filterDate != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: hasFilter,
              child: const Icon(Icons.filter_list_rounded),
            ),
            tooltip: 'Filter',
            onPressed: () => _showFilterDialog([]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expenseService.streamExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          // Pass all to filter dialog
          final filtered = _applyFilters(all);

          if (all.isEmpty) {
            return _buildEmptyState();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('No expenses match your filter.',
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _filterCategory = null;
                      _filterDate = null;
                    }),
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final expense = filtered[index];
              return _buildExpenseTile(expense);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 80, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No expenses yet!',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Tap the button below to add your first expense.',
              style: TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(ExpenseModel expense) {
    final cat = ExpenseCategories.fromName(expense.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openEditExpense(expense),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 14),

              // Name + category + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(
                      '${expense.category} • ${DateFormat('MMM dd').format(expense.date)}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Receipt icon if has photo
              if (!kIsWeb &&
                  expense.receiptPath != null &&
                  File(expense.receiptPath!).existsSync())
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.image_outlined,
                      size: 16, color: AppColors.textMuted),
                ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.danger),
                  ),
                  const SizedBox(height: 4),
                  // Delete button
                  InkWell(
                    onTap: () => _confirmDelete(expense),
                    child: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
