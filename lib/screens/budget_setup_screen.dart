import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/additional_income.dart';
import '../models/category.dart';
import '../models/monthly_budget.dart';
import '../theme/app_theme.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Ingresos
  final _incomeController = TextEditingController();
  final _incomeCashController = TextEditingController();
  final _incomeBankController = TextEditingController();
  bool _splitIncome = false;
  final List<_AdditionalIncomeRow> _additionalRows = [];

  // Presupuesto
  final _totalController = TextEditingController();
  bool _useCategoryBudgets = false;
  final Map<String, TextEditingController> _catControllers = {};
  final Map<String, TextEditingController> _catF1Controllers = {};
  final Map<String, TextEditingController> _catF2Controllers = {};
  bool _splitByFortnight = false;
  final _fortnight1Controller = TextEditingController();
  final _fortnight2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    for (final cat in Category.defaults) {
      _catControllers[cat.id] = TextEditingController();
      _catF1Controllers[cat.id] = TextEditingController();
      _catF2Controllers[cat.id] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final b = context.read<AppProvider>().budget;
      if (b != null) {
        _incomeController.text = b.income > 0 ? b.income.toStringAsFixed(2) : '';
        _incomeCashController.text = b.incomeCash > 0 ? b.incomeCash.toStringAsFixed(2) : '';
        _incomeBankController.text = b.incomeBank > 0 ? b.incomeBank.toStringAsFixed(2) : '';
        _splitIncome = b.splitIncome;
        _totalController.text = b.totalBudget > 0 ? b.totalBudget.toStringAsFixed(2) : '';
        _useCategoryBudgets = b.useCategoryBudgets;
        _splitByFortnight = b.splitByFortnight;
        _fortnight1Controller.text = (b.fortnightBudgets['1'] ?? 0) > 0 ? b.fortnightBudgets['1']!.toStringAsFixed(2) : '';
        _fortnight2Controller.text = (b.fortnightBudgets['2'] ?? 0) > 0 ? b.fortnightBudgets['2']!.toStringAsFixed(2) : '';
        for (final e in b.categoryBudgets.entries) {
          _catControllers[e.key]?.text = e.value > 0 ? e.value.toStringAsFixed(2) : '';
        }
        for (final e in b.categoryBudgetsF1.entries) {
          _catF1Controllers[e.key]?.text = e.value > 0 ? e.value.toStringAsFixed(2) : '';
        }
        for (final e in b.categoryBudgetsF2.entries) {
          _catF2Controllers[e.key]?.text = e.value > 0 ? e.value.toStringAsFixed(2) : '';
        }
        for (final ai in b.additionalIncomes) {
          final labelCtrl = TextEditingController(text: ai.label);
          final amountCtrl = TextEditingController(text: ai.amount > 0 ? ai.amount.toStringAsFixed(2) : '');
          labelCtrl.addListener(() => setState(() {}));
          amountCtrl.addListener(() => setState(() {}));
          _additionalRows.add(_AdditionalIncomeRow(id: ai.id, label: labelCtrl, amount: amountCtrl));
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomeController.dispose();
    _incomeCashController.dispose();
    _incomeBankController.dispose();
    _totalController.dispose();
    _fortnight1Controller.dispose();
    _fortnight2Controller.dispose();
    for (final c in _catControllers.values) c.dispose();
    for (final c in _catF1Controllers.values) c.dispose();
    for (final c in _catF2Controllers.values) c.dispose();
    for (final r in _additionalRows) { r.label.dispose(); r.amount.dispose(); }
    super.dispose();
  }

  double _parse(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.')) ?? 0.0;
  double get _sumCategories => _catControllers.values.fold(0.0, (s, c) => s + _parse(c));
  double get _sumAdditional => _additionalRows.fold(0.0, (s, r) => s + _parse(r.amount));
  double get _totalIncomeSummary => _parse(_incomeController) + _sumAdditional;

  void _addAdditionalRow() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    labelCtrl.addListener(() => setState(() {}));
    amountCtrl.addListener(() => setState(() {}));
    setState(() => _additionalRows.add(_AdditionalIncomeRow(id: id, label: labelCtrl, amount: amountCtrl)));
  }

  void _removeAdditionalRow(String id) => setState(() => _additionalRows.removeWhere((r) => r.id == id));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final catBudgets = <String, double>{};
    final catBudgetsF1 = <String, double>{};
    final catBudgetsF2 = <String, double>{};
    if (_useCategoryBudgets) {
      for (final cat in Category.defaults) {
        if (_splitByFortnight) {
          // Guarda los valores por quincena
          final v1 = _parse(_catF1Controllers[cat.id]!);
          final v2 = _parse(_catF2Controllers[cat.id]!);
          if (v1 > 0) catBudgetsF1[cat.id] = v1;
          if (v2 > 0) catBudgetsF2[cat.id] = v2;
          // El total de la cat es la suma de ambas quincenas
          if (v1 + v2 > 0) catBudgets[cat.id] = v1 + v2;
        } else {
          final v = _parse(_catControllers[cat.id]!);
          if (v > 0) catBudgets[cat.id] = v;
        }
      }
    }
    final fortnightBudgets = <String, double>{};
    if (_splitByFortnight) {
      final f1 = _parse(_fortnight1Controller);
      final f2 = _parse(_fortnight2Controller);
      if (f1 > 0) fortnightBudgets['1'] = f1;
      if (f2 > 0) fortnightBudgets['2'] = f2;
    }
    final additionalIncomes = _additionalRows
        .where((r) => r.label.text.trim().isNotEmpty)
        .map((r) => AdditionalIncome(id: r.id, label: r.label.text.trim(), amount: _parse(r.amount)))
        .toList();
    final provider = context.read<AppProvider>();
    await provider.saveBudget(MonthlyBudget(
      monthKey: provider.monthKey,
      income: _parse(_incomeController),
      incomeCash: _splitIncome ? _parse(_incomeCashController) : 0,
      incomeBank: _splitIncome ? _parse(_incomeBankController) : 0,
      splitIncome: _splitIncome,
      additionalIncomes: additionalIncomes,
      totalBudget: _parse(_totalController),
      useCategoryBudgets: _useCategoryBudgets,
      categoryBudgets: catBudgets,
      splitByFortnight: _splitByFortnight,
      fortnightBudgets: fortnightBudgets,
      categoryBudgetsF1: catBudgetsF1,
      categoryBudgetsF2: catBudgetsF2,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Guardar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configurar mes',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text('Toca Guardar cuando termines',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.normal)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.trending_up_rounded, size: 20),
                    text: 'Ingresos',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: Icon(Icons.donut_large_rounded, size: 20),
                    text: 'Presupuesto',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _IncomesTab(
              incomeCtrl: _incomeController,
              cashCtrl: _incomeCashController,
              bankCtrl: _incomeBankController,
              splitIncome: _splitIncome,
              onSplitChanged: (v) => setState(() => _splitIncome = v),
              additionalRows: _additionalRows,
              onAdd: _addAdditionalRow,
              onRemove: _removeAdditionalRow,
              onChanged: () => setState(() {}),
              parse: _parse,
              sumAdditional: _sumAdditional,
              totalIncome: _totalIncomeSummary,
            ),
            _BudgetTab(
              totalCtrl: _totalController,
              splitByFortnight: _splitByFortnight,
              onFortnightChanged: (v) => setState(() => _splitByFortnight = v),
              fortnight1Ctrl: _fortnight1Controller,
              fortnight2Ctrl: _fortnight2Controller,
              useCategoryBudgets: _useCategoryBudgets,
              onCategoryChanged: (v) => setState(() => _useCategoryBudgets = v),
              catControllers: _catControllers,
              catF1Controllers: _catF1Controllers,
              catF2Controllers: _catF2Controllers,
              onChanged: () => setState(() {}),
              parse: _parse,
              sumCategories: _sumCategories,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — INGRESOS
// ══════════════════════════════════════════════════════════════════════════════

class _IncomesTab extends StatelessWidget {
  final TextEditingController incomeCtrl;
  final TextEditingController cashCtrl;
  final TextEditingController bankCtrl;
  final bool splitIncome;
  final ValueChanged<bool> onSplitChanged;
  final List<_AdditionalIncomeRow> additionalRows;
  final VoidCallback onAdd;
  final void Function(String) onRemove;
  final VoidCallback onChanged;
  final double Function(TextEditingController) parse;
  final double sumAdditional;
  final double totalIncome;

  const _IncomesTab({
    required this.incomeCtrl,
    required this.cashCtrl,
    required this.bankCtrl,
    required this.splitIncome,
    required this.onSplitChanged,
    required this.additionalRows,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    required this.parse,
    required this.sumAdditional,
    required this.totalIncome,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _CardSection(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Ingreso base',
          subtitle: 'Tu sueldo o ingreso principal del mes',
          color: AppTheme.income,
          child: Column(
            children: [
              _BigAmountField(
                controller: incomeCtrl,
                hint: '0,00',
                color: AppTheme.income,
                label: 'Importe mensual',
                onChanged: (_) => onChanged(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Introduce los ingresos';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _ToggleRow(
                value: splitIncome,
                onChanged: onSplitChanged,
                icon: Icons.compare_arrows_rounded,
                label: 'Separar efectivo / banco',
              ),
              if (splitIncome) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _SmallAmountField(controller: cashCtrl, label: 'Efectivo', icon: Icons.payments_rounded, color: AppTheme.cash, onChanged: (_) => onChanged())),
                    const SizedBox(width: 12),
                    Expanded(child: _SmallAmountField(controller: bankCtrl, label: 'Banco', icon: Icons.account_balance_rounded, color: AppTheme.bank, onChanged: (_) => onChanged())),
                  ],
                ),
                const SizedBox(height: 10),
                _SplitSumIndicator(cash: parse(cashCtrl), bank: parse(bankCtrl), total: parse(incomeCtrl)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CardSection(
          icon: Icons.add_circle_rounded,
          title: 'Ingresos adicionales',
          subtitle: 'Freelance, alquileres, sueldo extra…',
          color: AppTheme.income,
          trailing: _AddButton(onPressed: onAdd),
          child: Column(
            children: [
              if (additionalRows.isEmpty)
                const _EmptyHint(text: 'Pulsa + para añadir otra fuente de ingresos')
              else
                ...additionalRows.map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AdditionalIncomeField(row: row, onRemove: () => onRemove(row.id), onChanged: onChanged),
                    )),
              if (totalIncome > 0) ...[
                if (additionalRows.isNotEmpty) const SizedBox(height: 6),
                _TotalRow(label: 'Total ingresos del mes', amount: totalIncome, color: AppTheme.income),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — PRESUPUESTO
// ══════════════════════════════════════════════════════════════════════════════

class _BudgetTab extends StatelessWidget {
  final TextEditingController totalCtrl;
  final bool splitByFortnight;
  final ValueChanged<bool> onFortnightChanged;
  final TextEditingController fortnight1Ctrl;
  final TextEditingController fortnight2Ctrl;
  final bool useCategoryBudgets;
  final ValueChanged<bool> onCategoryChanged;
  final Map<String, TextEditingController> catControllers;
  final Map<String, TextEditingController> catF1Controllers;
  final Map<String, TextEditingController> catF2Controllers;
  final VoidCallback onChanged;
  final double Function(TextEditingController) parse;
  final double sumCategories;

  const _BudgetTab({
    required this.totalCtrl,
    required this.splitByFortnight,
    required this.onFortnightChanged,
    required this.fortnight1Ctrl,
    required this.fortnight2Ctrl,
    required this.useCategoryBudgets,
    required this.onCategoryChanged,
    required this.catControllers,
    required this.catF1Controllers,
    required this.catF2Controllers,
    required this.onChanged,
    required this.parse,
    required this.sumCategories,
  });

  @override
  Widget build(BuildContext context) {
    final total = parse(totalCtrl);
    final sumCatsF = splitByFortnight
        ? catF1Controllers.values.fold(0.0, (s, c) => s + parse(c)) +
            catF2Controllers.values.fold(0.0, (s, c) => s + parse(c))
        : sumCategories;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
      children: [
        // ── Presupuesto total ─────────────────────────────────────────
        const _MiniLabel('PRESUPUESTO MENSUAL'),
        const SizedBox(height: 10),
        _BigAmountField(
          controller: totalCtrl,
          hint: '0,00',
          color: AppTheme.primary,
          label: '',
          onChanged: (_) => onChanged(),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Introduce el presupuesto';
            final n = double.tryParse(v.replaceAll(',', '.'));
            if (n == null || n <= 0) return 'Importe inválido';
            return null;
          },
        ),
        const SizedBox(height: 30),

        // ── Opciones ──────────────────────────────────────────────────
        const _MiniLabel('OPCIONES'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _CompactToggleRow(
                icon: Icons.calendar_view_week_rounded,
                label: 'Dividir en quincenas',
                sublabel: 'Días 1–15 y 16–fin del mes',
                value: splitByFortnight,
                onChanged: onFortnightChanged,
                color: AppTheme.primaryGlow,
                isFirst: true,
              ),
              if (splitByFortnight) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: _FortnightField(controller: fortnight1Ctrl, label: '1ª quincena', sublabel: 'Días 1 – 15', color: AppTheme.primary, onChanged: (_) => onChanged())),
                      const SizedBox(width: 10),
                      Expanded(child: _FortnightField(controller: fortnight2Ctrl, label: '2ª quincena', sublabel: 'Días 16 – fin', color: AppTheme.primaryGlow, onChanged: (_) => onChanged())),
                    ]),
                    const SizedBox(height: 10),
                    _BudgetSumIndicator(assigned: parse(fortnight1Ctrl) + parse(fortnight2Ctrl), total: total, label: 'Quincenas'),
                  ]),
                ),
              ],
              Divider(color: AppTheme.border.withOpacity(0.5), height: 1, indent: 16, endIndent: 16),
              _CompactToggleRow(
                icon: Icons.pie_chart_rounded,
                label: 'Límites por categoría',
                sublabel: splitByFortnight ? 'Por categoría y quincena' : 'Máximo por cada categoría',
                value: useCategoryBudgets,
                onChanged: onCategoryChanged,
                color: AppTheme.primary,
                isFirst: false,
              ),
            ],
          ),
        ),

        // ── Categorías ────────────────────────────────────────────────
        if (useCategoryBudgets) ...[
          const SizedBox(height: 28),
          const _MiniLabel('CATEGORÍAS'),
          const SizedBox(height: 12),
          _CategoryCarouselSection(
            catControllers: catControllers,
            catF1Controllers: catF1Controllers,
            catF2Controllers: catF2Controllers,
            splitByFortnight: splitByFortnight,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          _BudgetSumIndicator(assigned: sumCatsF, total: total, label: 'Categorías'),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPONENTES
// ══════════════════════════════════════════════════════════════════════════════

class _CardSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;
  final Widget? trailing;

  const _CardSection({required this.icon, required this.title, required this.subtitle, required this.color, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppTheme.border, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BigAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color color;
  final String label;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const _BigAmountField({required this.controller, required this.hint, required this.color, required this.label, this.onChanged, this.validator});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold),
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: color.withOpacity(0.25), fontSize: 28, fontWeight: FontWeight.bold),
          prefixText: r'$ ',
          prefixStyle: TextStyle(color: color.withOpacity(0.5), fontSize: 20, fontWeight: FontWeight.bold),
          suffixText: label,
          suffixStyle: TextStyle(color: color.withOpacity(0.4), fontSize: 12),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _SmallAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<String>? onChanged;

  const _SmallAmountField({required this.controller, required this.label, required this.icon, required this.color, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0,00',
              hintStyle: TextStyle(color: color.withOpacity(0.3), fontSize: 18),
              prefixText: r'$ ',
              prefixStyle: TextStyle(color: color.withOpacity(0.5), fontSize: 14),
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _FortnightField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String sublabel;
  final Color color;
  final ValueChanged<String>? onChanged;

  const _FortnightField({required this.controller, required this.label, required this.sublabel, required this.color, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(sublabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0,00',
              hintStyle: TextStyle(color: color.withOpacity(0.3), fontSize: 20),
              prefixText: r'$ ',
              prefixStyle: TextStyle(color: color.withOpacity(0.5), fontSize: 15),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final String label;

  const _ToggleRow({required this.value, required this.onChanged, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.income),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppTheme.income.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.add_rounded, color: AppTheme.income, size: 20),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary, size: 15),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _TotalRow({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.functions_rounded, color: color, size: 15),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          Text(AppTheme.formatCurrency(amount), style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AdditionalIncomeRow {
  final String id;
  final TextEditingController label;
  final TextEditingController amount;
  _AdditionalIncomeRow({required this.id, required this.label, required this.amount});
}

class _AdditionalIncomeField extends StatelessWidget {
  final _AdditionalIncomeRow row;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _AdditionalIncomeField({required this.row, required this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.income.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money_rounded, color: AppTheme.income, size: 17),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                hintText: 'Concepto (ej: Freelance, Alquiler…)',
                hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: TextField(
              controller: row.amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.income, fontWeight: FontWeight.bold, fontSize: 14),
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: '0,00',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                prefixText: r'$ ',
                prefixStyle: TextStyle(color: AppTheme.income, fontWeight: FontWeight.bold),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _SplitSumIndicator extends StatelessWidget {
  final double cash;
  final double bank;
  final double total;
  const _SplitSumIndicator({required this.cash, required this.bank, required this.total});

  @override
  Widget build(BuildContext context) {
    final sum = cash + bank;
    final diff = total - sum;
    final isOver = diff < -0.01;
    return _StatusRow(
      isOk: !isOver,
      message: isOver
          ? 'Excede el total en ${AppTheme.formatCurrency(diff.abs())}'
          : diff.abs() < 0.01 ? 'Reparto perfecto ✓' : '${AppTheme.formatCurrency(diff)} sin asignar',
      color: isOver ? AppTheme.danger : AppTheme.success,
    );
  }
}

class _BudgetSumIndicator extends StatelessWidget {
  final double assigned;
  final double total;
  final String label;
  const _BudgetSumIndicator({required this.assigned, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    final diff = total - assigned;
    final isOver = diff < -0.01;
    return _StatusRow(
      isOk: !isOver,
      message: isOver
          ? '$label excede en ${AppTheme.formatCurrency(diff.abs())}'
          : diff.abs() < 0.01 ? '$label: reparto perfecto ✓' : '$label: ${AppTheme.formatCurrency(diff)} sin asignar',
      color: isOver ? AppTheme.danger : AppTheme.success,
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool isOk;
  final String message;
  final Color color;
  const _StatusRow({required this.isOk, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: color, size: 15),
          const SizedBox(width: 8),
          Text(message, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Label de sección minimalista ─────────────────────────────────────────────

class _MiniLabel extends StatelessWidget {
  final String text;
  const _MiniLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ── Toggle compacto (quincenas / categorías) ──────────────────────────────────

class _CompactToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;
  final bool isFirst;

  const _CompactToggleRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
    required this.color,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 14, 12, value ? 10 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(sublabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ],
      ),
    );
  }
}

// ── Carrusel de categorías (chips de selección + cards) ───────────────────────

class _CategoryCarouselSection extends StatefulWidget {
  final Map<String, TextEditingController> catControllers;
  final Map<String, TextEditingController> catF1Controllers;
  final Map<String, TextEditingController> catF2Controllers;
  final bool splitByFortnight;
  final VoidCallback onChanged;

  const _CategoryCarouselSection({
    required this.catControllers,
    required this.catF1Controllers,
    required this.catF2Controllers,
    required this.splitByFortnight,
    required this.onChanged,
  });

  @override
  State<_CategoryCarouselSection> createState() => _CategoryCarouselSectionState();
}

class _CategoryCarouselSectionState extends State<_CategoryCarouselSection> {
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    // Pre-seleccionar categorías que ya tienen valor guardado
    for (final cat in Category.defaults) {
      final v  = double.tryParse(widget.catControllers[cat.id]?.text.replaceAll(',', '.') ?? '') ?? 0;
      final v1 = double.tryParse(widget.catF1Controllers[cat.id]?.text.replaceAll(',', '.') ?? '') ?? 0;
      final v2 = double.tryParse(widget.catF2Controllers[cat.id]?.text.replaceAll(',', '.') ?? '') ?? 0;
      if (v > 0 || v1 > 0 || v2 > 0) _selected.add(cat.id);
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        widget.catControllers[id]?.clear();
        widget.catF1Controllers[id]?.clear();
        widget.catF2Controllers[id]?.clear();
        widget.onChanged();
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unselected = Category.defaults.where((c) => !_selected.contains(c.id)).toList();
    final selected   = Category.defaults.where((c) =>  _selected.contains(c.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chips: categorías disponibles para añadir ─────────────────
        if (unselected.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: unselected.map((cat) => GestureDetector(
              onTap: () => _toggle(cat.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cat.color.withOpacity(0.22)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(cat.icon, color: cat.color.withOpacity(0.7), size: 13),
                  const SizedBox(width: 5),
                  Text(cat.name, style: TextStyle(color: cat.color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 5),
                  Icon(Icons.add_rounded, color: cat.color.withOpacity(0.45), size: 12),
                ]),
              ),
            )).toList(),
          ),

        if (unselected.isNotEmpty) const SizedBox(height: 16),

        // ── Pista / carrusel de cards seleccionadas ───────────────────
        if (selected.isEmpty)
          Row(children: [
            const Icon(Icons.touch_app_rounded, color: AppTheme.textSecondary, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Text('Toca una categoría para asignarle un límite',
                style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.65), fontSize: 12))),
          ])
        else
          SizedBox(
            height: widget.splitByFortnight ? 148 : 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: selected.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final cat = selected[i];
                return _CategoryCarouselCard(
                  cat: cat,
                  controller: widget.catControllers[cat.id]!,
                  f1Controller: widget.catF1Controllers[cat.id],
                  f2Controller: widget.catF2Controllers[cat.id],
                  splitByFortnight: widget.splitByFortnight,
                  onChanged: widget.onChanged,
                  onRemove: () => _toggle(cat.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CategoryCarouselCard extends StatelessWidget {
  final Category cat;
  final TextEditingController controller;
  final TextEditingController? f1Controller;
  final TextEditingController? f2Controller;
  final bool splitByFortnight;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _CategoryCarouselCard({
    required this.cat,
    required this.controller,
    required this.f1Controller,
    required this.f2Controller,
    required this.splitByFortnight,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cat.color.withOpacity(0.18), cat.color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cat.color.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono + X
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cat.icon, color: cat.color, size: 15),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 15),
            ),
          ]),
          const SizedBox(height: 7),
          // Nombre
          Text(cat.name,
              style: TextStyle(color: cat.color.withOpacity(0.75), fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          // Campos de importe
          if (splitByFortnight && f1Controller != null && f2Controller != null) ...[
            _MiniFortnightInput(controller: f1Controller!, color: AppTheme.primary, hint: '1ª', onChanged: onChanged),
            const SizedBox(height: 5),
            _MiniFortnightInput(controller: f2Controller!, color: AppTheme.primaryGlow, hint: '2ª', onChanged: onChanged),
          ] else
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: cat.color, fontWeight: FontWeight.bold, fontSize: 20),
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: cat.color.withOpacity(0.25), fontSize: 20),
                prefixText: r'$',
                prefixStyle: TextStyle(color: cat.color.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.bold),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniFortnightInput extends StatelessWidget {
  final TextEditingController controller;
  final Color color;
  final String hint;
  final VoidCallback onChanged;

  const _MiniFortnightInput({required this.controller, required this.color, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(hint, style: TextStyle(color: color.withOpacity(0.55), fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(width: 5),
      Expanded(
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          onChanged: (_) => onChanged(),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: color.withOpacity(0.25), fontSize: 13),
            prefixText: r'$',
            prefixStyle: TextStyle(color: color.withOpacity(0.4), fontSize: 11),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    ]);
  }
}
