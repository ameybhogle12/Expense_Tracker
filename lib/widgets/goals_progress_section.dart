import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class GoalsProgressSection extends StatelessWidget {
  const GoalsProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final goals = provider.goals;
    final theme = Theme.of(context);
    final currencyProvider = context.watch<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (goals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.savingsGoals,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  l10n.noSavingsGoals,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.savingsGoals,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...goals.map((goal) {
          final progress =
              goal.targetAmount > 0 ? (goal.savedAmount / goal.targetAmount) : 0.0;
          final clampedProgress = progress.clamp(0.0, 1.0);
          final percentText = '${(progress * 100).toStringAsFixed(0)}%';

          // Determine status color
          Color statusColor;
          String statusText;
          if (goal.deadline != null && DateTime.now().isAfter(goal.deadline!) && progress < 1.0) {
            statusColor = Colors.red;
            statusText = l10n.overdue;
          } else if (progress >= 1.0) {
            statusColor = const Color(0xFF00C853);
            statusText = l10n.completed;
          } else if (progress >= 0.6) {
            statusColor = const Color(0xFF00C853);
            statusText = l10n.onTrack;
          } else if (progress >= 0.3) {
            statusColor = Colors.orange;
            statusText = l10n.inProgress;
          } else {
            statusColor = theme.colorScheme.primary;
            statusText = l10n.justStarted;
          }

          final goalColor = Color(goal.colorValue);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: theme.dividerColor.withOpacity(0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: goalColor.withOpacity(0.15),
                        child: Icon(
                          IconData(goal.iconCodePoint,
                              fontFamily: 'MaterialIcons'),
                          size: 16,
                          color: goalColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          goal.name,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: clampedProgress,
                      minHeight: 10,
                      backgroundColor: goalColor.withOpacity(0.1),
                      color: goalColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currencyProvider.format(goal.savedAmount)} / ${currencyProvider.format(goal.targetAmount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Row(
                        children: [
                          if (goal.deadline != null) ...[
                            Icon(Icons.event, size: 13,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4)),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat.yMMMd().format(goal.deadline!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            percentText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: goalColor,
                            ),
                          ),
                        ],
                      ),
                    ],
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
