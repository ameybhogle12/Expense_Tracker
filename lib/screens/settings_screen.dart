import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'contact_developer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../providers/locale_provider.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import '../services/notification_tracker.dart';
import 'package:notification_listener_service/notification_listener_service.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _useBiometrics;
  late bool _autoLoggingEnabled;
  bool _isBatteryOptimized = true; // Assume optimized (bad) until checked

  static const _channel = MethodChannel('com.ameybhogle.expensetracker/payment_detection');

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings_v1');
    _useBiometrics = box.get('useBiometrics', defaultValue: false);
    _autoLoggingEnabled = box.get('auto_logging_enabled', defaultValue: false);
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final bool isOptimized = await _channel.invokeMethod('isBatteryOptimized');
      if (mounted) {
        setState(() {
          _isBatteryOptimized = isOptimized;
        });
      }
    } catch (_) {
      // Silently handle — MethodChannel may not be available
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
      // Re-check after the user returns from the system settings
      await Future.delayed(const Duration(seconds: 2));
      await _checkBatteryOptimization();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open battery settings. Please disable battery optimization manually in system settings.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleBiometrics(bool value) async {
    final box = Hive.box('settings_v1');
    await box.put('useBiometrics', value);
    setState(() {
      _useBiometrics = value;
    });
  }

  void _toggleAutoLogging(bool value) async {
    final box = Hive.box('settings_v1');
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      final isGranted = await NotificationListenerService.isPermissionGranted();
      if (!isGranted) {
        final requestResult = await NotificationListenerService.requestPermission();
        if (!requestResult) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.autoLoggingNotificationAccess),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }
      await box.put('auto_logging_enabled', true);
      await NotificationTracker().startListening();
      setState(() {
        _autoLoggingEnabled = true;
      });
    } else {
      await box.put('auto_logging_enabled', false);
      NotificationTracker().stopListening();
      setState(() {
        _autoLoggingEnabled = false;
      });
    }
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

  Widget _buildIconContainer(IconData icon, Color backgroundColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? backgroundColor.withOpacity(0.15) : backgroundColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: backgroundColor,
        size: 20,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildAppHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Image.asset(
            'assets/icon/icon.png',
            height: 72,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          const Text(
            'Trip & Track',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.6 (Free Release)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDeveloperCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.deepPurpleAccent.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      color: isDark ? Colors.deepPurple.withOpacity(0.06) : Colors.deepPurple.withOpacity(0.02),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: const Text(
          'Contact Developer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: const Text('Share feedback, suggestions, or report bugs directly to Amey.'),
        leading: _buildIconContainer(Icons.support_agent, Colors.deepPurpleAccent),
        trailing: const Icon(Icons.chevron_right, color: Colors.deepPurpleAccent),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactDeveloperScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildAppHeader(),
          
          // Standalone Highlighted Card
          _buildContactDeveloperCard(),

          _buildSectionHeader('Preferences'),
          _buildGroupCard([
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListTile(
                  title: Text(l10n.themeMode),
                  subtitle: Text(l10n.currentTheme(themeProvider.themeMode.name.toUpperCase())),
                  leading: _buildIconContainer(Icons.palette, Colors.purple),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    underline: const SizedBox(),
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
            const Divider(height: 1, indent: 64),
            Consumer<CurrencyProvider>(
              builder: (context, currencyProvider, child) {
                return ListTile(
                  title: Text(l10n.currency),
                  subtitle: Text(currencyProvider.selectedCurrency.name),
                  leading: _buildIconContainer(Icons.monetization_on_outlined, Colors.green),
                  trailing: DropdownButton<String>(
                    value: currencyProvider.code,
                    underline: const SizedBox(),
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
            const Divider(height: 1, indent: 64),
            Consumer<LocaleProvider>(
              builder: (context, localeProvider, child) {
                return ListTile(
                  title: Text(l10n.language),
                  subtitle: Text(localeProvider.locale?.languageCode == 'ja' ? '日本語' : 'English (System Default)'),
                  leading: _buildIconContainer(Icons.language, Colors.blue),
                  trailing: DropdownButton<String>(
                    value: localeProvider.locale?.languageCode ?? 'en',
                    underline: const SizedBox(),
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
          ]),

          _buildSectionHeader('Data Management'),
          _buildGroupCard([
            ListTile(
              title: Text(l10n.manageWallets),
              subtitle: Text(l10n.manageWalletsDesc),
              leading: _buildIconContainer(Icons.account_balance_wallet, Colors.cyan),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageWalletsScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 64),
            ListTile(
              title: Text(l10n.manageBudgets),
              subtitle: Text(l10n.manageBudgetsDesc),
              leading: _buildIconContainer(Icons.tune, Colors.amber),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageBudgetsScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 64),
            ListTile(
              title: Text(l10n.manageCategories),
              subtitle: Text(l10n.manageCategoriesDesc),
              leading: _buildIconContainer(Icons.category, Colors.deepOrange),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageCategoriesScreen()),
                );
              },
            ),
          ]),

          _buildSectionHeader('Data & Security'),
          _buildGroupCard([
            if (!kIsWeb) ...[
              SwitchListTile(
                title: Text(l10n.requireAuth),
                subtitle: Text(l10n.requireAuthDesc),
                value: _useBiometrics,
                onChanged: _toggleBiometrics,
                secondary: _buildIconContainer(Icons.security, Colors.teal),
              ),
              const Divider(height: 1, indent: 64),
              SwitchListTile(
                title: Text(l10n.autoLogging),
                subtitle: Text(l10n.autoLoggingDesc),
                value: _autoLoggingEnabled,
                onChanged: _toggleAutoLogging,
                secondary: _buildIconContainer(Icons.notification_important_outlined, Colors.deepOrange),
              ),
              const Divider(height: 1, indent: 64),
              ListTile(
                title: const Text('Battery Optimization'),
                subtitle: Text(
                  _isBatteryOptimized
                      ? 'Restricted — notifications may not work in background'
                      : 'Unrestricted — background notifications enabled ✓',
                ),
                leading: _buildIconContainer(
                  _isBatteryOptimized ? Icons.battery_alert : Icons.battery_full,
                  _isBatteryOptimized ? Colors.red : Colors.green,
                ),
                trailing: _isBatteryOptimized
                    ? FilledButton.tonal(
                        onPressed: _requestBatteryOptimization,
                        child: const Text('Fix'),
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
                onTap: _isBatteryOptimized ? _requestBatteryOptimization : null,
              ),
              const Divider(height: 1, indent: 64),
            ],
            ListTile(
              title: Text(l10n.backupData),
              subtitle: Text(l10n.backupDataDesc),
              leading: _buildIconContainer(Icons.backup_outlined, Colors.indigo),
              trailing: const Icon(Icons.chevron_right),
              onTap: _handleBackup,
            ),
            const Divider(height: 1, indent: 64),
            ListTile(
              title: Text(l10n.restoreData),
              subtitle: Text(l10n.restoreDataDesc),
              leading: _buildIconContainer(Icons.settings_backup_restore, Colors.blueGrey),
              trailing: const Icon(Icons.chevron_right),
              onTap: _handleRestore,
            ),
          ]),

          _buildSectionHeader('About & Support'),
          _buildGroupCard([
            ListTile(
              title: Text(l10n.restartTour),
              subtitle: Text(l10n.restartTourDesc),
              leading: _buildIconContainer(Icons.play_circle_outline, Colors.orange),
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
            const Divider(height: 1, indent: 64),
            ListTile(
              title: Text(l10n.shareFeedback),
              subtitle: Text(l10n.shareFeedbackDesc),
              leading: _buildIconContainer(Icons.feedback_outlined, Colors.lightGreen),
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
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
