import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/split_provider.dart';

class SettlementScreen extends StatelessWidget {
  final String tripId;
  const SettlementScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitProvider>();
    final trip = provider.trips.firstWhere((t) => t.id == tripId);
    final settlements = provider.getSettlements(tripId);
    final balances = provider.getBalances(tripId);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
        centerTitle: true,
      ),
      body: settlements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'All settled!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No one owes anyone anything.',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Summary Card ─────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.tertiaryContainer, colorScheme.secondaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.handshake, size: 40, color: colorScheme.onTertiaryContainer),
                      const SizedBox(height: 8),
                      Text(
                        '${settlements.length} transaction${settlements.length == 1 ? '' : 's'} to settle',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onTertiaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optimized for minimum transfers',
                        style: TextStyle(
                          color: colorScheme.onTertiaryContainer.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Settlement Cards ─────────────────────────
                ...settlements.map((s) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // From Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _getAvatarColor(s.from, colorScheme),
                            child: Text(
                              s.from[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // From Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.from, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('pays', style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            ),
                          ),
                          // Arrow + Amount
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '₹${s.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Icon(Icons.arrow_forward, size: 16, color: colorScheme.primary),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // To Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(s.to, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('receives', style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // To Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _getAvatarColor(s.to, colorScheme),
                            child: Text(
                              s.to[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // ─── Per-Person Summary ───────────────────────
                Text(
                  'Individual Breakdown',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 12),
                ...trip.members.map((member) {
                  final balance = balances[member] ?? 0;
                  String status;
                  Color statusColor;
                  IconData statusIcon;

                  if (balance > 0.01) {
                    status = 'Gets back ₹${balance.toStringAsFixed(0)}';
                    statusColor = Colors.green;
                    statusIcon = Icons.arrow_downward;
                  } else if (balance < -0.01) {
                    status = 'Owes ₹${balance.abs().toStringAsFixed(0)}';
                    statusColor = colorScheme.error;
                    statusIcon = Icons.arrow_upward;
                  } else {
                    status = 'Settled';
                    statusColor = colorScheme.onSurface.withOpacity(0.4);
                    statusIcon = Icons.check;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getAvatarColor(member, colorScheme),
                      child: Text(
                        member[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    title: Text(member),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
    );
  }

  Color _getAvatarColor(String name, ColorScheme colorScheme) {
    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
