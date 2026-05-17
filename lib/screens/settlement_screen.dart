import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/split_provider.dart';

class SettlementScreen extends StatefulWidget {
  final String tripId;
  const SettlementScreen({super.key, required this.tripId});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SplitProvider>();
    final trip = provider.trips.firstWhere((t) => t.id == widget.tripId);
    final settlements = provider.getSettlements(widget.tripId);
    final balances = provider.getBalances(widget.tripId);
    final colorScheme = Theme.of(context).colorScheme;

    // Count how many are already paid
    final paidCount = settlements
        .where((s) => provider.isSettlementPaid(widget.tripId, s.from, s.to))
        .length;
    final allPaid = settlements.isNotEmpty && paidCount == settlements.length;

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
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.green.withOpacity(0.4)),
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
                    style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Summary Card with stagger animation ──────────
                _buildAnimatedItem(
                  index: 0,
                  totalItems: settlements.length + 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: allPaid
                            ? [Colors.green.shade300, Colors.teal.shade300]
                            : [
                                colorScheme.tertiaryContainer,
                                colorScheme.secondaryContainer
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          allPaid ? Icons.celebration : Icons.handshake,
                          size: 40,
                          color: allPaid
                              ? Colors.white
                              : colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allPaid
                              ? '🎉 All payments done!'
                              : '$paidCount of ${settlements.length} paid',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: allPaid
                                        ? Colors.white
                                        : colorScheme.onTertiaryContainer,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          allPaid
                              ? 'Everyone is squared up!'
                              : 'Optimized for minimum transfers',
                          style: TextStyle(
                            color: allPaid
                                ? Colors.white70
                                : colorScheme.onTertiaryContainer
                                    .withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Settlement Cards with Paid button ────────────
                ...settlements.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final isPaid = provider.isSettlementPaid(
                      widget.tripId, s.from, s.to);

                  return _buildAnimatedItem(
                    index: idx + 1,
                    totalItems: settlements.length + 2,
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isPaid
                              ? Colors.green.withOpacity(0.4)
                              : colorScheme.outlineVariant,
                        ),
                      ),
                      color: isPaid
                          ? Colors.green.withOpacity(0.05)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            // From → Amount → To row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // From Avatar
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isPaid
                                      ? Colors.green.shade200
                                      : _getAvatarColor(s.from, colorScheme),
                                  child: isPaid
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 18)
                                      : Text(
                                          s.from[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 6),
                                // From Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.from,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          decoration: isPaid
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: isPaid
                                              ? colorScheme.onSurface
                                                  .withOpacity(0.4)
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        'pays',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow + Amount
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isPaid
                                            ? Colors.green.shade100
                                            : colorScheme.primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '₹${s.amount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isPaid
                                              ? Colors.green.shade700
                                              : colorScheme
                                                  .onPrimaryContainer,
                                          fontSize: 14,
                                          decoration: isPaid
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Icon(Icons.arrow_forward,
                                        size: 14,
                                        color: isPaid
                                            ? Colors.green
                                            : colorScheme.primary),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                // To Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        s.to,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          decoration: isPaid
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: isPaid
                                              ? colorScheme.onSurface
                                                  .withOpacity(0.4)
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        'receives',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // To Avatar
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isPaid
                                      ? Colors.green.shade200
                                      : _getAvatarColor(s.to, colorScheme),
                                  child: isPaid
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 18)
                                      : Text(
                                          s.to[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // ─── Paid / Mark Paid Button ───────────
                            SizedBox(
                              width: double.infinity,
                              child: isPaid
                                  ? OutlinedButton.icon(
                                      onPressed: () {
                                        provider.unmarkSettlementPaid(
                                            widget.tripId, s.from, s.to);
                                      },
                                      icon: const Icon(Icons.undo,
                                          size: 16, color: Colors.green),
                                      label: const Text(
                                        'Paid ✓  (tap to undo)',
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.green, width: 1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    )
                                  : FilledButton.icon(
                                      onPressed: () {
                                        _showPayConfirmation(
                                            context, provider, s);
                                      },
                                      icon: const Icon(Icons.check_circle,
                                          size: 16),
                                      label: const Text('Mark as Paid',
                                          style: TextStyle(fontSize: 13)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // ─── Per-Person Summary ───────────────────────
                _buildAnimatedItem(
                  index: settlements.length + 1,
                  totalItems: settlements.length + 2,
                  child: Text(
                    'Individual Breakdown',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                ...trip.members.map((member) {
                  final balance = balances[member] ?? 0;
                  String status;
                  Color statusColor;
                  IconData statusIcon;

                  if (balance > 0.01) {
                    // Check if all settlements TO this person are paid
                    final memberSettlements = settlements.where((s) => s.to == member);
                    final allMemberSettlementsPaid = memberSettlements.isNotEmpty &&
                        memberSettlements.every((s) => provider.isSettlementPaid(widget.tripId, s.from, s.to));
                    
                    if (allMemberSettlementsPaid) {
                      status = 'Paid ✓';
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else {
                      status = 'Gets back ₹${balance.toStringAsFixed(0)}';
                      statusColor = Colors.green;
                      statusIcon = Icons.arrow_downward;
                    }
                  } else if (balance < -0.01) {
                    // Check if all settlements FROM this person are paid
                    final memberSettlements = settlements.where((s) => s.from == member);
                    final allMemberSettlementsPaid = memberSettlements.isNotEmpty &&
                        memberSettlements.every((s) => provider.isSettlementPaid(widget.tripId, s.from, s.to));
                    
                    if (allMemberSettlementsPaid) {
                      status = 'Paid ✓';
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else {
                      status = 'Owes ₹${balance.abs().toStringAsFixed(0)}';
                      statusColor = colorScheme.error;
                      statusIcon = Icons.arrow_upward;
                    }
                  } else {
                    // Zero balance — either truly settled OR never included
                    final expenses = provider.getExpensesForTrip(widget.tripId);
                    final isInAnyExpense = expenses.any(
                      (e) =>
                          e.splitAmong.contains(member) ||
                          e.paidBy == member,
                    );
                    if (isInAnyExpense) {
                      status = 'Settled';
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else {
                      status = 'Not in any splits';
                      statusColor = Colors.orange;
                      statusIcon = Icons.warning_amber_rounded;
                    }
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getAvatarColor(member, colorScheme),
                      child: Text(
                        member[0].toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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

  // ─── Stagger Animation Helper ──────────────────────────────
  Widget _buildAnimatedItem({
    required int index,
    required int totalItems,
    required Widget child,
  }) {
    final begin = (index / totalItems).clamp(0.0, 1.0);
    final end = ((index + 1) / totalItems).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ─── Paid Confirmation Dialog ──────────────────────────────
  void _showPayConfirmation(
    BuildContext context,
    SplitProvider provider,
    Settlement s,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
                color: colorScheme.onSurface, fontSize: 15, height: 1.5),
            children: [
              TextSpan(
                text: s.from,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' has paid '),
              TextSpan(
                text: '₹${s.amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const TextSpan(text: ' to '),
              TextSpan(
                text: s.to,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not yet'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              provider.markSettlementPaid(widget.tripId, s.from, s.to);
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Yes, Paid!'),
          ),
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
