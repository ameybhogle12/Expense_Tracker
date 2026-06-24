import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

class DashboardKpiCards extends StatelessWidget {
  final double income;
  final double expense;
  final double prevIncome;
  final double prevExpense;

  const DashboardKpiCards({
    super.key,
    required this.income,
    required this.expense,
    required this.prevIncome,
    required this.prevExpense,
  });

  @override
  Widget build(BuildContext context) {
    final savings = income - expense;
    final savingsRate = income > 0 ? (savings / income) * 100 : 0.0;

    final incomeChange = prevIncome > 0
        ? ((income - prevIncome) / prevIncome) * 100
        : (income > 0 ? 100.0 : 0.0);
    final expenseChange = prevExpense > 0
        ? ((expense - prevExpense) / prevExpense) * 100
        : (expense > 0 ? 100.0 : 0.0);

    final currencyProvider = context.watch<CurrencyProvider>();

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: 'Income',
            value: currencyProvider.format(income),
            changePercent: incomeChange,
            icon: Icons.trending_up_rounded,
            gradientColors: [
              const Color(0xFF00C853),
              const Color(0xFF69F0AE),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            title: 'Expenses',
            value: currencyProvider.format(expense),
            changePercent: expenseChange,
            invertChange: true,
            icon: Icons.trending_down_rounded,
            gradientColors: [
              const Color(0xFFFF1744),
              const Color(0xFFFF8A80),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiCard(
            title: 'Savings',
            value: currencyProvider.format(savings.abs()),
            subtitle: savings >= 0
                ? '${savingsRate.toStringAsFixed(1)}% saved'
                : 'Overspent',
            icon: savings >= 0
                ? Icons.savings_rounded
                : Icons.warning_amber_rounded,
            gradientColors: savings >= 0
                ? [const Color(0xFF2979FF), const Color(0xFF82B1FF)]
                : [const Color(0xFFFF6D00), const Color(0xFFFFAB40)],
            isNegative: savings < 0,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double? changePercent;
  final bool invertChange;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isNegative;

  const _KpiCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.changePercent,
    this.invertChange = false,
    required this.icon,
    required this.gradientColors,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? gradientColors
                  .map((c) => c.withOpacity(0.25))
                  .toList()
              : gradientColors
                  .map((c) => c.withOpacity(0.12))
                  .toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors[0].withOpacity(isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: gradientColors[0]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (changePercent != null)
            _ChangeChip(
              percent: changePercent!,
              invertLogic: invertChange,
            )
          else if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isNegative
                    ? gradientColors[0]
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  final double percent;
  final bool invertLogic;

  const _ChangeChip({
    required this.percent,
    this.invertLogic = false,
  });

  @override
  Widget build(BuildContext context) {
    // For expenses, a decrease is good (green) and increase is bad (red).
    final isPositiveChange = percent >= 0;
    final isGood = invertLogic ? !isPositiveChange : isPositiveChange;
    final color = isGood ? const Color(0xFF00C853) : const Color(0xFFFF1744);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositiveChange
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            '${percent.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
