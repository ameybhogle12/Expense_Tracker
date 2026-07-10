# Trip & Track: App Progress & Developer Log

## 📱 Current Features (v1.0.3 - Free for all users)
*   **Wallets:** Unlimited Wallets.
*   **Categories:** Unlimited Categories.
*   **Subscriptions:** Unlimited Subscription tracking with automatic background logging.
*   **Trips (Splits):** Split expenses with friends for trips.
*   **Goals & EMIs:** Track saving goals and upcoming EMI payments.
*   **Security:** Screenshot App Lock.
*   **Dashboard:** Advanced interactive Donut Charts and Line Charts for tracking expenses.

## 🚀 PlayStore Strategy
*   **Version 1 (Initial Release):** 100% Free for all users to build a strong user base and ensure high retention.
*   **Version 2 (Monetization):** Introduction of the **Premium / Pro Tier**. Core features (wallets, categories, subscriptions) remain free. Advanced "power-user" features will be gated behind the paywall using RevenueCat.

## 💎 Premium Features Pipeline (v2.0+)
### 1. Auto-Magic Logger (Notification Tracking) - [IMPLEMENTED]
*   **Description:** Intercepts push notifications from banking/UPI apps (GPay, PhonePe, Paytm), parses the Amount and Merchant using Regex, and automatically logs the expense into Hive in the background.
*   **AI Categorization (Gemini):** Integrated Google Gemini API to automatically categorize the merchant (e.g., "Starbucks" -> "Food").
*   **Problem Faced (API Rate Limiting):** Gemini's Free Tier limits (15 RPM / 1,500 RPD) would break if scaled to 1,000+ users.
*   **Solution implemented (Hybrid Smart Cache):** Instead of calling the API for every transaction, the app maintains a local Hive cache `merchant_category_cache_v1`. When a user visits a merchant for the first time, an API call is made, and the result `{"Starbucks": "Food"}` is cached locally. Future transactions at the same merchant use the local cache (0 API calls). If the API rate limits out, the app falls back to categorizing as "Other" and pings the user.

## 🐛 Major Problems & Solutions Log
### 1. Gemini API Rate Limiting on Free Tier
*   **Problem:** UPI auto-logging makes frequent API calls. Free tier limitations would quickly block users.
*   **Root Cause:** Multi-user scaling on single free API key is unsustainable.
*   **Solution:** Built a local cache box (`merchant_category_cache_v1`) to store merchant -> category mappings. We only query the Gemini API for unique, uncached merchants, saving up to 90% of API quota. Added a graceful offline/error fallback to "Other" if the API rate limits out or fails.

### 2. API Key Security & Best Practices
*   **Problem:** The Gemini API key was initially hardcoded directly into the Dart source file (`AICategoryService.dart`).
*   **Root Cause:** Rapid prototyping without a secure environment configuration.
*   **Solution:** Integrated `flutter_dotenv`. Created a root `.env` file to store the `GEMINI_API_KEY`. Added `.env` to `.gitignore` to prevent it from being committed to version control, and updated `AICategoryService` to fetch the key securely via `dotenv.env['GEMINI_API_KEY']`.
