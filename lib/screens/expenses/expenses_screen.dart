import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/expense_categories.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_format.dart';
import '../../widgets/confirm_dialog.dart';
import 'add_edit_expense_screen.dart';
import '../../models/budget_model.dart';
import '../../services/budget_service.dart';
import '../../utils/period_helper.dart';
import '../../widgets/budget_alert_banner.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _expenseService = ExpenseService();
  bool _isAlertDismissed = false;

  // Filters state
  String? _filterCategory; // null = "All"
  DateTimeRange? _filterDateRange; // null = no date filter

  // E3: Multi-select state
  final Set<String> _selectedExpenseIds = {};
  bool get _isSelectionMode => _selectedExpenseIds.isNotEmpty;

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
        builder: (_) => AddEditExpenseScreen(expense: expense),
      ),
    );
  }

  Future<void> _pickDateFilter() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _filterDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                surface: AppColors.surface,
                onSurface: AppColors.textPrimary,
              ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _filterDateRange = picked);
    }
  }

  // E3: Delete selected expenses with confirmation
  Future<void> _confirmDeleteSelected(List<ExpenseModel> allExpenses) async {
    final selectedExpenses = allExpenses
        .where((e) => _selectedExpenseIds.contains(e.id))
        .toList();
    if (selectedExpenses.isEmpty) return;

    final count = selectedExpenses.length;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete $count expense${count > 1 ? 's' : ''}?',
      message:
          'Are you sure you want to delete $count expense${count > 1 ? 's' : ''}? This cannot be undone.',
      cancelText: 'Cancel',
      confirmText: 'Delete',
      confirmColor: AppColors.danger,
    );

    if (confirmed == true) {
      await _expenseService.deleteMultipleExpenses(selectedExpenses);
      if (mounted) {
        setState(() => _selectedExpenseIds.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$count expense${count > 1 ? 's' : ''} deleted.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // Apply active category and date filters
  List<ExpenseModel> _applyFilters(List<ExpenseModel> all) {
    return all.where((e) {
      final categoryMatch =
          _filterCategory == null || e.category == _filterCategory;

      bool dateMatch = true;
      if (_filterDateRange != null) {
        final start = DateTime(
          _filterDateRange!.start.year,
          _filterDateRange!.start.month,
          _filterDateRange!.start.day,
        );
        final end = DateTime(
          _filterDateRange!.end.year,
          _filterDateRange!.end.month,
          _filterDateRange!.end.day,
          23,
          59,
          59,
          999,
        );
        dateMatch = !e.date.isBefore(start) && !e.date.isAfter(end);
      }

      return categoryMatch && dateMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExpenseModel>>(
      stream: _expenseService.streamExpenses(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final filtered = _applyFilters(all);

        return PopScope(
          canPop: !_isSelectionMode,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _isSelectionMode) {
              setState(() => _selectedExpenseIds.clear());
            }
          },
          child: Scaffold(
            // E3: Contextual Selection Bar or Standard App Bar
            appBar: _isSelectionMode
                ? AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () =>
                          setState(() => _selectedExpenseIds.clear()),
                    ),
                    title: Text(
                      '${_selectedExpenseIds.length} selected',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedExpenseIds.length == filtered.length) {
                              _selectedExpenseIds.clear();
                            } else {
                              _selectedExpenseIds
                                  .addAll(filtered.map((e) => e.id));
                            }
                          });
                        },
                        child: Text(
                          _selectedExpenseIds.length == filtered.length
                              ? 'Deselect all'
                              : 'Select all',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                        ),
                        tooltip: 'Delete',
                        onPressed: _selectedExpenseIds.isEmpty
                            ? null
                            : () => _confirmDeleteSelected(filtered),
                      ),
                    ],
                  )
                : AppBar(
                    title: const Text('Expenses'),
                    centerTitle: true,
                  ),

            // E1 & E3: Only ONE add button (the floating "+" button), hidden in selection mode
            floatingActionButton: _isSelectionMode
                ? null
                : FloatingActionButton(
                    onPressed: _openAddExpense,
                    child: const Icon(Icons.add_rounded),
                  ),

            body: Column(
              children: [
                // E2: Filter Area - horizontal scrollable row directly under app bar
                Container(
                  height: 48,
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Calendar Icon-Only button
                      Center(
                        child: Container(
                          height: 40,
                          width: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _filterDateRange != null
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _filterDateRange != null
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.calendar_month_rounded,
                                  size: 20,
                                  color: _filterDateRange != null
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                tooltip: 'Filter by date',
                                onPressed: _pickDateFilter,
                              ),
                              if (_filterDateRange != null)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Removable chip for active date filter
                      if (_filterDateRange != null) ...[
                        Center(
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            child: InputChip(
                              label: Text(
                                _formatDateRangeLabel(_filterDateRange!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.18),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                              onDeleted: () =>
                                  setState(() => _filterDateRange = null),
                            ),
                          ),
                        ),
                      ],

                      // "All" Category Chip
                      Center(
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All'),
                            labelStyle: TextStyle(
                              color: _filterCategory == null
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: _filterCategory == null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            selected: _filterCategory == null,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _filterCategory == null
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            onSelected: (_) =>
                                setState(() => _filterCategory = null),
                          ),
                        ),
                      ),

                      // 6 Category Chips
                      ...ExpenseCategories.all.map((cat) {
                        final isSelected = _filterCategory == cat.name;
                        return Center(
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(
                                cat.icon,
                                size: 16,
                                color: isSelected ? Colors.white : cat.color,
                              ),
                              label: Text(cat.name),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              selected: isSelected,
                              selectedColor: cat.color,
                              backgroundColor: AppColors.surfaceHigh,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? cat.color
                                      : AppColors.border,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _filterCategory = cat.name),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Over Budget Alert Banner
                if (!_isAlertDismissed)
                  StreamBuilder<BudgetModel>(
                    stream: BudgetService().streamUserBudget(),
                    builder: (context, budgetSnap) {
                      final budget = budgetSnap.data;
                      if (budget != null && budget.weeklyBudget > 0) {
                        final weeklySpent = PeriodHelper.calculatePeriodTotal(all, 'Weekly');
                        if (weeklySpent > budget.weeklyBudget) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: BudgetAlertBanner(
                              period: 'Weekly',
                              budget: budget.weeklyBudget,
                              spent: weeklySpent,
                              onDismiss: () => setState(() => _isAlertDismissed = true),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                // Main Expense List
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (all.isEmpty) {
                        return _buildEmptyState();
                      }

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No expenses match your filter.',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => setState(() {
                                  _filterCategory = null;
                                  _filterDateRange = null;
                                }),
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final expense = filtered[index];
                          final isSelected =
                              _selectedExpenseIds.contains(expense.id);

                          return _buildExpenseTile(
                            expense: expense,
                            isSelected: isSelected,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateRangeLabel(DateTimeRange range) {
    if (range.start.year == range.end.year &&
        range.start.month == range.end.month &&
        range.start.day == range.end.day) {
      return DateFormat('MMM d').format(range.start);
    }
    return '${DateFormat('MMM d').format(range.start)} - ${DateFormat('MMM d').format(range.end)}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the "+" button below to add your first expense.',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile({
    required ExpenseModel expense,
    required bool isSelected,
  }) {
    final cat = ExpenseCategories.fromName(expense.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // E3: Long-press enters multi-selection mode
        onLongPress: () {
          setState(() {
            _selectedExpenseIds.add(expense.id);
          });
        },
        // E3: Tap toggles selection in selection mode, or opens detail/edit
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedExpenseIds.remove(expense.id);
              } else {
                _selectedExpenseIds.add(expense.id);
              }
            });
          } else {
            _openEditExpense(expense);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Check icon if in selection mode
              if (_isSelectionMode) ...[
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
              ],

              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 14),

              // Name + category + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${expense.category} • ${DateFormat('MMM dd').format(expense.date)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Receipt icon if has photo (with web safety)
              if (!kIsWeb &&
                  expense.receiptPath != null &&
                  File(expense.receiptPath!).existsSync())
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.image_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),

              // 2.2 & 2.2b: Spending format (-₱X.XX) with plain white text
              Text(
                formatSpent(expense.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
