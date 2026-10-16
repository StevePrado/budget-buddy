import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String userId;
  final double dailyBudget;
  final double weeklyBudget;
  final double monthlyBudget;
  final String selectedPeriod; // 'Daily', 'Weekly', or 'Monthly'

  BudgetModel({
    required this.userId,
    required this.dailyBudget,
    required this.weeklyBudget,
    required this.monthlyBudget,
    this.selectedPeriod = 'Monthly',
  });

  // Helper to get the active Total Budget based on the selected period
  double get activeTotalBudget {
    switch (selectedPeriod) {
      case 'Daily':
        return dailyBudget;
      case 'Weekly':
        return weeklyBudget;
      case 'Monthly':
      default:
        return monthlyBudget;
    }
  }

  factory BudgetModel.fromFirestore(DocumentSnapshot doc, String fallbackUid) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return BudgetModel(
        userId: fallbackUid,
        dailyBudget: 0.0,
        weeklyBudget: 0.0,
        monthlyBudget: 0.0,
        selectedPeriod: 'Monthly',
      );
    }

    return BudgetModel(
      userId: doc.id,
      dailyBudget: (data['dailyBudget'] ?? 0.0).toDouble(),
      weeklyBudget: (data['weeklyBudget'] ?? 0.0).toDouble(),
      monthlyBudget: (data['monthlyBudget'] ?? 0.0).toDouble(),
      selectedPeriod: data['selectedPeriod'] ?? 'Monthly',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dailyBudget': dailyBudget,
      'weeklyBudget': weeklyBudget,
      'monthlyBudget': monthlyBudget,
      'selectedPeriod': selectedPeriod,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}