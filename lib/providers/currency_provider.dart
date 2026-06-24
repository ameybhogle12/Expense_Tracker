import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String locale;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.locale,
    required this.name,
  });
}

class CurrencyProvider with ChangeNotifier {
  static const String settingsBoxName = 'settings_v1';
  static const String currencyKey = 'selected_currency_code';

  final List<CurrencyInfo> availableCurrencies = const [
    CurrencyInfo(code: 'INR', symbol: '₹', locale: 'en_IN', name: 'Indian Rupee'),
    CurrencyInfo(code: 'USD', symbol: '\$', locale: 'en_US', name: 'US Dollar'),
    CurrencyInfo(code: 'EUR', symbol: '€', locale: 'de_DE', name: 'Euro'),
    CurrencyInfo(code: 'GBP', symbol: '£', locale: 'en_GB', name: 'British Pound'),
    CurrencyInfo(code: 'JPY', symbol: '¥', locale: 'ja_JP', name: 'Japanese Yen'),
    CurrencyInfo(code: 'AUD', symbol: '\$', locale: 'en_AU', name: 'Australian Dollar'),
    CurrencyInfo(code: 'CAD', symbol: '\$', locale: 'en_CA', name: 'Canadian Dollar'),
  ];

  late CurrencyInfo _selectedCurrency;

  CurrencyProvider() {
    _loadCurrency();
  }

  CurrencyInfo get selectedCurrency => _selectedCurrency;

  void _loadCurrency() {
    final box = Hive.box(settingsBoxName);
    final savedCode = box.get(currencyKey, defaultValue: 'INR') as String;
    
    _selectedCurrency = availableCurrencies.firstWhere(
      (c) => c.code == savedCode,
      orElse: () => availableCurrencies.first,
    );
  }

  Future<void> setCurrency(String code) async {
    final currency = availableCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => availableCurrencies.first,
    );

    _selectedCurrency = currency;
    final box = Hive.box(settingsBoxName);
    await box.put(currencyKey, code);
    notifyListeners();
  }

  /// Formats the amount with currency code and symbol, e.g. "USD $500" or "INR ₹15,000"
  String format(double amount, {int decimalDigits = 0}) {
    final formatter = NumberFormat.currency(
      name: '', // We prefix code manually to ensure exact spacing and order
      locale: _selectedCurrency.locale,
      symbol: _selectedCurrency.symbol,
      decimalDigits: decimalDigits,
    );
    return '${_selectedCurrency.code} ${formatter.format(amount).trim()}';
  }

  /// Compact formatting, e.g. "USD $1.5M" or "INR ₹1.5L"
  String formatCompact(double amount) {
    final formatter = NumberFormat.compact(locale: _selectedCurrency.locale);
    final compactStr = formatter.format(amount);
    return '${_selectedCurrency.code} ${_selectedCurrency.symbol}$compactStr';
  }

  /// Simple getter for the currency symbol (e.g. "$", "₹")
  String get symbol => _selectedCurrency.symbol;

  /// Simple getter for the currency code (e.g. "USD", "INR")
  String get code => _selectedCurrency.code;
}
