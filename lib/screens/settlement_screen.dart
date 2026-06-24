import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/split_provider.dart';
import '../providers/currency_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class SettlementScreen extends StatefulWidget {
  final String tripId;
  const SettlementScreen({super.key, required this.tripId});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  bool _isCalculating = true;
  int _calcStep = 0;
  Timer? _calcTimer;

  late List<String> _calcSteps;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final provider = context.read<SplitProvider>();
    final l10n = AppLocalizations.of(context)!;
    _calcSteps = [
      l10n.analyzingExpenses,
      l10n.runningDebtOptimization,
      l10n.calculatingBalances,
      l10n.optimizingTransfers,
      l10n.done,
    ];

    // Settlement results are computed instantly; the loader is purely a
    // first-impression flourish. Only play it the first time a trip's
    // settlement is opened this session — reopening should be instant.
    if (!provider.shouldAnimateSettlement(widget.tripId)) {
      _isCalculating = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _staggerController.forward();
      });
      return;
    }
    provider.markSettlementAnimationSeen(widget.tripId);

    // Cycle through loader steps for 3.5 seconds before revealing results
    _calcTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted) {
        setState(() {
          if (_calcStep < _calcSteps.length - 1) {
            _calcStep++;
          } else {
            timer.cancel();
            _isCalculating = false;
            _staggerController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _calcTimer?.cancel();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isCalculating) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.calculatingSplits),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 3),
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          color: Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        );
                      },
                    ),
                    Icon(
                      Icons.calculate_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  _calcSteps[_calcStep],
                  key: ValueKey(_calcStep),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.runningDebtOptimization,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final provider = context.watch<SplitProvider>();
    final trip = provider.trips.firstWhere((t) => t.id == widget.tripId);
    final settlements = provider.getSettlements(widget.tripId);
    final balances = provider.getBalances(widget.tripId);
    final colorScheme = Theme.of(context).colorScheme;
    final currencyProvider = context.watch<CurrencyProvider>();

    // Count how many are already paid
    final paidCount = settlements
        .where((s) => provider.isSettlementPaid(widget.tripId, s.from, s.to))
        .length;
    final allPaid = settlements.isNotEmpty && paidCount == settlements.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settleUp),
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
                    l10n.allSettled,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noOneOwesAnything,
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
                              ? l10n.allPaymentsDone
                              : l10n.paidOfTotal(paidCount, settlements.length),
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
                              ? l10n.everyoneSquaredUp
                              : l10n.optimizedForMinimumTransfers,
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
                                        l10n.pays,
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
                                        currencyProvider.format(s.amount),
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
                                        l10n.receives,
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
                                      label: Text(
                                        l10n.paidTapToUndo,
                                        style: const TextStyle(
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
                                      label: Text(l10n.markAsPaid,
                                          style: const TextStyle(fontSize: 13)),
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
                    l10n.individualBreakdown,
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
                      status = l10n.paidCheck;
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else {
                      status = l10n.getsBackAmount(currencyProvider.format(balance));
                      statusColor = Colors.green;
                      statusIcon = Icons.arrow_downward;
                    }
                  } else if (balance < -0.01) {
                    // Check if all settlements FROM this person are paid
                    final memberSettlements = settlements.where((s) => s.from == member);
                    final allMemberSettlementsPaid = memberSettlements.isNotEmpty &&
                        memberSettlements.every((s) => provider.isSettlementPaid(widget.tripId, s.from, s.to));
                    
                    if (allMemberSettlementsPaid) {
                      status = l10n.paidCheck;
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else {
                      status = l10n.owesAmount(currencyProvider.format(balance.abs()));
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
                      status = l10n.settled;
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else {
                      status = l10n.notInAnySplits;
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
    final currencyProvider = context.read<CurrencyProvider>();

    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmPayment),
        content: RichText(
          text: TextSpan(
            style: TextStyle(
                color: colorScheme.onSurface, fontSize: 15, height: 1.5),
            children: [
              TextSpan(
                text: s.from,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: l10n.hasPaidPart),
              TextSpan(
                text: currencyProvider.format(s.amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              TextSpan(text: l10n.toPart),
              TextSpan(
                text: s.to,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: l10n.questionMarkPart),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.notYet),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              provider.markSettlementPaid(widget.tripId, s.from, s.to);
            },
            icon: const Icon(Icons.check, size: 18),
            label: Text(l10n.yesPaid),
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
