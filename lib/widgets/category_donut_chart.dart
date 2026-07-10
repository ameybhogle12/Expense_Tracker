import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import '../screens/category_transactions_screen.dart';

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
    final categoryDataMap = <String, _CategorySpend>{};
    for (final cat in provider.categories) {
      categoryDataMap[cat.name] = _CategorySpend(
        name: cat.name,
        amount: 0,
        count: 0,
        color: Color(cat.colorValue),
        iconCodePoint: cat.iconCodePoint,
      );
    }
    
    double totalSpend = 0;
    for (final e in provider.expenses) {
      if (e.date.year == widget.year && e.date.month == widget.month) {
        if (categoryDataMap.containsKey(e.category)) {
          categoryDataMap[e.category]!.amount += e.amount;
          categoryDataMap[e.category]!.count += 1;
          totalSpend += e.amount;
        }
      }
    }
    
    final categoryData = categoryDataMap.values.where((c) => c.amount > 0).toList();

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

      // Enforce a minimum render value of 3% of total spend so tiny slices are clickable
      final minRenderValue = totalSpend * 0.03;
      final renderValue = item.amount < minRenderValue ? minRenderValue : item.amount;

      sections.add(PieChartSectionData(
        color: item.color,
        value: renderValue,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 60 : 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    final centerLabel = _touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < categoryData.length
        ? categoryData[_touchedIndex!].name
        : l10n.total;
    final centerAmount = _touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < categoryData.length
        ? categoryData[_touchedIndex!].amount
        : totalSpend;

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
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent) {
                        setState(() {
                          if (response == null || response.touchedSection == null) {
                            _touchedIndex = null;
                            return;
                          }
                          final index = response.touchedSection!.touchedSectionIndex;
                          if (index == -1) {
                            _touchedIndex = null;
                          } else {
                            _touchedIndex = _touchedIndex == index ? null : index;
                          }
                        });
                      }
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: sections,
                ),
              ),
              // Center label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyProvider.formatCompact(centerAmount),
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
          return InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryTransactionsScreen(
                categoryName: item.name,
                year: widget.year,
                month: widget.month,
              )));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${item.count} transactions',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
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
            ),
          );
        }),
      ],
    );
  }
}

class _CategorySpend {
  final String name;
  double amount;
  int count;
  final Color color;
  final int iconCodePoint;

  _CategorySpend({
    required this.name,
    required this.amount,
    required this.count,
    required this.color,
    required this.iconCodePoint,
  });
}
