import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final String description;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
  });

  String get monthKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'categoryId': categoryId,
        'description': description,
        'date': Timestamp.fromDate(date),
      };

  factory Expense.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      categoryId: data['categoryId'] as String? ?? 'other',
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }
}
