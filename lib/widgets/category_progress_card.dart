import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class CategoryProgressCard extends StatelessWidget {
  final Category category;
  final double spent;
  final double budget;
  final double remaining;

  const CategoryProgressCard({
    super.key,
    required this.category,
    required this.spent,
    required this.budget,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOver = remaining < 0;
    final double ratio =
        budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final Color barColor = isOver
        ? AppTheme.danger
        : ratio > 0.8
            ? AppTheme.warning
            : category.color;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: category.color.withOpacity(0.15),
                  child: Icon(category.icon, color: category.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isOver)
                  const Icon(Icons.warning_rounded,
                      color: AppTheme.danger, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTheme.formatCurrency(spent),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  isOver
                      ? '-${AppTheme.formatCurrency(remaining.abs())} excedido'
                      : '${AppTheme.formatCurrency(remaining)} restante',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOver ? AppTheme.danger : AppTheme.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
