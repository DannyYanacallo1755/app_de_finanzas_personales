import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/monthly_budget.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Usamos un ID fijo de "usuario" para el desarrollo.
  // Cuando añadas autenticación real, sustitúyelo por el UID del usuario.
  static const String _userId = 'local_user';

  CollectionReference<Map<String, dynamic>> get _budgets =>
      _db.collection('users').doc(_userId).collection('budgets');

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _db.collection('users').doc(_userId).collection('expenses');

  // ─── Budgets ─────────────────────────────────────────────────────────────

  Future<MonthlyBudget?> getBudget(String monthKey) async {
    final doc = await _budgets.doc(monthKey).get();
    if (!doc.exists || doc.data() == null) return null;
    return MonthlyBudget.fromMap(monthKey, doc.data()!);
  }

  Future<void> saveBudget(MonthlyBudget budget) async {
    await _budgets.doc(budget.monthKey).set(budget.toMap());
  }

  // ─── Expenses ────────────────────────────────────────────────────────────

  Stream<List<Expense>> expensesStream(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    return _expenses
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Expense.fromDoc).toList());
  }

  Future<void> addExpense(Expense expense) async {
    await _expenses.add(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenses.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _expenses.doc(id).delete();
  }
}
