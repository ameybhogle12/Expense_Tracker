import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AICategoryService {
  static const String cacheBoxName = 'merchant_category_cache_v1';

  static final AICategoryService _instance = AICategoryService._internal();
  factory AICategoryService() => _instance;
  AICategoryService._internal();

  GenerativeModel? _model;
  late Box<String> _cacheBox;

  Future<void> init() async {
    _cacheBox = await Hive.openBox<String>(cacheBoxName);
    
    // Load API Key from Settings, falling back to .env if not set
    final settingsBox = await Hive.openBox('settings_v1');
    final String envApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final apiKey = settingsBox.get('gemini_api_key', defaultValue: envApiKey) as String;

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  /// Categorizes a merchant using a local cache first, falling back to Gemini AI.
  Future<String> categorizeMerchant(String merchantName, List<String> availableCategories) async {
    if (merchantName.trim().isEmpty) {
      return 'Other';
    }

    final normalizedMerchant = merchantName.trim().toLowerCase();

    // 1. Check local Hive Cache
    if (_cacheBox.containsKey(normalizedMerchant)) {
      final cachedCategory = _cacheBox.get(normalizedMerchant);
      if (cachedCategory != null && availableCategories.contains(cachedCategory)) {
        return cachedCategory;
      }
    }

    // 2. Call Gemini API
    if (_model == null) {
      await init();
    }

    try {
      final prompt = '''
You are a smart expense categorizer. 
Categorize the merchant: "$merchantName". 
Here are the available categories: ${availableCategories.join(', ')}. 
Respond with ONLY the exact name of the best matching category from this list, nothing else. 
If none of them match, respond with "Other".
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      final resultCategory = response.text?.trim() ?? 'Other';

      // Validate that Gemini returned a category in our list
      if (availableCategories.contains(resultCategory)) {
        // Cache the result
        await _cacheBox.put(normalizedMerchant, resultCategory);
        return resultCategory;
      } else {
        // Fallback check: Case insensitive match
        for (var cat in availableCategories) {
          if (cat.toLowerCase() == resultCategory.toLowerCase()) {
            await _cacheBox.put(normalizedMerchant, cat);
            return cat;
          }
        }
      }
    } catch (e) {
      // In case of rate limits (429) or offline, fail gracefully to "Other"
      print('AICategoryService Error: $e');
    }

    return 'Other';
  }
}
