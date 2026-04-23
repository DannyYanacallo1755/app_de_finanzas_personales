import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_tile.dart';
import 'add_expense_screen.dart';
import 'budget_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _goToHistory() => setState(() => _tabIndex = 1);
  void _goToHome() => setState(() => _tabIndex = 0);
  void _openMenu() => _scaffoldKey.currentState?.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: true,
      endDrawer: _AppDrawer(
        onHistory: () {
          Navigator.pop(context);
          _goToHistory();
        },
        onSettings: (ctx) {
          Navigator.pop(context);
          Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const BudgetSetupScreen()));
        },
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _DashboardTab(onShowHistory: _goToHistory, onOpenMenu: _openMenu),
          _HistoryTab(onBack: _goToHome),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        backgroundColor: const Color(0xFFFF6B6B),
        elevation: 6,
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final VoidCallback onShowHistory;
  final VoidCallback onOpenMenu;
  const _DashboardTab({required this.onShowHistory, required this.onOpenMenu});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.background,
          automaticallyImplyLeading: false,
          title: _MonthPicker(provider: p),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: AppTheme.textSecondary),
              onPressed: onOpenMenu,
            ),
          ],
        ),
        if (p.loading)
          const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
          )
        else
          SliverList(
            delegate: SliverChildListDelegate([
              // ── Hero ──────────────────────────────────────────────────
              _HeroSection(provider: p),

              // ── Category bar chart ────────────────────────────────────
              if (p.budget?.useCategoryBudgets == true &&
                  p.budget!.categoryBudgets.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Por categorías',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                _CategoryBarChart(provider: p),
              ] else if (p.totalSpent > 0) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gastos del mes',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                      Text('por categoría',
                          style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SpendingBreakdown(provider: p),
              ],

              // ── Actividad del mes ─────────────────────────────────────
              if (p.totalSpent > 0) ...[
                const SizedBox(height: 32),
                _DailyActivity(provider: p),
              ],

              // ── Gastos recientes ───────────────────────────────────────
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gastos recientes',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    if (p.expenses.isNotEmpty)
                      TextButton(
                        onPressed: onShowHistory,
                        style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Ver todos',
                            style: TextStyle(
                                color: AppTheme.primary, fontSize: 13)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _RecentExpenses(provider: p),
              const SizedBox(height: 120),
            ]),
          ),
      ],
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final AppProvider provider;
  const _HeroSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalIncome = provider.totalIncome;
    final spent = provider.totalSpent;
    final incomeRemaining = totalIncome - spent;         // ← el gran número: baja al gastar
    final hasBudget = provider.totalBudget > 0;
    final byFortnight = provider.splitByFortnight;
    final additionalCount = provider.additionalIncomes.length;

    // Quincena activa
    final int activeFortnight = DateTime.now().day <= 15 ? 1 : 2;
    final fSpent = byFortnight ? provider.fortnightSpent(activeFortnight) : spent;
    final fBudget = byFortnight ? provider.fortnightBudget(activeFortnight) : provider.totalBudget;
    final fRemaining = byFortnight ? provider.fortnightRemaining(activeFortnight) : provider.remaining;
    final fRatio = byFortnight ? provider.fortnightProgressRatio(activeFortnight) : provider.progressRatio;
    final fIsOver = fRemaining < 0;   // excedió el presupuesto

    // Color del presupuesto (solo afecta la sección de presupuesto, no el número grande)
    final Color budgetColor = fIsOver
        ? AppTheme.danger
        : fBudget > 0 && fRemaining / fBudget < 0.2
            ? AppTheme.warning
            : AppTheme.primary;

    final Color barColor = fIsOver
        ? AppTheme.danger
        : fRatio > 0.8
            ? AppTheme.warning
            : AppTheme.primary;

    // Color del número grande: basado en si el ingreso disponible es positivo o no
    final bool incomeIsNegative = incomeRemaining < 0;
    final Color incomeColor = incomeIsNegative ? AppTheme.danger : AppTheme.income;

    String budgetLabel;
    if (byFortnight) {
      final fn = activeFortnight == 1 ? '1ª quincena' : '2ª quincena';
      budgetLabel = fIsOver ? 'PRESUPUESTO EXCEDIDO · $fn' : 'PRESUPUESTO · $fn';
    } else {
      budgetLabel = fIsOver ? 'PRESUPUESTO EXCEDIDO' : 'PRESUPUESTO';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Etiqueta superior ──────────────────────────────────────────
          Text(
            'INGRESO DISPONIBLE',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),

          // ── Número grande = ingreso - gastado (baja al gastar) ────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalIncome > 0
                    ? '${incomeIsNegative ? '-' : ''}${AppTheme.formatCurrency(incomeRemaining.abs())}'
                    : '—',
                style: TextStyle(
                  color: incomeColor,
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -2,
                ),
              ),
              if (additionalCount > 0) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.income.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$additionalCount extra',
                      style: TextStyle(
                        color: AppTheme.income.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // ── Referencia: ingreso total + gastado ────────────────────────
          if (totalIncome > 0 && spent > 0) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'de ${AppTheme.formatCurrency(totalIncome)}',
                  style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.55), fontSize: 12),
                ),
                Container(width: 3, height: 3, decoration: BoxDecoration(color: AppTheme.border, shape: BoxShape.circle)),
                Text(
                  '-${AppTheme.formatCurrency(spent)} gastado',
                  style: TextStyle(color: AppTheme.danger.withOpacity(0.65), fontSize: 12),
                ),
              ],
            ),
          ],

          // ── Sección presupuesto (separada, independiente) ─────────────
          if (hasBudget) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: AppTheme.border),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budgetLabel,
                        style: TextStyle(
                          color: budgetColor.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (fIsOver)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 18),
                            ),
                          Text(
                            '${fIsOver ? '-' : ''}${AppTheme.formatCurrency(fRemaining.abs())}',
                            style: TextStyle(
                              color: budgetColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BudgetSetupScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(children: [
                      Icon(Icons.edit_rounded, color: AppTheme.primary, size: 13),
                      SizedBox(width: 5),
                      Text('Configurar',
                          style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),

            // ── Barra de progreso del presupuesto ─────────────────────
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: fRatio.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(fRatio * 100).clamp(0, 999).toStringAsFixed(0)}% gastado · ${AppTheme.formatCurrency(fSpent)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(
                  'límite ${AppTheme.formatCurrency(fBudget)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),

            // ── Pills ─────────────────────────────────────────────────
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _InfoPill(
                    icon: Icons.remove_circle_outline_rounded,
                    label: byFortnight
                        ? 'Gastado ${activeFortnight == 1 ? '(1-15)' : '(16-fin)'}'
                        : 'Gastado',
                    value: AppTheme.formatCurrency(fSpent),
                    color: AppTheme.danger,
                  ),
                  const SizedBox(width: 8),
                  _InfoPill(
                    icon: Icons.account_balance_wallet_rounded,
                    label: byFortnight ? 'Presup. quincena' : 'Presupuesto',
                    value: AppTheme.formatCurrency(fBudget),
                    color: AppTheme.primary,
                  ),
                  if (byFortnight) ...[
                    const SizedBox(width: 8),
                    _InfoPill(
                      icon: Icons.calendar_today_rounded,
                      label: 'Total gastado mes',
                      value: AppTheme.formatCurrency(spent),
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Sin presupuesto: sólo botón configurar
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BudgetSetupScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded,
                        color: AppTheme.primary, size: 13),
                    SizedBox(width: 6),
                    Text('Configurar presupuesto',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color.withOpacity(0.65), fontSize: 9)),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Category Bar Chart ───────────────────────────────────────────────────────

class _CategoryBarChart extends StatelessWidget {
  final AppProvider provider;
  const _CategoryBarChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cats = Category.defaults
        .where((c) => provider.budget!.categoryBudgets.containsKey(c.id))
        .toList();

    const barMaxH = 180.0;
    const barWidth = 70.0;

    return SizedBox(
      height: barMaxH + 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final budget = provider.budgetForCategory(cat.id);
          final spent = provider.spentByCategory(cat.id);
          final ratio =
              budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
          final isOver = budget > 0 && spent > budget;
          final pct = budget > 0
              ? '${(spent / budget * 100).toStringAsFixed(0)}%'
              : '—';
          final fillH = ratio * barMaxH;

          final Color barColor = isOver
              ? AppTheme.danger
              : ratio > 0.8
                  ? AppTheme.warning
                  : cat.color;

          return SizedBox(
            width: barWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  budget > 0 ? AppTheme.formatCurrencyCompact(budget) : '',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned.fill(
                        child: _DashedBar(color: cat.color.withOpacity(0.25)),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        width: barWidth,
                        height: fillH.clamp(0, barMaxH),
                        decoration: BoxDecoration(
                          color: barColor.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppTheme.background.withOpacity(0.75),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cat.icon, color: barColor, size: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppTheme.formatCurrencyCompact(spent),
                  style: TextStyle(
                    color: isOver ? AppTheme.danger : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pct,
                  style: TextStyle(
                    color: isOver ? AppTheme.danger : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cat.name,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashedBar extends StatelessWidget {
  final Color color;
  const _DashedBar({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedRectPainter(color: color));
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashLen = 5.0;
    const gapLen = 4.0;
    const r = 12.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(r)));

    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final len = draw ? dashLen : gapLen;
        if (draw) canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}

// ─── Spending Breakdown (carrusel por categoría sin límites) ──────────────────

class _SpendingBreakdown extends StatelessWidget {
  final AppProvider provider;
  const _SpendingBreakdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    // Solo categorías con gasto > 0
    final cats = Category.defaults
        .where((c) => provider.spentByCategory(c.id) > 0)
        .toList()
      ..sort((a, b) => provider.spentByCategory(b.id)
          .compareTo(provider.spentByCategory(a.id)));

    if (cats.isEmpty) return const SizedBox.shrink();

    final total = provider.totalSpent;

    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        clipBehavior: Clip.none,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final spent = provider.spentByCategory(cat.id);
          final pct = total > 0 ? (spent / total * 100) : 0.0;
          final barRatio = (pct / 100).clamp(0.0, 1.0);

          return Container(
            width: 112,
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cat.color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + %
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: TextStyle(color: cat.color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ]),
                const Spacer(),
                // Importe gastado
                Text(
                  AppTheme.formatCurrencyCompact(spent),
                  style: TextStyle(color: cat.color, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                Text(cat.name,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 7),
                // Mini barra de proporción
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barRatio,
                    minHeight: 3,
                    backgroundColor: cat.color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(cat.color.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Recent Expenses ──────────────────────────────────────────────────────────

class _RecentExpenses extends StatelessWidget {
  final AppProvider provider;
  const _RecentExpenses({required this.provider});

  @override
  Widget build(BuildContext context) {
    final expenses = provider.expenses.take(5).toList();

    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 48, color: AppTheme.surface),
              const SizedBox(height: 12),
              const Text('Sin gastos este mes',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: expenses
            .map((e) => ExpenseTile(
                  expense: e,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddExpenseScreen(existing: e)),
                  ),
                  onDelete: () => provider.deleteExpense(e.id),
                ))
            .toList(),
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final VoidCallback onBack;
  const _HistoryTab({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    final Map<String, List<dynamic>> grouped = {};
    for (final e in p.expenses) {
      grouped.putIfAbsent(AppTheme.formatDate(e.date), () => []).add(e);
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textSecondary, size: 18),
            onPressed: onBack,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Historial',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold)),
              Text(AppTheme.formatMonth(p.selectedMonth),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        if (p.loading)
          const SliverFillRemaining(
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primary)))
        else if (p.expenses.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 64, color: AppTheme.surface),
                  const SizedBox(height: 16),
                  const Text('Sin gastos este mes',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final entries = grouped.entries.toList();
                final entry = entries[i];
                final dayTotal = entry.value
                    .fold(0.0, (s, e) => s + (e.amount as double));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text('-${AppTheme.formatCurrency(dayTotal)}',
                              style: const TextStyle(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: entry.value
                            .map((e) => ExpenseTile(
                                  expense: e,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            AddExpenseScreen(existing: e)),
                                  ),
                                  onDelete: () => p.deleteExpense(e.id),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
              childCount: grouped.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─── Daily Activity ───────────────────────────────────────────────────────────

class _DailyActivity extends StatelessWidget {
  final AppProvider provider;
  const _DailyActivity({required this.provider});

  @override
  Widget build(BuildContext context) {
    final expenses = provider.expenses;
    if (expenses.isEmpty) return const SizedBox.shrink();

    final Map<int, double> byDay = {};
    for (final e in expenses) {
      byDay[e.date.day] = (byDay[e.date.day] ?? 0) + e.amount;
    }
    final maxAmount = byDay.values.reduce(math.max);
    final month = provider.selectedMonth;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateTime.now();
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Actividad del mes',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              Text(
                '${byDay.length} días con gasto',
                style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.6),
                    fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _DayHeatmap(
            byDay: byDay,
            expenses: expenses,
            daysInMonth: daysInMonth,
            maxAmount: maxAmount,
            month: month,
            isCurrentMonth: isCurrentMonth,
            todayDay: today.day,
          ),
        ),
      ],
    );
  }
}

// ─── Day Heatmap ──────────────────────────────────────────────────────────────

class _DayHeatmap extends StatelessWidget {
  final Map<int, double> byDay;
  final List<Expense> expenses;
  final int daysInMonth;
  final double maxAmount;
  final DateTime month;
  final bool isCurrentMonth;
  final int todayDay;

  const _DayHeatmap({
    required this.byDay,
    required this.expenses,
    required this.daysInMonth,
    required this.maxAmount,
    required this.month,
    required this.isCurrentMonth,
    required this.todayDay,
  });

  @override
  Widget build(BuildContext context) {
    const weekLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final offset = DateTime(month.year, month.month, 1).weekday - 1;
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: weekLabels
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.35),
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        for (int row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (col) {
                final idx = row * 7 + col;
                final day = idx - offset + 1;

                if (day < 1 || day > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final isFuture = isCurrentMonth && day > todayDay;
                final isToday = isCurrentMonth && day == todayDay;
                final amount = byDay[day] ?? 0.0;
                final intensity =
                    maxAmount > 0 ? (amount / maxAmount) : 0.0;
                final hasExpenses = amount > 0;

                Color bgColor;
                Color textColor;
                if (isFuture) {
                  bgColor = Colors.transparent;
                  textColor = AppTheme.textSecondary.withOpacity(0.18);
                } else if (hasExpenses) {
                  bgColor =
                      AppTheme.primary.withOpacity(0.12 + 0.65 * intensity);
                  textColor =
                      Colors.white.withOpacity(0.5 + 0.5 * intensity);
                } else {
                  bgColor = AppTheme.surface.withOpacity(0.45);
                  textColor = AppTheme.textSecondary.withOpacity(0.3);
                }

                final date = DateTime(month.year, month.month, day);
                final dayExpenses =
                    expenses.where((e) => e.date.day == day).toList();

                return Expanded(
                  child: _BounceCell(
                    onTap: hasExpenses && !isFuture
                        ? () => _DayDetailSheet.show(
                            context, date, dayExpenses)
                        : null,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(7),
                          border: isToday
                              ? Border.all(
                                  color: AppTheme.primary.withOpacity(0.8),
                                  width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              fontWeight: hasExpenses
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

// ─── Bounce Cell ──────────────────────────────────────────────────────────────

class _BounceCell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _BounceCell({required this.child, this.onTap});

  @override
  State<_BounceCell> createState() => _BounceCellState();
}

class _BounceCellState extends State<_BounceCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.72)
      .chain(CurveTween(curve: Curves.easeOut))
      .animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap!();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─── Day Detail Sheet ─────────────────────────────────────────────────────────

class _DayDetailSheet extends StatefulWidget {
  final DateTime date;
  final List<Expense> expenses;

  const _DayDetailSheet({required this.date, required this.expenses});

  static void show(
      BuildContext context, DateTime date, List<Expense> expenses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _DayDetailSheet(date: date, expenses: expenses),
    );
  }

  @override
  State<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<_DayDetailSheet>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final AnimationController _staggerCtrl;
  late final Animation<Offset> _slideAnim;

  static const _wd = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _mo = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOut)));

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(
              begin: const Offset(0, 0.25), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _staggerCtrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic)));

  @override
  Widget build(BuildContext context) {
    final expenses = List<Expense>.from(widget.expenses)
      ..sort((a, b) => a.date.compareTo(b.date));
    final total = expenses.fold(0.0, (s, e) => s + e.amount);
    final dateLabel =
        '${_wd[widget.date.weekday - 1]}, ${widget.date.day} de ${_mo[widget.date.month - 1]}';

    // ── Por categoría ──────────────────────────────────────────────────
    final Map<String, double> byCategory = {};
    for (final e in expenses) {
      byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
    }
    final catEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dominantCat = catEntries.isNotEmpty
        ? Category.defaults.firstWhere((c) => c.id == catEntries.first.key,
            orElse: () => Category.defaults.last)
        : null;

    // ── Por franja horaria ─────────────────────────────────────────────
    final slots = {
      'morning':   _SlotData('Mañana',    '6–12h',  Icons.wb_sunny_rounded,    const Color(0xFFFDCB6E)),
      'afternoon': _SlotData('Tarde',     '12–18h', Icons.wb_cloudy_rounded,   const Color(0xFF74B9FF)),
      'evening':   _SlotData('Noche',     '18–22h', Icons.nights_stay_rounded, AppTheme.primary),
      'night':     _SlotData('Madrugada', '0–6h',   Icons.bedtime_rounded,     const Color(0xFF6C5CE7)),
    };
    for (final e in expenses) {
      final h = e.date.hour;
      final key = (h >= 6 && h < 12) ? 'morning'
          : (h >= 12 && h < 18) ? 'afternoon'
          : (h >= 18 && h < 22) ? 'evening'
          : 'night';
      slots[key]!.amount += e.amount;
      slots[key]!.count++;
    }
    final orderedSlots = ['morning', 'afternoon', 'evening', 'night']
        .map((k) => slots[k]!)
        .toList();

    return SlideTransition(
      position: _slideAnim,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────────────────
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header ────────────────────────────────────────
                      FadeTransition(
                        opacity: _fade(0.0, 0.35),
                        child: SlideTransition(
                          position: _slide(0.0, 0.35),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dateLabel,
                                        style: TextStyle(
                                            color: AppTheme.textSecondary
                                                .withOpacity(0.55),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3)),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppTheme.formatCurrency(total),
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -2),
                                    ),
                                    Text(
                                      '${expenses.length} ${expenses.length == 1 ? 'gasto' : 'gastos'}',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary
                                              .withOpacity(0.45),
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              // Dominant category badge
                              if (dominantCat != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: dominantCat.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: dominantCat.color
                                            .withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(dominantCat.icon,
                                          color: dominantCat.color, size: 22),
                                      const SizedBox(height: 4),
                                      Text(dominantCat.name,
                                          style: TextStyle(
                                              color: dominantCat.color,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Stacked category bar + legend ─────────────────
                      FadeTransition(
                        opacity: _fade(0.08, 0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 8,
                                child: Row(
                                  children: catEntries
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final i = entry.key;
                                    final e = entry.value;
                                    final cat =
                                        Category.defaults.firstWhere(
                                            (c) => c.id == e.key,
                                            orElse: () =>
                                                Category.defaults.last);
                                    final flex = ((e.value / total) * 1000)
                                        .round()
                                        .clamp(1, 1000);
                                    return Expanded(
                                      flex: flex,
                                      child: Container(
                                        color: cat.color.withOpacity(
                                            i == 0
                                                ? 0.9
                                                : (0.65 - i * 0.07)
                                                    .clamp(0.15, 0.65)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: catEntries.map((entry) {
                                  final cat = Category.defaults.firstWhere(
                                      (c) => c.id == entry.key,
                                      orElse: () => Category.defaults.last);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 14),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                              color: cat.color,
                                              shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(cat.name,
                                            style: TextStyle(
                                                color: AppTheme.textSecondary
                                                    .withOpacity(0.55),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Por categoría ─────────────────────────────────
                      FadeTransition(
                        opacity: _fade(0.18, 0.52),
                        child: SlideTransition(
                          position: _slide(0.18, 0.52),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('POR CATEGORÍA',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary
                                          .withOpacity(0.4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4)),
                              const SizedBox(height: 10),
                              ...catEntries.map((entry) {
                                final cat = Category.defaults.firstWhere(
                                    (c) => c.id == entry.key,
                                    orElse: () => Category.defaults.last);
                                final pct =
                                    total > 0 ? entry.value / total : 0.0;
                                final pctLabel =
                                    '${(pct * 100).toStringAsFixed(0)}%';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface.withOpacity(0.28),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border(
                                      left: BorderSide(
                                          color: cat.color, width: 3),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 11, 12, 11),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: cat.color.withOpacity(0.13),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(cat.icon,
                                              color: cat.color, size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(cat.name,
                                                  style: const TextStyle(
                                                      color:
                                                          AppTheme.textPrimary,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              const SizedBox(height: 5),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                child: LinearProgressIndicator(
                                                  value: pct,
                                                  minHeight: 3,
                                                  backgroundColor: cat.color
                                                      .withOpacity(0.1),
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                          cat.color.withOpacity(
                                                              0.65)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              AppTheme.formatCurrency(
                                                  entry.value),
                                              style: TextStyle(
                                                  color: cat.color,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 3),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color:
                                                    cat.color.withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(pctLabel,
                                                  style: TextStyle(
                                                      color: cat.color
                                                          .withOpacity(0.8),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      // ── Cuándo gastaste ───────────────────────────────
                      FadeTransition(
                        opacity: _fade(0.32, 0.62),
                        child: SlideTransition(
                          position: _slide(0.32, 0.62),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text('CUÁNDO GASTASTE',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary
                                          .withOpacity(0.4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4)),
                              const SizedBox(height: 12),
                              LayoutBuilder(builder: (ctx, constraints) {
                                final w = (constraints.maxWidth - 8) / 2;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: orderedSlots
                                      .map((s) => SizedBox(
                                          width: w,
                                          child: _TimeSlotCard(
                                              slot: s, total: total)))
                                      .toList(),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      // ── Detalle / Timeline ────────────────────────────
                      FadeTransition(
                        opacity: _fade(0.48, 0.9),
                        child: SlideTransition(
                          position: _slide(0.48, 0.9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text('DETALLE',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary
                                          .withOpacity(0.4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4)),
                              const SizedBox(height: 12),
                              ...expenses.asMap().entries.map((entry) {
                                final i = entry.key;
                                final e = entry.value;
                                final cat = Category.defaults.firstWhere(
                                    (c) => c.id == e.categoryId,
                                    orElse: () => Category.defaults.last);
                                final h = e.date.hour
                                    .toString()
                                    .padLeft(2, '0');
                                final m = e.date.minute
                                    .toString()
                                    .padLeft(2, '0');
                                return _TimelineRow(
                                  time: '$h:$m',
                                  cat: cat,
                                  expense: e,
                                  isLast: i == expenses.length - 1,
                                );
                              }),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Slot Data ────────────────────────────────────────────────────────────────

class _SlotData {
  final String label;
  final String range;
  final IconData icon;
  final Color color;
  double amount = 0;
  int count = 0;
  _SlotData(this.label, this.range, this.icon, this.color);
}

// ─── Time Slot Card ───────────────────────────────────────────────────────────

class _TimeSlotCard extends StatelessWidget {
  final _SlotData slot;
  final double total;
  const _TimeSlotCard({required this.slot, required this.total});

  @override
  Widget build(BuildContext context) {
    final active = slot.amount > 0;
    final ratio = total > 0 ? slot.amount / total : 0.0;
    final c = slot.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? c.withOpacity(0.08) : AppTheme.surface.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? c.withOpacity(0.22) : AppTheme.border.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: active
                      ? c.withOpacity(0.14)
                      : AppTheme.surface.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(slot.icon,
                    color: active ? c : AppTheme.textSecondary.withOpacity(0.25),
                    size: 15),
              ),
              const Spacer(),
              if (active)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${slot.count} ${slot.count == 1 ? 'gasto' : 'gastos'}',
                    style: TextStyle(
                        color: c.withOpacity(0.75),
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(slot.label,
              style: TextStyle(
                  color: active
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary.withOpacity(0.3),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text(slot.range,
              style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.35),
                  fontSize: 10)),
          const SizedBox(height: 10),
          Text(
            active ? AppTheme.formatCurrency(slot.amount) : '—',
            style: TextStyle(
                color: active ? c : AppTheme.textSecondary.withOpacity(0.2),
                fontSize: active ? 17 : 15,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 3,
              backgroundColor: c.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                  active ? c.withOpacity(0.6) : Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline Row ─────────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  final String time;
  final Category cat;
  final Expense expense;
  final bool isLast;

  const _TimelineRow({
    required this.time,
    required this.cat,
    required this.expense,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(time,
                  style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 6),
          // Dot + vertical line
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: cat.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: cat.color.withOpacity(0.45),
                        blurRadius: 5,
                        spreadRadius: 1),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppTheme.border.withOpacity(0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Expense card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(13),
                  border:
                      Border.all(color: cat.color.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.description.isNotEmpty
                                ? expense.description
                                : cat.name,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(cat.name,
                              style: TextStyle(
                                  color: cat.color.withOpacity(0.55),
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppTheme.formatCurrency(expense.amount),
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─── Month Picker ─────────────────────────────────────────────────────────────

// ─── App Drawer ───────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final VoidCallback onHistory;
  final void Function(BuildContext ctx) onSettings;

  const _AppDrawer({required this.onHistory, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Drawer(
      width: 280,
      backgroundColor: AppTheme.cardBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(height: 14),
                  const Text('Contador',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(AppTheme.formatMonth(p.selectedMonth),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Container(height: 1, color: AppTheme.border),
            const SizedBox(height: 8),

            // ── Items ────────────────────────────────────────────────────
            _DrawerItem(
              icon: Icons.history_rounded,
              label: 'Historial',
              onTap: onHistory,
            ),
            _DrawerItem(
              icon: Icons.tune_rounded,
              label: 'Configuración',
              onTap: () => onSettings(context),
            ),

            const Spacer(),

            // ── Footer: resumen rápido ────────────────────────────────────
            if (p.totalIncome > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen del mes',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 10),
                      _DrawerStat('Ingresos',
                          AppTheme.formatCurrency(p.totalIncome),
                          AppTheme.income),
                      const SizedBox(height: 6),
                      _DrawerStat('Gastado',
                          AppTheme.formatCurrency(p.totalSpent),
                          AppTheme.danger),
                      if (p.totalBudget > 0) ...[
                        const SizedBox(height: 6),
                        _DrawerStat(
                            p.isOverBudget ? 'Excedido' : 'Disponible',
                            AppTheme.formatCurrency(p.remaining.abs()),
                            p.isOverBudget
                                ? AppTheme.danger
                                : AppTheme.primary),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class _DrawerStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DrawerStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ─── Month Picker ─────────────────────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  final AppProvider provider;
  const _MonthPicker({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              final prev = DateTime(provider.selectedMonth.year,
                  provider.selectedMonth.month - 1);
              provider.changeMonth(prev);
            },
            child: const Icon(Icons.chevron_left_rounded,
                color: AppTheme.textSecondary, size: 18),
          ),
          const SizedBox(width: 6),
          Text(
            AppTheme.formatMonth(provider.selectedMonth),
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              final now = DateTime.now();
              final next = DateTime(provider.selectedMonth.year,
                  provider.selectedMonth.month + 1);
              if (next.isBefore(DateTime(now.year, now.month + 1))) {
                provider.changeMonth(next);
              }
            },
            child: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }
}
