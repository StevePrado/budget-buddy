import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/expense_model.dart';

class ExpenseService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String get currentUserId =>
      _auth.currentUser?.uid ?? 'demo_student_uid';

  // Reference to this user's expenses subcollection
  CollectionReference<Map<String, dynamic>> get _expensesRef => _firestore
      .collection('users')
      .doc(currentUserId)
      .collection('expenses');

  // 1. Stream all expenses, ordered by date descending
  Stream<List<ExpenseModel>> streamExpenses() {
    return _expensesRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList());
  }

  // 2. Add a new expense
  Future<void> addExpense(ExpenseModel expense) async {
    await _expensesRef.add(expense.toMap());
  }

  // 3. Update an existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    final updateData = {
      'name': expense.name,
      'amount': expense.amount,
      'category': expense.category,
      'date': Timestamp.fromDate(expense.date),
      'notes': expense.notes,
      'receiptPath': expense.receiptPath,
    };
    await _expensesRef.doc(expense.id).update(updateData);
  }

  // 4. Delete an expense (and its local receipt image if any)
  Future<void> deleteExpense(ExpenseModel expense) async {
    // Delete local receipt file if it exists (on non-web platforms)
    if (!kIsWeb && expense.receiptPath != null) {
      final file = File(expense.receiptPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _expensesRef.doc(expense.id).delete();
  }

  // 5. Copy a picked image to the app's documents directory and return its path
  Future<String?> saveReceiptLocally(String sourcePath) async {
    if (kIsWeb) return sourcePath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
      final destPath = p.join(dir.path, 'receipts', fileName);
      await Directory(p.dirname(destPath)).create(recursive: true);
      final savedFile = await File(sourcePath).copy(destPath);
      return savedFile.path;
    } catch (_) {
      return null;
    }
  }

  // 6. Stream total expenses for budget summary
  Stream<double> streamTotalExpenses() {
    return streamExpenses().map(
      (list) => list.fold(0.0, (total, e) => total + e.amount),
    );
  }
}
