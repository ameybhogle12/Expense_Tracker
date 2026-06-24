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
import '../providers/locale_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';


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
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await BackupService.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path != null
              ? l10n.backupSuccess
              : l10n.backupCancelled),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupFailed(e.toString())), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleRestore() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreDialogTitle),
        content: Text(l10n.restoreDialogContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.restore),
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
        SnackBar(
          content: Text(l10n.restoreSuccess),
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
        SnackBar(content: Text(l10n.restoreFailed(e.toString())), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          if (!kIsWeb) ...[
            SwitchListTile(
              title: Text(l10n.requireAuth),
              subtitle: Text(l10n.requireAuthDesc),
              value: _useBiometrics,
              onChanged: _toggleBiometrics,
              secondary: const Icon(Icons.security),
            ),
            const Divider(),
          ],
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                title: Text(l10n.themeMode),
                subtitle: Text(l10n.currentTheme(themeProvider.themeMode.name.toUpperCase())),
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
                title: Text(l10n.currency),
                subtitle: Text(l10n.currentCurrency(currencyProvider.selectedCurrency.name, currencyProvider.code, currencyProvider.symbol)),
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
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return ListTile(
                title: Text(l10n.language),
                subtitle: Text(localeProvider.locale?.languageCode == 'ja' ? '日本語' : 'English (System Default)'),
                leading: const Icon(Icons.language),
                trailing: DropdownButton<String>(
                  value: localeProvider.locale?.languageCode ?? 'en',
                  onChanged: (String? newValue) {
                    if (newValue == 'ja') {
                      localeProvider.setLocale(const Locale('ja'));
                    } else {
                      localeProvider.setLocale(null); // English / System default
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ja', child: Text('日本語')),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.restartTour),
            subtitle: Text(l10n.restartTourDesc),
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
                SnackBar(
                  content: Text(l10n.tourStarted),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.shareFeedback),
            subtitle: Text(l10n.shareFeedbackDesc),
            leading: const Icon(Icons.feedback_outlined),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final Uri url = Uri.parse(AppConstants.feedbackFormUrl);
              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.feedbackError)),
                  );
                }
              }
            },
          ),

          const Divider(),
          ListTile(
            title: Text(l10n.backupData),
            subtitle: Text(l10n.backupDataDesc),
            leading: const Icon(Icons.backup_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleBackup,
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.restoreData),
            subtitle: Text(l10n.restoreDataDesc),
            leading: const Icon(Icons.settings_backup_restore),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleRestore,
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.manageWallets),
            subtitle: Text(l10n.manageWalletsDesc),
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
            title: Text(l10n.manageBudgets),
            subtitle: Text(l10n.manageBudgetsDesc),
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
            title: Text(l10n.manageCategories),
            subtitle: Text(l10n.manageCategoriesDesc),
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
