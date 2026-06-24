import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/wallet_model.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class ManageWalletsScreen extends StatefulWidget {
  const ManageWalletsScreen({super.key});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {

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

  void _showEditWalletDialog(BuildContext context, WalletModel wallet) {
    final nameController = TextEditingController(text: wallet.name);
    final provider = context.read<ExpenseProvider>();
    final currentBalance = provider.getWalletBalance(wallet.name);
    final balanceController = TextEditingController(
      text: currentBalance.toStringAsFixed(
          currentBalance == currentBalance.roundToDouble() ? 0 : 2),
    );
    final formKey = GlobalKey<FormState>();
    final l10n = AppLocalizations.of(context)!;
    final currencyProvider = context.read<CurrencyProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Text(l10n.editWallet, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterWalletName;
                  }
                  if (value.trim().toLowerCase() == wallet.name.toLowerCase()) {
                    return null;
                  }
                  final p = context.read<ExpenseProvider>();
                  if (p.wallets.any((w) => w.name.toLowerCase() == value.trim().toLowerCase())) {
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
                  labelText: l10n.adjustBalance,
                  prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ',
                  helperText: l10n.adjustBalanceHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null) {
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
                final oldName = wallet.name;
                final newName = nameController.text.trim();

                // Handle rename
                if (oldName != newName) {
                  context.read<ExpenseProvider>().updateWallet(wallet, newName);
                }

                // Handle balance adjustment
                final balanceStr = balanceController.text.trim();
                if (balanceStr.isNotEmpty) {
                  final newBalance = double.tryParse(balanceStr);
                  if (newBalance != null && newBalance != currentBalance) {
                    // Use the new name if it was renamed
                    final walletName = oldName != newName ? newName : oldName;
                    context.read<ExpenseProvider>().adjustWalletBalance(walletName, newBalance);
                  }
                }

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.walletRenamed(newName)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWallet(BuildContext context, WalletModel wallet) {
    final provider = context.read<ExpenseProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (provider.wallets.length <= 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.cannotDelete),
          content: Text(l10n.mustKeepOneWallet),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    final txCount = provider.getWalletTransactionCount(wallet.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmDeleteWalletMsg(wallet.name)),
            if (txCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.deleteWalletWarning(txCount.toString()),
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.deleteWallet(wallet);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.walletDeleted(wallet.name)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageWallets, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final wallets = provider.wallets;
          final currencyProvider = context.watch<CurrencyProvider>();
          final totalNetWorth = wallets.fold(0.0, (sum, w) => sum + provider.getWalletBalance(w.name));

          return Column(
            children: [
              // Premium Net Worth Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3F51B5), // Deep Indigo
                      Color(0xFF673AB7), // Deep Purple
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3F51B5).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalNetWorth,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyProvider.format(totalNetWorth),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 28,
                      child: Icon(Icons.account_balance, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: wallets.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];
                    final balance = provider.getWalletBalance(wallet.name);
                    final isNegative = balance < 0;

                    // Generate a curated colorful gradient for each card based on index
                    final List<Color> cardColors = [
                      Colors.blue.shade700,
                      Colors.teal.shade700,
                      Colors.amber.shade800,
                      Colors.purple.shade700,
                      Colors.pink.shade700,
                      Colors.indigo.shade700,
                    ];
                    final colorTheme = cardColors[index % cardColors.length];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showEditWalletDialog(context, wallet),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorTheme.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.account_balance_wallet, color: colorTheme, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wallet.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isNegative ? l10n.balanceOverdrawn : l10n.availableBalance,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyProvider.format(balance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isNegative ? Colors.red : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showEditWalletDialog(context, wallet),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _confirmDeleteWallet(context, wallet),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWalletDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addWallet),
      ),
    );
  }
}
