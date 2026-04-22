import 'dart:async';
import 'package:flutter/material.dart';
import '../models/additional_income.dart';
import '../models/expense.dart';
import '../models/monthly_budget.dart';
import '../services/firestore_service.dart';

class AppProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  DateTime _selectedMonth = DateTime.now();
  MonthlyBudget? _budget;
  List<Expense> _expenses = [];
  bool _loading = true;
  StreamSubscription<List<Expense>>? _expensesSub;

  DateTime get selectedMonth => _selectedMonth;
  MonthlyBudget? get budget => _budget;
  List<Expense> get expenses => _expenses;
  bool get loading => _loading;

  String get monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  // ─── Income ───────────────────────────────────────────────────────────────

  double get income => _budget?.income ?? 0.0;
  double get incomeCash => _budget?.incomeCash ?? 0.0;
  double get incomeBank => _budget?.incomeBank ?? 0.0;
  bool get splitIncome {
    try {
      return _budget?.splitIncome ?? false;
    } catch (_) {
      return false;
    }
  }

  List<AdditionalIncome> get additionalIncomes {
    try {
      return _budget?.additionalIncomes ?? [];
    } catch (_) {
      return [];
    }
  }

  double get totalAdditionalIncome =>
      additionalIncomes.fold(0.0, (s, e) => s + e.amount);
  double get totalIncome => income + totalAdditionalIncome;

  /// Dinero libre después de gastos vs ingreso
  double get incomeRemaining => totalIncome - totalSpent;

  // ─── Totals ──────────────────────────────────────────────────────────────

  double get totalSpent =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get totalBudget => _budget?.totalBudget ?? 0.0;

  /// Positivo = queda presupuesto. Negativo = pasado de presupuesto.
  double get remaining => totalBudget - totalSpent;

  bool get isOverBudget => remaining < 0;

  double get progressRatio =>
      totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

  // ─── Per category ────────────────────────────────────────────────────────

  double spentByCategory(String categoryId) =>
      _expenses
          .where((e) => e.categoryId == categoryId)
          .fold(0.0, (s, e) => s + e.amount);

  double budgetForCategory(String categoryId) =>
      _budget?.categoryBudgets[categoryId] ?? 0.0;

  /// Presupuesto de categoría para una quincena concreta.
  /// Si no hay valores por quincena, reparte el total a la mitad.
  double categoryBudgetF(String categoryId, int fortnight) {
    if (fortnight == 1) {
      final v = _budget?.categoryBudgetsF1[categoryId] ?? 0.0;
      if (v > 0) return v;
    } else {
      final v = _budget?.categoryBudgetsF2[categoryId] ?? 0.0;
      if (v > 0) return v;
    }
    // Fallback: mitad del presupuesto total de la categoría
    return budgetForCategory(categoryId) / 2;
  }

  double remainingForCategory(String categoryId) =>
      budgetForCategory(categoryId) - spentByCategory(categoryId);

  double categoryProgressRatio(String categoryId) {
    final b = budgetForCategory(categoryId);
    if (b <= 0) return 0.0;
    return (spentByCategory(categoryId) / b).clamp(0.0, 1.0);
  }

  // ─── Quincenas ───────────────────────────────────────────────────────────

  bool get splitByFortnight {
    try {
      return _budget?.splitByFortnight ?? false;
    } catch (_) {
      return false;
    }
  }

  double fortnightSpent(int f) => _expenses
      .where((e) => f == 1 ? e.date.day <= 15 : e.date.day > 15)
      .fold(0.0, (s, e) => s + e.amount);

  double spentByCategoryInFortnight(String categoryId, int f) => _expenses
      .where((e) =>
          e.categoryId == categoryId &&
          (f == 1 ? e.date.day <= 15 : e.date.day > 15))
      .fold(0.0, (s, e) => s + e.amount);

  double fortnightBudget(int f) {
    try {
      return _budget?.fortnightBudgets[f.toString()] ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  double fortnightRemaining(int f) => fortnightBudget(f) - fortnightSpent(f);

  double fortnightProgressRatio(int f) {
    final b = fortnightBudget(f);
    if (b <= 0) return 0.0;
    return (fortnightSpent(f) / b).clamp(0.0, 1.0);
  }

  // ─── Init & Load ─────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadMonth();
  }

  Future<void> _loadMonth() async {
    _loading = true;
    notifyListeners();

    _budget = await _service.getBudget(monthKey);
    _loading = false;
    notifyListeners();

    await _expensesSub?.cancel();
    _expensesSub = _service.expensesStream(monthKey).listen((list) {
      _expenses = list;
      notifyListeners();
    });
  }

  Future<void> changeMonth(DateTime month) async {
    _selectedMonth = month;
    await _loadMonth();
  }

  // ─── Budget ───────────────────────────────────────────────────────────────

  Future<void> saveBudget(MonthlyBudget budget) async {
    await _service.saveBudget(budget);
    _budget = budget;
    notifyListeners();
  }

  // ─── Expenses ────────────────────────────────────────────────────────────

  Future<void> addExpense(Expense expense) async {
    await _service.addExpense(expense);
  }

  Future<void> updateExpense(Expense expense) async {
    await _service.updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _service.deleteExpense(id);
  }

  @override
  void dispose() {
    _expensesSub?.cancel();
    super.dispose();
  }
}
