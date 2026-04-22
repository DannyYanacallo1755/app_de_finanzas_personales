import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/category.dart';
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
    final total = provider.totalIncome;
    final spent = provider.totalSpent;
    final remaining = provider.remaining;
    final hasBudget = provider.totalBudget > 0;
    final byFortnight = provider.splitByFortnight;
    final additionalCount = provider.additionalIncomes.length;

    // Quincena activa
    final int activeFortnight = DateTime.now().day <= 15 ? 1 : 2;
    final fSpent = byFortnight ? provider.fortnightSpent(activeFortnight) : spent;
    final fBudget = byFortnight ? provider.fortnightBudget(activeFortnight) : provider.totalBudget;
    final fRemaining = byFortnight ? provider.fortnightRemaining(activeFortnight) : remaining;
    final fRatio = byFortnight ? provider.fortnightProgressRatio(activeFortnight) : provider.progressRatio;
    final fIsOver = fRemaining < 0;

    final Color budgetColor = fIsOver
        ? AppTheme.danger
        : fRemaining / (fBudget > 0 ? fBudget : 1) < 0.2
            ? AppTheme.warning
            : AppTheme.primary;

    final Color barColor = fIsOver
        ? AppTheme.danger
        : fRatio > 0.8
            ? AppTheme.warning
            : AppTheme.primary;

    String budgetLabel;
    if (byFortnight) {
      final fn = activeFortnight == 1 ? '1ª quincena' : '2ª quincena';
      budgetLabel = fIsOver ? 'EXCEDIDO · $fn' : 'DISPONIBLE · $fn';
    } else {
      budgetLabel = fIsOver ? 'EXCEDIDO DEL MES' : 'DISPONIBLE DEL MES';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Etiqueta superior ─────────────────────────────────────────
          Text(
            'TOTAL DE INGRESOS',
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),

          // ── Número grande = ingresos siempre ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                total > 0 ? AppTheme.formatCurrency(total) : '—',
                style: const TextStyle(
                  color: AppTheme.income,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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

          // ── Separador ─────────────────────────────────────────────────
          if (hasBudget) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: AppTheme.border),
            const SizedBox(height: 16),

            // ── Disponible / Excedido (secundario) ────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budgetLabel,
                      style: TextStyle(
                        color: budgetColor.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                const Spacer(),
                // Botón configurar
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BudgetSetupScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_rounded,
                            color: AppTheme.primary, size: 13),
                        SizedBox(width: 5),
                        Text('Configurar',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Barra de progreso ─────────────────────────────────────
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
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(
                  'de ${AppTheme.formatCurrency(fBudget)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),

            // ── Pills adicionales ─────────────────────────────────────
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
