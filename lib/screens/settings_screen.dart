import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'manage_categories_screen.dart';

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
          SwitchListTile(
            title: const Text('Require Authentication'),
            subtitle: const Text('Lock app with Fingerprint or PIN'),
            value: _useBiometrics,
            onChanged: _toggleBiometrics,
            secondary: const Icon(Icons.security),
          ),
          const Divider(),
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
