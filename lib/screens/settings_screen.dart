import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tour_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/split_provider.dart';
import '../providers/currency_provider.dart';
import '../services/backup_service.dart';
import 'manage_categories_screen.dart';
import 'manage_budgets_screen.dart';
import 'manage_wallets_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _useBiometrics;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings_v1');
    _useBiometrics = box.get('useBiometrics', defaultValue: false);
  }

  void _toggleBiometrics(bool value) async {
    final box = Hive.box('settings_v1');
    await box.put('useBiometrics', value);
    setState(() {
      _useBiometrics = value;
    });
  }

  Future<void> _handleBackup() async {
    try {
      final path = await BackupService.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null
              ? 'Backup saved. Keep this file safe to restore later.'
              : 'Backup cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
            'This replaces ALL current data in the app with the contents of the backup file. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final restored = await BackupService.importBackup();
      if (!mounted || !restored) return;

      await context.read<ExpenseProvider>().reloadAll();
      if (!mounted) return;
      await context.read<SplitProvider>().loadData();
      if (!mounted) return;
      context.read<ThemeProvider>().loadTheme();

      setState(() {
        _useBiometrics =
            Hive.box('settings_v1').get('useBiometrics', defaultValue: false);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restored successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (!kIsWeb) ...[
            SwitchListTile(
              title: const Text('Require Authentication'),
              subtitle: const Text('Lock app with Fingerprint or PIN'),
              value: _useBiometrics,
              onChanged: _toggleBiometrics,
              secondary: const Icon(Icons.security),
            ),
            const Divider(),
          ],
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                title: const Text('Theme Mode'),
                subtitle: Text('Current: ${themeProvider.themeMode.name.toUpperCase()}'),
                leading: const Icon(Icons.palette),
                trailing: DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      themeProvider.setThemeMode(newValue);
                    }
                  },
                  items: ThemeMode.values.map((ThemeMode mode) {
                    return DropdownMenuItem<ThemeMode>(
                      value: mode,
                      child: Text(mode.name.toUpperCase()),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const Divider(),
          Consumer<CurrencyProvider>(
            builder: (context, currencyProvider, child) {
              return ListTile(
                title: const Text('Currency'),
                subtitle: Text(
                    'Current: ${currencyProvider.selectedCurrency.name} (${currencyProvider.code} ${currencyProvider.symbol})'),
                leading: const Icon(Icons.monetization_on_outlined),
                trailing: DropdownButton<String>(
                  value: currencyProvider.code,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      currencyProvider.setCurrency(newValue);
                    }
                  },
                  items: currencyProvider.availableCurrencies.map((CurrencyInfo info) {
                    return DropdownMenuItem<String>(
                      value: info.code,
                      child: Text('${info.code} (${info.symbol})'),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Restart Guided Tour'),
            subtitle: const Text('Replay the step-by-step feature tour'),
            leading: const Icon(Icons.play_circle_outline),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final tourProvider = context.read<TourProvider>();
              tourProvider.resetTourFlag();
              Navigator.pop(context); // Pop Settings screen to return to home first!
              
              // Wait for pop transition to finish so widget coordinates settle perfectly
              Future.delayed(const Duration(milliseconds: 600), () {
                tourProvider.startTour();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Guided tour started!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Share Feedback & Suggestions'),
            subtitle: const Text('Rate your experience and vote on features'),
            leading: const Icon(Icons.feedback_outlined),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final Uri url = Uri.parse(AppConstants.feedbackFormUrl);
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open feedback form')),
                  );
                }
              }
            },
          ),

          const Divider(),
          ListTile(
            title: const Text('Backup Data'),
            subtitle: const Text('Save all your data to a file you can keep safe'),
            leading: const Icon(Icons.backup_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleBackup,
          ),
          const Divider(),
          ListTile(
            title: const Text('Restore Data'),
            subtitle: const Text('Replace current data with a backup file'),
            leading: const Icon(Icons.settings_backup_restore),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleRestore,
          ),
          const Divider(),
          ListTile(
            title: const Text('Manage Wallets'),
            subtitle: const Text('Configure accounts and starting balances'),
            leading: const Icon(Icons.account_balance_wallet),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageWalletsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Manage Budgets'),
            subtitle: const Text('Set custom monthly limits for categories'),
            leading: const Icon(Icons.tune),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageBudgetsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Manage Categories'),
            subtitle: const Text('Add or remove custom categories'),
            leading: const Icon(Icons.category),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageCategoriesScreen()),
              );
            },
          )
        ],
      ),
    );
  }
}
