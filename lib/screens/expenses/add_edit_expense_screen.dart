import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../constants/expense_categories.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_format.dart';
import '../../widgets/confirm_dialog.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense; // null = Add mode, non-null = Edit mode

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _expenseService = ExpenseService();
  final _imagePicker = ImagePicker();

  String _selectedCategory = ExpenseCategories.food.name;
  DateTime _selectedDate = DateTime.now();
  String? _receiptPath;
  bool _isSaving = false;

  // Initial values to detect unsaved changes (1.2)
  late final String _initialName;
  late final String _initialAmount;
  late final String _initialNotes;
  late final String _initialCategory;
  late final DateTime _initialDate;
  late final String? _initialReceiptPath;

  bool get _isEditing => widget.expense != null;

  bool get _hasUnsavedChanges {
    if (_nameController.text.trim() != _initialName) return true;
    if (_amountController.text.trim() != _initialAmount) return true;
    if (_notesController.text.trim() != _initialNotes) return true;
    if (_selectedCategory != _initialCategory) return true;
    if (_selectedDate.year != _initialDate.year ||
        _selectedDate.month != _initialDate.month ||
        _selectedDate.day != _initialDate.day) {
      return true;
    }
    if (_receiptPath != _initialReceiptPath) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.expense!;
      _initialName = e.name;
      _initialAmount = formatAmountForInput(e.amount);
      _initialNotes = e.notes;
      _initialCategory = e.category;
      _initialDate = e.date;
      _initialReceiptPath = e.receiptPath;

      _nameController.text = _initialName;
      _amountController.text = _initialAmount;
      _notesController.text = _initialNotes;
      _selectedCategory = _initialCategory;
      _selectedDate = _initialDate;
      _receiptPath = _initialReceiptPath;
    } else {
      _initialName = '';
      _initialAmount = '';
      _initialNotes = '';
      _initialCategory = ExpenseCategories.food.name;
      _initialDate = DateTime.now();
      _initialReceiptPath = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Pick receipt photo from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null) return;
    final savedPath = await _expenseService.saveReceiptLocally(picked.path);
    if (savedPath != null) {
      setState(() => _receiptPath = savedPath);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: const Text(
                'Take a Photo',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.secondary),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_receiptPath != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text(
                  'Remove Receipt',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _receiptPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _handleBackPress() async {
    if (!_hasUnsavedChanges || _isSaving) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showAppConfirmDialog(
      context: context,
      title: 'Discard changes?',
      message:
          'You have unsaved changes. Do you want to discard them or continue editing?',
      cancelText: 'Keep Editing',
      confirmText: 'Discard',
      isDiscardMode: true,
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final parsedAmount = parsePeso(_amountController.text);
      if (parsedAmount == null || parsedAmount <= 0) {
        throw Exception('Please enter a valid amount.');
      }

      // 1.1 Auto-name: if empty, defaults to selected category name
      final trimmedName = _nameController.text.trim();
      final finalName = trimmedName.isEmpty ? _selectedCategory : trimmedName;

      final expense = ExpenseModel(
        id: _isEditing ? widget.expense!.id : '',
        userId: _expenseService.currentUserId,
        name: finalName,
        amount: parsedAmount,
        category: _selectedCategory,
        date: _selectedDate,
        notes: _notesController.text.trim(),
        receiptPath: _receiptPath,
      );

      if (_isEditing) {
        await _expenseService.updateExpense(expense);
      } else {
        await _expenseService.addExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Expense updated!'
                : 'Expense added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1.2: Discard confirmation with PopScope
    return PopScope(
      canPop: !_hasUnsavedChanges || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackPress,
          ),
          title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
          centerTitle: true,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1.1: Expense Name (Optional, defaults to category name)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Name',
                        hintText: 'Optional (defaults to category name)',
                        prefixIcon: Icon(
                          Icons.label_outline,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // Not required anymore per 1.1
                    ),
                    const SizedBox(height: 14),

                    // Amount field with peso prefix and comma formatter
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: const [CommaNumberInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Amount (₱)',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            '₱',
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter amount';
                        final parsed = parsePeso(v);
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid positive amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown (Required)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      dropdownColor: AppColors.surface,
                      items: ExpenseCategories.all
                          .map((cat) => DropdownMenuItem(
                                value: cat.name,
                                child: Row(
                                  children: [
                                    Icon(cat.icon, color: cat.color, size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      cat.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedCategory = v);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date Picker
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        child: Text(
                          DateFormat('MMMM dd, yyyy').format(_selectedDate),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes field
                    TextFormField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        alignLabelWithHint: true,
                        prefixIcon: Align(
                          alignment: Alignment.topCenter,
                          widthFactor: 1,
                          heightFactor: 1,
                          child: Padding(
                            padding: EdgeInsets.only(top: 14),
                            child: Icon(
                              Icons.notes_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Receipt Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Receipt Photo',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showImageSourceSheet,
                          icon: Icon(
                            _receiptPath != null
                                ? Icons.edit_outlined
                                : Icons.add_a_photo_outlined,
                            size: 18,
                          ),
                          label:
                              Text(_receiptPath != null ? 'Change' : 'Add Photo'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_receiptPath != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: (!kIsWeb && File(_receiptPath!).existsSync())
                            ? Image.file(
                                File(_receiptPath!),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 80,
                                color: AppColors.surfaceHigh,
                                alignment: Alignment.center,
                                child: Text(
                                  kIsWeb
                                      ? 'Receipt stored locally (Mobile feature)'
                                      : 'Receipt file not found',
                                  style:
                                      const TextStyle(color: AppColors.textMuted),
                                ),
                              ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Save Changes' : 'Add Expense',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
