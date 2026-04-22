import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existing;

  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategoryId = 'food';
  late DateTime _selectedDate;
  bool _saving = false;

  // Staggered entrance
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  // Shake on validation error
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountController.text = e.amount.toString();
      _descController.text = e.description;
      _selectedCategoryId = e.categoryId;
      _selectedDate = e.date;
    } else {
      _selectedDate = DateTime.now();
    }

    // ── Staggered entrance ──
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    const delays = [0.0, 0.13, 0.26, 0.39, 0.52];
    _fadeAnims = delays
        .map((d) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _entranceCtrl,
                curve: Interval(d, (d + 0.5).clamp(0.0, 1.0),
                    curve: Curves.easeOut),
              ),
            ))
        .toList();
    _slideAnims = delays
        .map((d) =>
            Tween<Offset>(begin: const Offset(0, 0.28), end: Offset.zero)
                .animate(
              CurvedAnimation(
                parent: _entranceCtrl,
                curve: Interval(d, (d + 0.5).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic),
              ),
            ))
        .toList();
    _entranceCtrl.forward();

    // ── Shake ──
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _entranceCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _shakeCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final provider = context.read<AppProvider>();
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    if (widget.existing != null) {
      await provider.updateExpense(
        widget.existing!.copyWith(
          amount: amount,
          categoryId: _selectedCategoryId,
          description: _descController.text.trim(),
          date: _selectedDate,
        ),
      );
    } else {
      await provider.addExpense(
        Expense(
          id: '',
          amount: amount,
          categoryId: _selectedCategoryId,
          description: _descController.text.trim(),
          date: _selectedDate,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.cardBg,
            onSurface: AppTheme.textPrimary,
          ),
          dialogBackgroundColor: AppTheme.cardBg,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _selectedDate = picked);
    }
  }

  void _selectCategory(String id) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategoryId = id);
  }

  Widget _entrance(int i, Widget child) => FadeTransition(
        opacity: _fadeAnims[i],
        child: SlideTransition(position: _slideAnims[i], child: child),
      );

  Category get _selectedCategory =>
      Category.defaults.firstWhere((c) => c.id == _selectedCategoryId);

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final cat = _selectedCategory;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Editar gasto' : 'Nuevo gasto',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.danger, size: 22),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppTheme.cardBg,
                    title: const Text('Eliminar gasto',
                        style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text(
                        '¿Seguro que quieres eliminar este gasto?',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar',
                              style:
                                  TextStyle(color: AppTheme.textSecondary))),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar',
                              style: TextStyle(color: AppTheme.danger))),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  context
                      .read<AppProvider>()
                      .deleteExpense(widget.existing!.id);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // ── 0. Importe ────────────────────────────────────────────────
            _entrance(
              0,
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) {
                  final dx =
                      math.sin(_shakeAnim.value * math.pi * 7) * 10;
                  return Transform.translate(
                      offset: Offset(dx, 0), child: child);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                      vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: cat.color.withOpacity(0.2), width: 1),
                  ),
                  child: Column(
                    children: [
                      // Icono + nombre animado al cambiar categoría
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                                    begin: const Offset(0, -0.4),
                                    end: Offset.zero)
                                .animate(anim),
                            child: child,
                          ),
                        ),
                        child: Row(
                          key: ValueKey(cat.id),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: cat.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(cat.icon,
                                  color: cat.color, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(cat.name,
                                style: TextStyle(
                                    color: cat.color.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: cat.color),
                              child: const Text('\$'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 170,
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*[,.]?\d{0,2}')),
                              ],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: cat.color,
                                letterSpacing: -1,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  fontSize: 44,
                                  color: cat.color.withOpacity(0.25),
                                  letterSpacing: -1,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Introduce un importe';
                                }
                                final n =
                                    double.tryParse(v.replaceAll(',', '.'));
                                if (n == null || n <= 0) {
                                  return 'Importe inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── 1. Categoría ──────────────────────────────────────────────
            _entrance(
              1,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('CATEGORÍA'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: Category.defaults.length,
                    itemBuilder: (_, i) {
                      final c = Category.defaults[i];
                      final selected = c.id == _selectedCategoryId;
                      return _BounceTap(
                        onTap: () => _selectCategory(c.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: selected
                                ? c.color.withOpacity(0.18)
                                : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? c.color.withOpacity(0.6)
                                  : AppTheme.border,
                              width: selected ? 1.5 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: c.color.withOpacity(0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1.2 : 1.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                child: Icon(c.icon,
                                    color: selected
                                        ? c.color
                                        : AppTheme.textSecondary,
                                    size: 24),
                              ),
                              const SizedBox(height: 6),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selected
                                      ? c.color
                                      : AppTheme.textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                child: Text(c.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 2. Descripción ────────────────────────────────────────────
            _entrance(
              2,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('DESCRIPCIÓN'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: TextFormField(
                      controller: _descController,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'ej. Supermercado, gasolina...',
                        hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            fontSize: 14),
                        prefixIcon: Icon(Icons.notes_rounded,
                            color: AppTheme.textSecondary.withOpacity(0.6),
                            size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 3. Fecha ──────────────────────────────────────────────────
            _entrance(
              3,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('FECHA'),
                  const SizedBox(height: 10),
                  _BounceTap(
                    scaleTo: 0.97,
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              color: AppTheme.primary.withOpacity(0.8),
                              size: 18),
                          const SizedBox(width: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                        begin: const Offset(0, 0.5),
                                        end: Offset.zero)
                                    .animate(anim),
                                child: child,
                              ),
                            ),
                            child: Text(
                              AppTheme.formatDate(_selectedDate),
                              key: ValueKey(_selectedDate
                                  .toIso8601String()
                                  .substring(0, 10)),
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 15),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                              size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ── 4. Botón guardar ──────────────────────────────────────────
            _entrance(
              4,
              const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      floatingActionButton: _entrance(
        4,
        FloatingActionButton.extended(
          onPressed: _saving ? null : _save,
          backgroundColor: _saving ? cat.color.withOpacity(0.6) : cat.color,
          foregroundColor: Colors.white,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Icon(isEditing ? Icons.check_rounded : Icons.add_rounded),
          label: Text(
            isEditing ? 'Guardar cambios' : 'Añadir gasto',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ─── Bounce Tap ───────────────────────────────────────────────────────────────

class _BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleTo;

  const _BounceTap({
    required this.child,
    required this.onTap,
    this.scaleTo = 0.87,
  });

  @override
  State<_BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<_BounceTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.scaleTo,
  ).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}


