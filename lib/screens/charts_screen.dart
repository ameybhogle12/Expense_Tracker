import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../widgets/dashboard_kpi_cards.dart';
import '../widgets/income_expense_chart.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/budgets_overview.dart';
import '../widgets/goals_progress_section.dart';
import '../widgets/upcoming_bills_section.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

enum _FilterPreset { thisMonth, lastMonth, last3Months, ytd }

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  _FilterPreset _activePreset = _FilterPreset.thisMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  void _goToPreviousMonth() {
    setState(() {
      _activePreset = _FilterPreset.thisMonth; // reset preset on manual nav
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    // Don't allow navigating past the current month
    if (_selectedYear == now.year && _selectedMonth == now.month) return;
    setState(() {
      _activePreset = _FilterPreset.thisMonth;
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  void _applyPreset(_FilterPreset preset) {
    final now = DateTime.now();
    setState(() {
      _activePreset = preset;
      _selectedYear = now.year;
      _selectedMonth = now.month;
      if (preset == _FilterPreset.lastMonth) {
        if (_selectedMonth == 1) {
          _selectedMonth = 12;
          _selectedYear--;
        } else {
          _selectedMonth--;
        }
      }
    });
  }

  int get _trendMonths {
    switch (_activePreset) {
      case _FilterPreset.last3Months:
        return 3;
      case _FilterPreset.ytd:
        final now = DateTime.now();
        return now.month;
      case _FilterPreset.thisMonth:
      case _FilterPreset.lastMonth:
        return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedYear == now.year && _selectedMonth == now.month;

    // KPI data
    final income = provider.getMonthlyIncome(_selectedYear, _selectedMonth);
    final expense = provider.getMonthlyExpense(_selectedYear, _selectedMonth);

    // Previous month for % change comparison
    final prevDate = DateTime(_selectedYear, _selectedMonth - 1, 1);
    final prevIncome = provider.getMonthlyIncome(prevDate.year, prevDate.month);
    final prevExpense =
        provider.getMonthlyExpense(prevDate.year, prevDate.month);

    // Trend data
    final trendData = provider.getMonthlyTrend(_trendMonths);

    final monthLabel = DateFormat.yMMMM()
        .format(DateTime(_selectedYear, _selectedMonth));
        
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analytics,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Month Selector ──────────────────────────────────
            _buildMonthSelector(theme, monthLabel, isCurrentMonth),
            const SizedBox(height: 12),

            // ── Filter Preset Chips ─────────────────────────────
            _buildFilterChips(theme, l10n),
            const SizedBox(height: 20),

            // ── Section 1: KPI Cards ────────────────────────────
            DashboardKpiCards(
              income: income,
              expense: expense,
              prevIncome: prevIncome,
              prevExpense: prevExpense,
            ),
            const SizedBox(height: 28),

            // ── Section 2: Income vs Expense Line Chart ─────────
            IncomeExpenseChart(trendData: trendData),
            const SizedBox(height: 28),

            // ── Section 3: Category Donut Chart ─────────────────
            CategoryDonutChart(
              year: _selectedYear,
              month: _selectedMonth,
            ),
            const SizedBox(height: 28),

            // ── Section 4: Budget Tracker ───────────────────────
            const BudgetsOverview(),
            const SizedBox(height: 28),

            // ── Section 5: Savings Goals ────────────────────────
            const GoalsProgressSection(),
            const SizedBox(height: 28),

            // ── Section 6: Upcoming Bills ───────────────────────
            const UpcomingBillsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(
      ThemeData theme, String monthLabel, bool isCurrentMonth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor:
                  theme.colorScheme.primary.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            monthLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: isCurrentMonth ? null : _goToNextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: isCurrentMonth
                  ? null
                  : theme.colorScheme.primary.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: l10n.thisMonth,
            isActive: _activePreset == _FilterPreset.thisMonth,
            onTap: () => _applyPreset(_FilterPreset.thisMonth),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.lastMonth,
            isActive: _activePreset == _FilterPreset.lastMonth,
            onTap: () => _applyPreset(_FilterPreset.lastMonth),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.last3Months,
            isActive: _activePreset == _FilterPreset.last3Months,
            onTap: () => _applyPreset(_FilterPreset.last3Months),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.yearToDate,
            isActive: _activePreset == _FilterPreset.ytd,
            onTap: () => _applyPreset(_FilterPreset.ytd),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? null
                : Border.all(
                    color: theme.dividerColor.withOpacity(0.15)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
