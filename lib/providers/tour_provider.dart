import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class TourStep {
  final String keyId;
  final String title;
  final String description;
  final String spotlightLabel;

  TourStep({
    required this.keyId,
    required this.title,
    required this.description,
    required this.spotlightLabel,
  });
}

class TourProvider with ChangeNotifier {
  final _settingsBox = Hive.box('settings_v1');
  static const String _tourCompleteKey = 'tourCompleted';

  bool _isTourActive = false;
  int _currentStep = 0;
  final Map<String, GlobalKey> _registeredKeys = {};

  bool get isTourActive => _isTourActive;
  int get currentStep => _currentStep;
  
  final List<TourStep> steps = [
    TourStep(
      keyId: 'wallets',
      title: 'Dynamic Wallets',
      description: 'See live balances across all your customized wallets. Swipe to view, or click the edit icon to add or rename accounts!',
      spotlightLabel: 'My Wallets',
    ),
    TourStep(
      keyId: 'add_btn',
      title: 'Log Transactions',
      description: 'Tap this button to record Expenses, Income, or swap/transfer funds from one wallet to another.',
      spotlightLabel: 'Quick Add',
    ),
    TourStep(
      keyId: 'nav_bar',
      title: 'Main Navigation',
      description: 'Switch instantly between Home, Charts, Subscriptions, EMIs/Goals, and Split settlement rooms.',
      spotlightLabel: 'Quick Tabs',
    ),
  ];

  bool get isTourCompleted => _settingsBox.get(_tourCompleteKey, defaultValue: false);

  void registerKey(String id, GlobalKey key) {
    _registeredKeys[id] = key;
  }

  GlobalKey? getKeyForStep(int index) {
    if (index >= 0 && index < steps.length) {
      return _registeredKeys[steps[index].keyId];
    }
    return null;
  }

  void startTour() {
    _isTourActive = true;
    _currentStep = 0;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < steps.length - 1) {
      _currentStep++;
      notifyListeners();
    } else {
      endTour();
    }
  }

  void skipTour() {
    endTour();
  }

  void endTour() {
    _isTourActive = false;
    _settingsBox.put(_tourCompleteKey, true);
    notifyListeners();
  }

  void resetTourFlag() {
    _settingsBox.put(_tourCompleteKey, false);
    notifyListeners();
  }
}
