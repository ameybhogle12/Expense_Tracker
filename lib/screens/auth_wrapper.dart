import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _useBiometrics = false;
  bool _isSettingsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = Hive.box('settings_v1');
    _useBiometrics = box.get('useBiometrics', defaultValue: false);
    setState(() {
      _isSettingsLoaded = true;
    });
    
    if (_useBiometrics) {
      _authenticate();
    } else {
      setState(() {
        _isAuthenticated = true; 
      });
    }
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      
      if (!canAuthenticate) {
        setState(() => _isAuthenticated = true);
        return;
      }
      
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access your financial data',
      );
      
      if (didAuthenticate) {
        setState(() => _isAuthenticated = true);
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth Error: $e')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_useBiometrics) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_useBiometrics && !_isAuthenticated) {
        _authenticate();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSettingsLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_isAuthenticated) {
      return const MainScreen();
    }
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text('App Locked', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please authenticate to continue'),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            )
          ],
        ),
      ),
    );
  }
}
