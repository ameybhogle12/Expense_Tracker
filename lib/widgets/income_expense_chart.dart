import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class IncomeExpenseChart extends StatelessWidget {
  final List<Map<String, dynamic>> trendData;

  const IncomeExpenseChart({super.key, required this.trendData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (trendData.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(l10n.notEnoughDataForChart)),
      );
    }

    final theme = Theme.of(context);
    final currencyProvider = context.watch<CurrencyProvider>();

    double maxY = 0;
    for (final item in trendData) {
      final inc = (item['income'] as double);
      final exp = (item['expense'] as double);
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }
    maxY = maxY == 0 ? 10000 : maxY * 1.2;

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (int i = 0; i < trendData.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), trendData[i]['income'] as double));
      expenseSpots.add(FlSpot(i.toDouble(), trendData[i]['expense'] as double));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.incomeVsExpenses,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _LegendDot(color: const Color(0xFF00C853), label: l10n.income),
            const SizedBox(width: 12),
            _LegendDot(color: const Color(0xFFFF1744), label: l10n.expenses),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.dividerColor.withOpacity(0.15),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == maxY) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          currencyProvider.formatCompact(value),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= trendData.length) {
                        return const SizedBox.shrink();
                      }
                      final month = trendData[idx]['month'] as int;
                      final monthName = DateFormat.MMM()
                          .format(DateTime(2026, month));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      return LineTooltipItem(
                        currencyProvider.format(spot.y.toDouble()),
                        TextStyle(
                          color:
                              isIncome ? const Color(0xFF00C853) : const Color(0xFFFF1744),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                // Income line
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: const Color(0xFF00C853),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3.5,
                      color: const Color(0xFF00C853),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00C853).withOpacity(0.25),
                        const Color(0xFF00C853).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Expense line
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: const Color(0xFFFF1744),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3.5,
                      color: const Color(0xFFFF1744),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF1744).withOpacity(0.15),
                        const Color(0xFFFF1744).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
