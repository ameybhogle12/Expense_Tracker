import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../screens/manage_wallets_screen.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  static const double _cardExtent = 145 + 12; // card width + right margin
  final ScrollController _scrollController = ScrollController();
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final index = (_scrollController.offset / _cardExtent).round();
    if (index != _activeIndex) {
      setState(() => _activeIndex = index);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final totalSpending = provider.totalMonthlySpending;
    final wallets = provider.wallets;

    final currencyProvider = context.watch<CurrencyProvider>();
    final onContainer = Theme.of(context).colorScheme.onPrimaryContainer;
    final activeIndex = _activeIndex.clamp(0, wallets.isEmpty ? 0 : wallets.length - 1);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'My Wallets',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onContainer,
                        ),
                  ),
                  if (wallets.length > 1) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.swipe, size: 16, color: onContainer.withOpacity(0.7)),
                  ],
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 20),
                tooltip: 'Manage Wallets',
                color: onContainer,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageWalletsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Horizontal scrolling list of dynamic wallets
          SizedBox(
            height: 95,
            child: wallets.isEmpty
                ? const Center(child: Text('No wallets configured'))
                : ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      final balance = provider.getWalletBalance(wallet.name);

                      // Curated visual gradients for premium card looks
                      final List<List<Color>> gradients = [
                        [Colors.indigo.shade600, Colors.blue.shade500],
                        [Colors.teal.shade600, Colors.cyan.shade500],
                        [Colors.deepOrange.shade600, Colors.orange.shade500],
                        [Colors.purple.shade600, Colors.pink.shade500],
                      ];
                      final activeGradient = gradients[index % gradients.length];

                      return Container(
                        width: 145,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: activeGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: activeGradient[0].withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              wallet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currencyProvider.format(balance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Page-dot indicator so users know more wallets exist beyond the edge.
          if (wallets.length > 1) ...[
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(wallets.length, (i) {
                  final isActive = i == activeIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: onContainer.withOpacity(isActive ? 0.9 : 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Spent This Month',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: onContainer.withOpacity(0.8),
                    ),
              ),
              Text(
                currencyProvider.format(totalSpending),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onContainer,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
