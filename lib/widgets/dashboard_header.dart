import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/wallet_model.dart';
import '../screens/manage_wallets_screen.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final ScrollController _scrollController = ScrollController();
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) {
      if (_activeIndex != 0) setState(() => _activeIndex = 0);
      return;
    }

    final walletsCount = context.read<ExpenseProvider>().wallets.length;
    if (walletsCount <= 1) return;

    final double scrollPercentage = (_scrollController.offset / maxExtent).clamp(0.0, 1.0);
    final index = (scrollPercentage * (walletsCount - 1)).round();
    
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

  void _showAddWalletDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final currencyProvider = context.read<CurrencyProvider>();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Text(l10n.createWallet, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.walletName,
                  hintText: l10n.walletNameHint,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterWalletName;
                  }
                  final provider = context.read<ExpenseProvider>();
                  if (provider.wallets.any((w) => w.name.toLowerCase() == value.trim().toLowerCase())) {
                    return l10n.walletNameExists;
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.startingBalanceOptional,
                  prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ',
                  hintText: '0',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 0) {
                      return l10n.pleaseEnterValidBalance;
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final name = nameController.text.trim();
                final balanceStr = balanceController.text.trim();
                final balance = balanceStr.isNotEmpty ? double.parse(balanceStr) : 0.0;

                final provider = context.read<ExpenseProvider>();
                final newWallet = WalletModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                );

                provider.addWallet(newWallet, initialBalance: balance);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.walletCreated(name)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final totalSpending = provider.totalMonthlySpending;
    final wallets = provider.wallets;
    final l10n = AppLocalizations.of(context)!;

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
              Text(
                l10n.myWallets,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onContainer,
                    ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    tooltip: l10n.addWallet,
                    color: onContainer,
                    onPressed: () => _showAddWalletDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, size: 20),
                    tooltip: l10n.manageWallets,
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
            ],
          ),
          const SizedBox(height: 10),
          // Horizontal scrolling list of dynamic wallets
          SizedBox(
            height: 95,
            child: wallets.isEmpty
                ? Center(child: Text(l10n.noWalletsConfigured))
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
                l10n.totalSpentThisMonth,
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
