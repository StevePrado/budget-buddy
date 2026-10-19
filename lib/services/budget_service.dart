import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';

/// How much the student has spent today, this week and this month.
class PeriodSpending {
  const PeriodSpending({
    required this.daily,
    required this.weekly,
    required this.monthly,
  });

  static const zero = PeriodSpending(daily: 0, weekly: 0, monthly: 0);

  final double daily;
  final double weekly;
  final double monthly;

  double forPeriod(String period) {
    switch (period) {
      case 'Daily':
        return daily;
      case 'Weekly':
        return weekly;
      default:
        return monthly;
    }
  }
}

class BudgetService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'demo_student_uid';

  // Budget limits: users/{uid}/settings/budget
  DocumentReference<Map<String, dynamic>> get _budgetRef =>
      _db.collection('users').doc(currentUserId).collection('settings').doc('budget');

  // Expenses written by the Expenses module: users/{uid}/expenses
  CollectionReference<Map<String, dynamic>> get _expensesRef =>
      _db.collection('users').doc(currentUserId).collection('expenses');

  /// Live budget limits for the signed-in user.
  Stream<BudgetModel> streamUserBudget() {
    final uid = currentUserId;
    return _budgetRef
        .snapshots()
        .map((doc) => BudgetModel.fromFirestore(doc, uid));
  }

  /// Live spending totals, worked out from the expense documents.
  /// Weeks start on Monday; expenses dated in the future are ignored.
  Stream<PeriodSpending> streamSpending() {
    return _expensesRef.snapshots().map((snapshot) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = DateTime(now.year, now.month, now.day + 1);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      double day = 0, week = 0, month = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawAmount = data['amount'];
        final amount = rawAmount is num
            ? rawAmount.toDouble()
            : double.tryParse('$rawAmount') ?? 0.0;
        final rawDate = data['date'];
        if (rawDate is! Timestamp) continue;
        final date = rawDate.toDate();
        if (!date.isBefore(tomorrowStart)) continue;

        if (!date.isBefore(monthStart)) month += amount;
        if (!date.isBefore(weekStart)) week += amount;
        if (!date.isBefore(todayStart)) day += amount;
      }
      return PeriodSpending(daily: day, weekly: week, monthly: month);
    });
  }

  /// Saves all three limits. Errors are thrown so the screen can show them.
  Future<void> saveBudget({
    required double dailyBudget,
    required double weeklyBudget,
    required double monthlyBudget,
    required String selectedPeriod,
  }) {
    final budget = BudgetModel(
      userId: currentUserId,
      dailyBudget: dailyBudget,
      weeklyBudget: weeklyBudget,
      monthlyBudget: monthlyBudget,
      selectedPeriod: selectedPeriod,
    );
    return _budgetRef.set(budget.toMap(), SetOptions(merge: true));
  }

  /// Remembers which period the student last looked at.
  Future<void> updateSelectedPeriod(String period) {
    return _budgetRef.set(
      {
        'userId': currentUserId,
        'selectedPeriod': period,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
