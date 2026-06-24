import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class CategoryDonutChart extends StatefulWidget {
  final int year;
  final int month;

  const CategoryDonutChart({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final currencyProvider = context.watch<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;

    // Build category spending data for the selected month
    final categoryData = <_CategorySpend>[];
    double totalSpend = 0;

    for (final cat in provider.categories) {
      final spent = provider.getCategorySpendingForMonth(
          cat.name, widget.year, widget.month);
      if (spent > 0) {
        categoryData.add(_CategorySpend(
          name: cat.name,
          amount: spent,
          color: Color(cat.colorValue),
          iconCodePoint: cat.iconCodePoint,
        ));
        totalSpend += spent;
      }
    }

    if (categoryData.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.spendingByCategory,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Center(child: Text(l10n.noSpendingData)),
          const SizedBox(height: 40),
        ],
      );
    }

    // Sort by amount descending
    categoryData.sort((a, b) => b.amount.compareTo(a.amount));

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < categoryData.length; i++) {
      final item = categoryData[i];
      final percentage = (item.amount / totalSpend) * 100;
      final isTouched = i == _touchedIndex;

      sections.add(PieChartSectionData(
        color: item.color,
        value: item.amount,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 58 : 48,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.spendingByCategory,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = null;
                          return;
                        }
                        _touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 55,
                  sections: sections,
                ),
              ),
              // Center label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.total,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyProvider.format(totalSpend),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Legend list
        ...categoryData.map((item) {
          final percentage = (item.amount / totalSpend) * 100;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                  size: 16,
                  color: item.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  currencyProvider.format(item.amount),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 45,
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _CategorySpend {
  final String name;
  final double amount;
  final Color color;
  final int iconCodePoint;

  _CategorySpend({
    required this.name,
    required this.amount,
    required this.color,
    required this.iconCodePoint,
  });
}
