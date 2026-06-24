import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';

class UpcomingBillsSection extends StatelessWidget {
  const UpcomingBillsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final bills = provider.getUpcomingBills();
    final theme = Theme.of(context);
    final currencyProvider = context.watch<CurrencyProvider>();

    final totalCommitted =
        bills.fold(0.0, (sum, b) => sum + (b['amount'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Upcoming Bills',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (bills.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${bills.length} pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (bills.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No upcoming bills for the rest of this month. 🎉',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: theme.dividerColor.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                ...bills.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final bill = entry.value;
                  final isEmi = bill['type'] == 'emi';
                  final name = bill['name'] as String;
                  final amount = bill['amount'] as double;
                  final dueDay = bill['dueDay'] as int;
                  final now = DateTime.now();
                  final todayDate = DateTime(now.year, now.month, now.day);
                  final dueDate = DateTime(now.year, now.month, dueDay);
                  final daysUntil = dueDate.difference(todayDate).inDays;

                  final urgencyColor = daysUntil <= 2
                      ? Colors.red
                      : daysUntil <= 5
                          ? Colors.orange
                          : theme.colorScheme.onSurface.withOpacity(0.5);

                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isEmi
                              ? Colors.deepPurple.withOpacity(0.1)
                              : Colors.teal.withOpacity(0.1),
                          child: Icon(
                            isEmi
                                ? Icons.credit_card_rounded
                                : Icons.event_repeat_rounded,
                            size: 18,
                            color:
                                isEmi ? Colors.deepPurple : Colors.teal,
                          ),
                        ),
                        title: Text(
                          name,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isEmi
                                    ? Colors.deepPurple.withOpacity(0.08)
                                    : Colors.teal.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isEmi ? 'EMI' : 'Sub',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isEmi
                                      ? Colors.deepPurple
                                      : Colors.teal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.calendar_today,
                                size: 11, color: urgencyColor),
                            const SizedBox(width: 3),
                            Text(
                              daysUntil == 0
                                  ? 'Due today'
                                  : daysUntil == 1
                                      ? 'Due tomorrow'
                                      : 'Due on ${_ordinal(dueDay)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: urgencyColor,
                                fontWeight: daysUntil <= 2
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          currencyProvider.format(amount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (idx < bills.length - 1)
                        Divider(
                          height: 1,
                          indent: 56,
                          color: theme.dividerColor.withOpacity(0.08),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Total committed footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Committed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  currencyProvider.format(totalCommitted),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }
}
