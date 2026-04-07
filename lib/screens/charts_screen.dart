import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.expenses;

    if (expenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Charts')),
        body: const Center(
          child: Text('No data available for charts.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Charts', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: _buildCategoryPieChart(provider, context),
            ),
            const SizedBox(height: 48),
            Text(
              'Daily Spending (This Month)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: _buildDailyBarChart(provider, context),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(ExpenseProvider provider, BuildContext context) {
    final List<PieChartSectionData> sections = [];
    double total = provider.totalMonthlySpending;

    if (total == 0) return const Center(child: Text('No spending this month.'));

    for (final category in provider.categories) {
      final spent = provider.getCategorySpending(category.name);
      if (spent > 0) {
        final percentage = (spent / total) * 100;
        sections.add(
          PieChartSectionData(
            color: Color(category.colorValue),
            value: spent,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: sections,
      ),
    );
  }

  Widget _buildDailyBarChart(ExpenseProvider provider, BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    // Group by day exactly
    Map<int, double> dailyTotals = {};
    for (int i = 1; i <= daysInMonth; i++) {
      dailyTotals[i] = 0.0;
    }

    for (final e in provider.expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        dailyTotals[e.date.day] = (dailyTotals[e.date.day] ?? 0) + e.amount;
      }
    }

    // Determine max Y for the chart scaling
    double maxY = 0;
    dailyTotals.forEach((key, value) {
      if (value > maxY) maxY = value;
    });
    
    if (maxY == 0) maxY = 10; // Default if nothing is there
    maxY = maxY * 1.2; // Give 20% headroom

    final barGroups = dailyTotals.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Theme.of(context).colorScheme.primary,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0 || value == 1 || value == daysInMonth) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
