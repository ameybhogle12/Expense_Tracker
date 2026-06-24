import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/wallet_model.dart';

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.deepPurple),
            SizedBox(width: 12),
            Text('Create Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Name',
                  hintText: 'e.g. HDFC Credit Card',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a wallet name';
                  }
                  final provider = context.read<ExpenseProvider>();
                  if (provider.wallets.any((w) => w.name.toLowerCase() == value.trim().toLowerCase())) {
                    return 'Wallet name already exists';
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
                  labelText: 'Starting Balance (Optional)',
                  prefixText: '${currencyProvider.code} ${currencyProvider.symbol} ',
                  hintText: '0',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 0) {
                      return 'Please enter a valid starting balance';
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
            child: const Text('Cancel'),
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
                    content: Text('Wallet "$name" created successfully.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditWalletDialog(BuildContext context, WalletModel wallet) {
    final nameController = TextEditingController(text: wallet.name);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.deepPurple),
            SizedBox(width: 12),
            Text('Rename Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Wallet Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a wallet name';
              }
              if (value.trim().toLowerCase() == wallet.name.toLowerCase()) {
                return null;
              }
              final provider = context.read<ExpenseProvider>();
              if (provider.wallets.any((w) => w.name.toLowerCase() == value.trim().toLowerCase())) {
                return 'Wallet name already exists';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final oldName = wallet.name;
                final newName = nameController.text.trim();
                if (oldName != newName) {
                  context.read<ExpenseProvider>().updateWallet(wallet, newName);
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Wallet renamed to "$newName".'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWallet(BuildContext context, WalletModel wallet) {
    final provider = context.read<ExpenseProvider>();
    if (provider.wallets.length <= 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text('You must keep at least one active wallet in the app.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "${wallet.name}"?\n\nNote: Transactions previously linked to this wallet will remain in history, but they won\'t affect any active wallet balances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteWallet(wallet);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Wallet "${wallet.name}" deleted.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Wallets', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Text(
                          'Total Net Worth',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
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
                                      isNegative ? 'Balance Overdrawn' : 'Available Balance',
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
        label: const Text('Add Wallet'),
      ),
    );
  }
}
