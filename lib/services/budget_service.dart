import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';

class BudgetService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Uses the logged-in user's UID, or a fallback ID for testing/offline preview
  String get currentUserId {
    try {
      return _auth.currentUser?.uid ?? 'demo_student_uid';
    } catch (_) {
      return 'demo_student_uid';
    }
  }

  // Reference to users/{uid}/budget document
  DocumentReference<Map<String, dynamic>> get _budgetDoc =>
      _firestore.collection('users').doc(currentUserId).collection('settings').doc('budget');

  // Check if a budget has been saved (doc exists in Firestore) (2.4 & 3.5)
  Future<bool> hasBudget() async {
    try {
      final doc = await _budgetDoc.get();
      return doc.exists && doc.data() != null;
    } catch (_) {
      return false;
    }
  }

  // Quick fetch of user's budget if set, or null if no budget set yet (3.5)
  Future<BudgetModel?> getBudget() async {
    try {
      final doc = await _budgetDoc.get();
      if (!doc.exists || doc.data() == null) return null;
      return BudgetModel.fromFirestore(doc, currentUserId);
    } catch (_) {
      return null;
    }
  }

  // 1. Stream the student's budget document in real time; emits null if no budget saved yet
  Stream<BudgetModel?> streamUserBudget() {
    final uid = currentUserId;
    try {
      return _budgetDoc.snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          return null;
        }
        return BudgetModel.fromFirestore(doc, uid);
      });
    } catch (_) {
      return Stream.value(null);
    }
  }

  // 2. Save or update Daily, Weekly, and Monthly budgets in Firestore
  Future<void> saveBudget({
    required double dailyBudget,
    required double weeklyBudget,
    required double monthlyBudget,
    required String selectedPeriod,
  }) async {
    final uid = currentUserId;
    final budget = BudgetModel(
      userId: uid,
      dailyBudget: dailyBudget,
      weeklyBudget: weeklyBudget,
      monthlyBudget: monthlyBudget,
      selectedPeriod: selectedPeriod,
    );

    try {
      await _budgetDoc.set(budget.toMap(), SetOptions(merge: true));
    } catch (e) {
      // Firebase save fallback for offline/test environment
    }
  }

  // 3. Update only the active budget period ('Daily', 'Weekly', 'Monthly')
  Future<void> updateSelectedPeriod(String period) async {
    final uid = currentUserId;
    try {
      await _budgetDoc.set(
        {
          'userId': uid,
          'selectedPeriod': period,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  // 4. Stream Total Expenses from the expenses subcollection
  Stream<double> streamTotalExpenses() {
    final uid = currentUserId;
    try {
      return _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
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
