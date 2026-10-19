import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';

class BudgetService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final StreamController<BudgetModel> _localBudgetUpdates =
      StreamController<BudgetModel>.broadcast();
  BudgetModel _localBudget = BudgetModel(
    userId: 'demo_student_uid',
    dailyBudget: 0,
    weeklyBudget: 0,
    monthlyBudget: 0,
  );

  bool get isAuthenticated {
    try {
      return _auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _localBudgetUpdates.close();
  }

  // Uses the logged-in user's UID, or a fallback ID for testing/offline preview
  String get currentUserId {
    try {
      return _auth.currentUser?.uid ?? 'demo_student_uid';
    } catch (_) {
      return 'demo_student_uid';
    }
  }

  // 1. Stream the student's budget document in real time
  Stream<BudgetModel> streamUserBudget() {
    if (!isAuthenticated) {
      return Stream<BudgetModel>.multi((controller) {
        final subscription = _localBudgetUpdates.stream.listen(
          controller.add,
          onError: (Object error, StackTrace stackTrace) {
            controller.addError(error, stackTrace);
          },
        );
        controller.add(_localBudget);
        controller.onCancel = subscription.cancel;
      });
    }

    final uid = currentUserId;
    try {
      return _firestore.collection('budgets').doc(uid).snapshots().map((doc) {
        return BudgetModel.fromFirestore(doc, uid);
      });
    } catch (_) {
      return Stream.value(
        BudgetModel(
          userId: uid,
          dailyBudget: 0,
          weeklyBudget: 0,
          monthlyBudget: 0,
        ),
      );
    }
  }

  // 2. Save or update Daily, Weekly, and Monthly budgets in Firestore
  Future<void> saveBudget({
    required double dailyBudget,
    required double weeklyBudget,
    required double monthlyBudget,
    required String selectedPeriod,
  }) async {
    if (!isAuthenticated) {
      _localBudget = BudgetModel(
        userId: currentUserId,
        dailyBudget: dailyBudget,
        weeklyBudget: weeklyBudget,
        monthlyBudget: monthlyBudget,
        selectedPeriod: selectedPeriod,
      );
      _localBudgetUpdates.add(_localBudget);
      return;
    }

    final uid = currentUserId;
    final budget = BudgetModel(
      userId: uid,
      dailyBudget: dailyBudget,
      weeklyBudget: weeklyBudget,
      monthlyBudget: monthlyBudget,
      selectedPeriod: selectedPeriod,
    );

    await _firestore
        .collection('budgets')
        .doc(uid)
        .set(budget.toMap(), SetOptions(merge: true));
  }

  // 3. Update only the active budget period ('Daily', 'Weekly', 'Monthly')
  Future<void> updateSelectedPeriod(String period) async {
    if (!isAuthenticated) {
      _localBudget = BudgetModel(
        userId: currentUserId,
        dailyBudget: _localBudget.dailyBudget,
        weeklyBudget: _localBudget.weeklyBudget,
        monthlyBudget: _localBudget.monthlyBudget,
        selectedPeriod: period,
      );
      _localBudgetUpdates.add(_localBudget);
      return;
    }

    final uid = currentUserId;
    await _firestore.collection('budgets').doc(uid).set(
      {
        'userId': uid,
        'selectedPeriod': period,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // 4. Stream Total Expenses from the 'expenses' collection for this user
  Stream<double> streamTotalExpenses() {
    if (!isAuthenticated) {
      return Stream.value(0.0);
    }

    final uid = currentUserId;
    try {
      return _firestore
          .collection('expenses')
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map((snapshot) {
        double total = 0.0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final amount = data['amount'];
          if (amount is num) {
            total += amount.toDouble();
          } else if (amount is String) {
            total += double.tryParse(amount) ?? 0.0;
          }
        }
        return total;
      });
    } catch (_) {
      return Stream.value(0.0);
    }
  }
}
