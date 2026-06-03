import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/tour_provider.dart';
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
