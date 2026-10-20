import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final String notes;
  final String? receiptPath; // local file path only
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    this.notes = '',
    this.receiptPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      category: data['category'] ?? 'Other',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] ?? '',
      receiptPath: data['receiptPath'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'receiptPath': receiptPath,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? name,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
    String? receiptPath,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt,
    );
  }
}
