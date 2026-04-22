import 'additional_income.dart';

class MonthlyBudget {
  final String monthKey; // format: yyyy-MM
  final double income; // ingreso base del mes
  final double incomeCash;
  final double incomeBank;
  final bool splitIncome;
  final List<AdditionalIncome> additionalIncomes;
  final double totalBudget;
  final bool useCategoryBudgets;
  final Map<String, double> categoryBudgets;
  final bool splitByFortnight;
  final Map<String, double> fortnightBudgets; // '1' y '2'
  final Map<String, double> categoryBudgetsF1; // presupuesto por cat — 1ª quincena
  final Map<String, double> categoryBudgetsF2; // presupuesto por cat — 2ª quincena

  MonthlyBudget({
    required this.monthKey,
    this.income = 0.0,
    this.incomeCash = 0.0,
    this.incomeBank = 0.0,
    this.splitIncome = false,
    this.additionalIncomes = const [],
    required this.totalBudget,
    this.useCategoryBudgets = false,
    this.categoryBudgets = const {},
    this.splitByFortnight = false,
    this.fortnightBudgets = const {},
    this.categoryBudgetsF1 = const {},
    this.categoryBudgetsF2 = const {},
  });

  double get totalAssigned =>
      categoryBudgets.values.fold(0.0, (s, v) => s + v);

  double get totalAdditionalIncome =>
      additionalIncomes.fold(0.0, (s, e) => s + e.amount);

  double get totalIncome => income + totalAdditionalIncome;

  Map<String, dynamic> toMap() => {
        'income': income,
        'incomeCash': incomeCash,
        'incomeBank': incomeBank,
        'splitIncome': splitIncome,
        'additionalIncomes': additionalIncomes.map((e) => e.toMap()).toList(),
        'totalBudget': totalBudget,
        'useCategoryBudgets': useCategoryBudgets,
        'categoryBudgets': categoryBudgets,
        'splitByFortnight': splitByFortnight,
        'fortnightBudgets': fortnightBudgets,
        'categoryBudgetsF1': categoryBudgetsF1,
        'categoryBudgetsF2': categoryBudgetsF2,
      };

  factory MonthlyBudget.fromMap(String monthKey, Map<String, dynamic> data) {
    return MonthlyBudget(
      monthKey: monthKey,
      income: (data['income'] as num?)?.toDouble() ?? 0.0,
      incomeCash: (data['incomeCash'] as num?)?.toDouble() ?? 0.0,
      incomeBank: (data['incomeBank'] as num?)?.toDouble() ?? 0.0,
      splitIncome: data['splitIncome'] as bool? ?? false,
      additionalIncomes: (data['additionalIncomes'] as List<dynamic>?)
              ?.map((e) =>
                  AdditionalIncome.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalBudget: (data['totalBudget'] as num?)?.toDouble() ?? 0.0,
      useCategoryBudgets: data['useCategoryBudgets'] as bool? ?? false,
      categoryBudgets:
          (data['categoryBudgets'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
              {},
      splitByFortnight: data['splitByFortnight'] as bool? ?? false,
      fortnightBudgets:
          (data['fortnightBudgets'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
              {},
      categoryBudgetsF1:
          (data['categoryBudgetsF1'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
              {},
      categoryBudgetsF2:
          (data['categoryBudgetsF2'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
              {},
    );
  }

  MonthlyBudget copyWith({
    double? income,
    double? incomeCash,
    double? incomeBank,
    bool? splitIncome,
    List<AdditionalIncome>? additionalIncomes,
    double? totalBudget,
    bool? useCategoryBudgets,
    Map<String, double>? categoryBudgets,
    bool? splitByFortnight,
    Map<String, double>? fortnightBudgets,
    Map<String, double>? categoryBudgetsF1,
    Map<String, double>? categoryBudgetsF2,
  }) {
    return MonthlyBudget(
      monthKey: monthKey,
      income: income ?? this.income,
      incomeCash: incomeCash ?? this.incomeCash,
      incomeBank: incomeBank ?? this.incomeBank,
      splitIncome: splitIncome ?? this.splitIncome,
      additionalIncomes: additionalIncomes ?? this.additionalIncomes,
      totalBudget: totalBudget ?? this.totalBudget,
      useCategoryBudgets: useCategoryBudgets ?? this.useCategoryBudgets,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      splitByFortnight: splitByFortnight ?? this.splitByFortnight,
      fortnightBudgets: fortnightBudgets ?? this.fortnightBudgets,
      categoryBudgetsF1: categoryBudgetsF1 ?? this.categoryBudgetsF1,
      categoryBudgetsF2: categoryBudgetsF2 ?? this.categoryBudgetsF2,
    );
  }
}
